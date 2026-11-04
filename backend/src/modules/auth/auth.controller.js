const service = require('./auth.service');
const { saveAsWebp } = require('./avatar.upload');
const fs = require('fs/promises');
const path = require('path');
const { asyncHandler } = require('../../utils/httpError');

exports.register = asyncHandler(async (req, res) => {
  const { username, password, displayName } = req.body;
  res.status(201).json(await service.register(
    username, password, displayName || username, req.get('user-agent')
  ));
});

exports.updateDisplayName = asyncHandler(async (req, res) => {
  const user = await service.updateDisplayName(req.user.id, req.body.displayName);
  res.json({ user });
});

exports.updateBio = asyncHandler(async (req, res) => {
  const user = await service.updateBio(req.user.id, req.body.bio);
  res.json({ user });
});

exports.changePassword = asyncHandler(async (req, res) => {
  const user = await service.changePassword(
    req.user.id,
    req.body.currentPassword,
    req.body.newPassword,
    req.get('user-agent')
  );
  res.json(user);
});

exports.logout = asyncHandler(async (req, res) => {
  await service.revokeSession(req.user.id, req.user.sid);
  res.status(204).end();
});

exports.logoutAll = asyncHandler(async (req, res) => {
  await service.revokeAllSessions(req.user.id);
  res.status(204).end();
});

exports.deleteAccount = asyncHandler(async (req, res) => {
  const { oldAvatarUrl } = await service.deleteAccount(
    req.user.id,
    req.body.password
  );
  if (oldAvatarUrl) {
    await fs.rm(
      path.join(__dirname, '../../../', oldAvatarUrl.replace(/^\/+/, '')),
      { force: true }
    );
  }
  res.status(204).end();
});

exports.refresh = asyncHandler(async (req, res) => {
  res.json(await service.refresh(req.body.refreshToken, req.get('user-agent')));
});

exports.sessions = asyncHandler(async (req, res) => {
  res.json(await service.listSessions(req.user.id, req.user.sid));
});

exports.revokeSession = asyncHandler(async (req, res) => {
  await service.revokeSession(req.user.id, req.params.sessionId);
  res.status(204).end();
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
  res.json({ user });
});

exports.login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  res.json(await service.login(username, password, req.get('user-agent')));
});
