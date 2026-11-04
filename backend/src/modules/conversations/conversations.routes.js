const router = require('express').Router();
const requireAuth = require('../auth/auth.middleware');
const controller = require('./conversations.controller');
const messagesController = require('../messages/messages.controller');

router.use(requireAuth);
router.get('/', controller.list);
router.get('/users', controller.listUsers);
router.get('/users/:userId', controller.profile);
router.post('/friends/requests', controller.requestFriend);
router.patch('/friends/requests/:userId', controller.respondFriend);
router.patch('/friends/:userId/mute', controller.mute);
router.patch('/friends/:userId/block', controller.block);
router.post('/', controller.create);
router.get('/:conversationId/messages', messagesController.listByConversation);

module.exports = router;
