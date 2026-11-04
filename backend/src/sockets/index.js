const { Server } = require('socket.io');
const { verifyToken } = require('../modules/auth/auth.service');
const messages = require('../modules/messages/messages.service');

const roomKey = (id) => `room:${id}`;

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
    socket.on('join_room', (roomId) => socket.join(roomKey(roomId)));
    socket.on('leave_room', (roomId) => socket.leave(roomKey(roomId)));

    socket.on('send_message', async ({ roomId, content }, ack) => {
      try {
        const msg = await messages.create({ roomId, userId: socket.user.id, content });
        io.to(roomKey(roomId)).emit('new_message', msg);
        if (typeof ack === 'function') ack({ ok: true });
      } catch (e) {
        if (typeof ack === 'function') ack({ ok: false, error: e.message });
      }
    });
  });

  return io;
};
