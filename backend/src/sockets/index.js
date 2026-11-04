const { Server } = require('socket.io');
const { verifyToken } = require('../modules/auth/auth.service');
const messages = require('../modules/messages/messages.service');
const conversations = require('../modules/conversations/conversations.service');

const conversationKey = (id) => `conversation:${id}`;

module.exports = function initSockets(httpServer) {
  const io = new Server(httpServer, { cors: { origin: '*' } });

  // Authenticate every connection with the JWT sent in the handshake.
  io.use((socket, next) => {
    try {
      socket.user = verifyToken(socket.handshake.auth.token);
      next();
    } catch {
      next(new Error('unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('join_conversation', async (conversationId, ack) => {
      try {
        await conversations.assertMember(Number(conversationId), socket.user.id);
        socket.join(conversationKey(conversationId));
        if (typeof ack === 'function') ack({ ok: true });
      } catch (e) {
        if (typeof ack === 'function') ack({ ok: false, error: e.message });
      }
    });
    socket.on('leave_conversation', (conversationId) => socket.leave(conversationKey(conversationId)));

    socket.on('send_message', async ({ conversationId, content }, ack) => {
      try {
        const msg = await messages.create({ conversationId, userId: socket.user.id, content });
        io.to(conversationKey(conversationId)).emit('new_message', msg);
        if (typeof ack === 'function') ack({ ok: true });
      } catch (e) {
        if (typeof ack === 'function') ack({ ok: false, error: e.message });
      }
    });
  });

  return io;
};
