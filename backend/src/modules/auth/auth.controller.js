const service = require('./auth.service');
const { saveAsWebp } = require('./avatar.upload');
const fs = require('fs/promises');
const path = require('path');
const { asyncHandler } = require('../../utils/httpError');

exports.register = asyncHandler(async (req, res) => {
  const { username, password, displayName } = req.body;
  res.status(201).json(await service.register(username, password, displayName || username));
});

exports.updateDisplayName = asyncHandler(async (req, res) => {
  const user = await service.updateDisplayName(req.user.id, req.body.displayName);
  res.json({ user, token: service.signToken(user) });
});

exports.updateBio = asyncHandler(async (req, res) => {
  const user = await service.updateBio(req.user.id, req.body.bio);
  res.json({ user, token: service.signToken(user) });
});

exports.updateAvatar = asyncHandler(async (req, res) => {
  if (!req.file) {
    res.status(400).json({ error: 'Profile picture is required' });
    return;
  }
  const filename = await saveAsWebp(req.file);
  const { user, oldAvatarUrl } = await service.updateAvatar(req.user.id, filename);
  if (oldAvatarUrl) {
    await fs.rm(
      path.join(__dirname, '../../../', oldAvatarUrl.replace(/^\/+/, '')),
      { force: true }
    );
  }
  res.json({ user, token: service.signToken(user) });
});

exports.login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  res.json(await service.login(username, password));
});
