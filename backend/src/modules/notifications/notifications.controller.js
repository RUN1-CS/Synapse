const service = require('./notifications.service');
const { asyncHandler } = require('../../utils/httpError');

exports.list = asyncHandler(async (req, res) => {
  res.json(await service.list(req.user.id));
});

exports.markRead = asyncHandler(async (req, res) => {
  await service.markRead(req.user.id, req.params.notificationId);
  res.json({ ok: true });
});

exports.markConversationRead = asyncHandler(async (req, res) => {
  await service.markConversationRead(
    req.user.id,
    Number(req.params.conversationId)
  );
  res.json({ ok: true });
});

exports.markAllRead = asyncHandler(async (req, res) => {
  await service.markAllRead(req.user.id);
  res.json({ ok: true });
});
