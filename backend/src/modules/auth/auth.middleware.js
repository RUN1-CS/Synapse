const { validateToken } = require('./auth.service');
const { HttpError } = require('../../utils/httpError');

module.exports = async function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  try {
    req.user = await validateToken(token);
    next();
  } catch {
    next(new HttpError(401, 'Unauthorized'));
  }
};
