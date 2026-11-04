const service = require('./conversations.service');
const { asyncHandler } = require('../../utils/httpError');

exports.listUsers = asyncHandler(async (req, res) => {
  res.json(await service.listUsers(req.user.id));
});

exports.list = asyncHandler(async (req, res) => {
  res.json(await service.listForUser(req.user.id));
});

exports.create = asyncHandler(async (req, res) => {
  res.status(201).json(await service.getOrCreate(req.user.id, req.body.userId));
});
