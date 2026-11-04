const router = require('express').Router();
const requireAuth = require('../auth/auth.middleware');
const controller = require('./notifications.controller');

router.use(requireAuth);
router.get('/', controller.list);
router.patch('/:notificationId/read', controller.markRead);

module.exports = router;
