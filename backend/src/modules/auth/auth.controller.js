const service = require('./auth.service');
const { asyncHandler } = require('../../utils/httpError');

exports.register = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  res.status(201).json(await service.register(username, password));
});

exports.login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  res.json(await service.login(username, password));
});
