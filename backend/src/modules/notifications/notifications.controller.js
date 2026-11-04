const service = require('./notifications.service');
const { asyncHandler } = require('../../utils/httpError');

exports.list = asyncHandler(async (req, res) => {
  res.json(await service.list(req.user.id));
});

exports.markRead = asyncHandler(async (req, res) => {
  await service.markRead(req.user.id, req.params.notificationId);
  res.json({ ok: true });
});
