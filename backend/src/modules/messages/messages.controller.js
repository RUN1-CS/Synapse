const service = require('./messages.service');
const { asyncHandler } = require('../../utils/httpError');

exports.listByConversation = asyncHandler(async (req, res) => {
  res.json(await service.listByConversation(
    Number(req.params.conversationId),
    req.user.id,
    {
      limit: req.query.limit,
      before: req.query.before,
      after: req.query.after,
    }
  ));
});
