const { Server } = require("socket.io");
const db = require("../config/db");
const { validateToken } = require("../modules/auth/auth.service");
const {
  websocketRateLimitWindowSeconds,
  websocketRateLimitMaxEvents,
  websocketConnectionWindowSeconds,
  websocketConnectionMaxAttempts,
} = require("../config/env");
const messages = require("../modules/messages/messages.service");
const conversations = require("../modules/conversations/conversations.service");

const conversationKey = (id) => `conversation:${id}`;
const userKey = (id) => `user:${id}`;

module.exports = function initSockets(httpServer) {
  const io = new Server(httpServer, { cors: { origin: "*" } });
  const connections = new Map();

  // Authenticate every connection with the JWT sent in the handshake.
  io.use(async (socket, next) => {
    try {
      const now = Date.now();
      const key = socket.handshake.address;
      const current = connections.get(key);
      if (connections.size > 10000) {
        for (const [address, entry] of connections) {
          if (now - entry.startedAt >= websocketConnectionWindowSeconds * 1000) {
            connections.delete(address);
          }
        }
      }
      if (!current || now - current.startedAt >= websocketConnectionWindowSeconds * 1000) {
        connections.set(key, { startedAt: now, count: 1 });
      } else {
        current.count += 1;
        if (current.count > websocketConnectionMaxAttempts) {
          next(new Error("too many connections"));
          return;
        }
      }
      socket.user = await validateToken(socket.handshake.auth.token);
      next();
    } catch {
      next(new Error("unauthorized"));
    }
  });

  io.on("connection", (socket) => {
    let eventWindowStarted = Date.now();
    let eventCount = 0;
    const allowEvent = () => {
      const now = Date.now();
      if (now - eventWindowStarted >= websocketRateLimitWindowSeconds * 1000) {
        eventWindowStarted = now;
        eventCount = 0;
      }
      eventCount += 1;
      return eventCount <= websocketRateLimitMaxEvents;
    };
    socket.join(userKey(socket.user.id));
    socket.on("join_conversation", async (conversationId, ack) => {
      if (!allowEvent()) {
        if (typeof ack === "function") ack({ ok: false, error: "Too many events" });
        return;
      }
      try {
        await conversations.assertMember(
          Number(conversationId),
          socket.user.id,
        );
        socket.join(conversationKey(conversationId));
        if (typeof ack === "function") ack({ ok: true, message: msg });
      } catch (e) {
        if (typeof ack === "function") ack({ ok: false, error: e.message });
      }
    });
    socket.on("leave_conversation", (conversationId) =>
      allowEvent() && socket.leave(conversationKey(conversationId)),
    );

    socket.on("send_message", async (payload, ack) => {
      if (!allowEvent()) {
        if (typeof ack === "function") ack({ ok: false, error: "Too many events" });
        return;
      }
      try {
        if (!payload || typeof payload !== "object") {
          throw new Error("Invalid message payload");
        }
        const { conversationId, content, clientMessageId } = payload;
        const msg = await messages.create({
          conversationId,
          userId: socket.user.id,
          content,
          clientMessageId,
        });
        io.to(conversationKey(conversationId)).emit("message:created", msg);
        io.to(conversationKey(conversationId)).emit("new_message", msg);
        const { rows } = await db.query(
          `SELECT CASE WHEN c.user_one_id = $1 THEN c.user_two_id ELSE c.user_one_id END AS "recipientId",
             EXISTS (SELECT 1 FROM muted_users m
               WHERE m.muter_id = CASE WHEN c.user_one_id = $1 THEN c.user_two_id ELSE c.user_one_id END
                 AND m.muted_id = $1) AS muted,
             EXISTS (SELECT 1 FROM blocked_users b
               WHERE (b.blocker_id = $1 AND b.blocked_id = CASE WHEN c.user_one_id = $1 THEN c.user_two_id ELSE c.user_one_id END)
                  OR (b.blocker_id = CASE WHEN c.user_one_id = $1 THEN c.user_two_id ELSE c.user_one_id END AND b.blocked_id = $1)) AS blocked
           FROM conversations c WHERE c.id = $2`,
          [socket.user.id, conversationId],
        );
        if (rows[0] && !rows[0].muted && !rows[0].blocked)
          io.to(userKey(rows[0].recipientId)).emit("message_notification", msg);
        if (typeof ack === "function") ack({ ok: true });
      } catch (e) {
        if (typeof ack === "function") ack({ ok: false, error: e.message });
      }
    });
    socket.on("message:delivered", async ({ messageId }, ack) => {
      if (!allowEvent()) {
        if (typeof ack === "function") ack({ ok: false, error: "Too many events" });
        return;
      }
      try {
        const status = await messages.markDelivered(Number(messageId), socket.user.id);
        if (status) {
          const { rows } = await db.query(
            'SELECT user_id AS "senderId", conversation_id AS "conversationId" FROM messages WHERE id = $1',
            [messageId]
          );
          if (rows[0]) {
            io.to(userKey(rows[0].senderId)).emit("message:delivered", {
              messageId: Number(messageId),
              conversationId: rows[0].conversationId,
              status: "delivered",
            });
          }
        }
        if (typeof ack === "function") ack({ ok: true });
      } catch (e) {
        if (typeof ack === "function") ack({ ok: false, error: e.message });
      }
    });
    socket.on("message:read", async ({ conversationId, messageId }, ack) => {
      if (!allowEvent()) {
        if (typeof ack === "function") ack({ ok: false, error: "Too many events" });
        return;
      }
      try {
        const status = await messages.markRead(
          Number(conversationId), socket.user.id, Number(messageId)
        );
        if (status) {
          const { rows } = await db.query(
            'SELECT user_one_id AS "userOneId", user_two_id AS "userTwoId" FROM conversations WHERE id = $1',
            [conversationId]
          );
          const other = rows[0]?.userOneId === socket.user.id
            ? rows[0]?.userTwoId : rows[0]?.userOneId;
          if (other) io.to(userKey(other)).emit("message:read", {
            conversationId: Number(conversationId),
            messageId: Number(messageId),
            status: "read",
          });
        }
        if (typeof ack === "function") ack({ ok: true });
      } catch (e) {
        if (typeof ack === "function") ack({ ok: false, error: e.message });
      }
    });
  });

  return io;
};
