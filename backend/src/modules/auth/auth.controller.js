const service = require('./auth.service');
const { asyncHandler } = require('../../utils/httpError');

exports.register = asyncHandler(async (req, res) => {
  const { username, password, displayName } = req.body;
  res.status(201).json(await service.register(username, password, displayName || username));
});

exports.updateDisplayName = asyncHandler(async (req, res) => {
  const user = await service.updateDisplayName(req.user.id, req.body.displayName);
  res.json({ user, token: service.signToken(user) });
});

exports.updateAvatar = asyncHandler(async (req, res) => {
  if (!req.file) {
    res.status(400).json({ error: 'Profile picture is required' });
    return;
  }
  const user = await service.updateAvatar(req.user.id, req.file.filename);
  res.json({ user, token: service.signToken(user) });
});

exports.login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  res.json(await service.login(username, password));
});
