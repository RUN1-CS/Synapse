const { Server } = require("socket.io");
const db = require("../config/db");
const { verifyToken } = require("../modules/auth/auth.service");
const messages = require("../modules/messages/messages.service");
const conversations = require("../modules/conversations/conversations.service");

const conversationKey = (id) => `conversation:${id}`;
const userKey = (id) => `user:${id}`;

module.exports = function initSockets(httpServer) {
  const io = new Server(httpServer, { cors: { origin: "*" } });

  // Authenticate every connection with the JWT sent in the handshake.
  io.use((socket, next) => {
    try {
      socket.user = verifyToken(socket.handshake.auth.token);
      next();
    } catch {
      next(new Error("unauthorized"));
    }
  });

  io.on("connection", (socket) => {
    socket.join(userKey(socket.user.id));
    socket.on("join_conversation", async (conversationId, ack) => {
      try {
        await conversations.assertMember(
          Number(conversationId),
          socket.user.id,
        );
        socket.join(conversationKey(conversationId));
        if (typeof ack === "function") ack({ ok: true });
      } catch (e) {
        if (typeof ack === "function") ack({ ok: false, error: e.message });
      }
    });
    socket.on("leave_conversation", (conversationId) =>
      socket.leave(conversationKey(conversationId)),
    );

    socket.on("send_message", async ({ conversationId, content }, ack) => {
      try {
        const msg = await messages.create({
          conversationId,
          userId: socket.user.id,
          content,
        });
        io.to(conversationKey(conversationId)).emit("new_message", msg);
        const { rows } = await db.query(
          `SELECT CASE WHEN user_one_id = $1 THEN user_two_id ELSE user_one_id END AS "recipientId"
           FROM conversations WHERE id = $2`,
          [socket.user.id, conversationId],
        );
        if (rows[0])
          io.to(userKey(rows[0].recipientId)).emit("message_notification", msg);
        if (typeof ack === "function") ack({ ok: true });
      } catch (e) {
        if (typeof ack === "function") ack({ ok: false, error: e.message });
      }
    });
  });

  return io;
};
