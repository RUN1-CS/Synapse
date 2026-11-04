const router = require('express').Router();
const controller = require('./auth.controller');
const requireAuth = require('./auth.middleware');
const upload = require('./avatar.upload');

router.post('/register', controller.register);
router.post('/login', controller.login);
router.patch('/me', requireAuth, controller.updateDisplayName);
router.patch('/me/avatar', requireAuth, upload.single('avatar'), controller.updateAvatar);

module.exports = router;
