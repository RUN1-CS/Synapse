const service = require('./conversations.service');
const { asyncHandler } = require('../../utils/httpError');

exports.listUsers = asyncHandler(async (req, res) => {
  const search = String(req.query.search || '').slice(0, 64);
  res.json(await service.listUsers(req.user.id, search));
});

exports.profile = asyncHandler(async (req, res) => {
  res.json(await service.profile(req.user.id, req.params.userId));
});

exports.list = asyncHandler(async (req, res) => {
  res.json(await service.listForUser(req.user.id));
});

exports.create = asyncHandler(async (req, res) => {
  res.status(201).json(await service.getOrCreate(req.user.id, req.body.userId));
});

exports.requestFriend = asyncHandler(async (req, res) => {
  res.status(201).json(await service.requestFriend(req.user.id, req.body.userId));
});

exports.respondFriend = asyncHandler(async (req, res) => {
  res.json(await service.respondFriend(
    req.user.id, req.params.userId, req.body.accept === true
  ));
});

exports.mute = asyncHandler(async (req, res) => {
  await service.setMuted(req.user.id, req.params.userId, req.body.muted === true);
  res.json({ ok: true });
});

exports.block = asyncHandler(async (req, res) => {
  await service.setBlocked(req.user.id, req.params.userId, req.body.blocked === true);
  res.json({ ok: true });
});
