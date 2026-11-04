const router = require('express').Router();
const requireAuth = require('../auth/auth.middleware');
const controller = require('./conversations.controller');
const messagesController = require('../messages/messages.controller');

router.use(requireAuth);
router.get('/users', controller.listUsers);
router.post('/', controller.create);
router.get('/:conversationId/messages', messagesController.listByConversation);

module.exports = router;
