const service = require('./messages.service');
const { asyncHandler } = require('../../utils/httpError');

exports.listByRoom = asyncHandler(async (req, res) => {
  res.json(await service.listByRoom(Number(req.params.roomId)));
});
