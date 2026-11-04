const service = require('./rooms.service');
const { asyncHandler } = require('../../utils/httpError');

exports.list = asyncHandler(async (_req, res) => res.json(await service.list()));
exports.create = asyncHandler(async (req, res) => res.status(201).json(await service.create(req.body.name)));
