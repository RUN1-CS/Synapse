const router = require('express').Router();
const requireAuth = require('../auth/auth.middleware');
const controller = require('./rooms.controller');
const messagesController = require('../messages/messages.controller');

router.use(requireAuth);
router.get('/', controller.list);
router.post('/', controller.create);
router.get('/:roomId/messages', messagesController.listByRoom);

module.exports = router;
