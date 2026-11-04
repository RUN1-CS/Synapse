const router = require('express').Router();
const controller = require('./auth.controller');
const requireAuth = require('./auth.middleware');
const upload = require('./avatar.upload');

router.post('/register', controller.register);
router.post('/login', controller.login);
router.post('/refresh', controller.refresh);
router.post('/logout', requireAuth, controller.logout);
router.post('/logout-all', requireAuth, controller.logoutAll);
router.get('/sessions', requireAuth, controller.sessions);
router.delete('/sessions/:sessionId', requireAuth, controller.revokeSession);
router.patch('/me', requireAuth, controller.updateDisplayName);
router.patch('/me/bio', requireAuth, controller.updateBio);
router.patch('/me/password', requireAuth, controller.changePassword);
router.patch('/me/avatar', requireAuth, upload.single('avatar'), controller.updateAvatar);

module.exports = router;
