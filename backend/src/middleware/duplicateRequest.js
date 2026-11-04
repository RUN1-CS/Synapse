const crypto = require('crypto');
const { HttpError } = require('../utils/httpError');

function duplicateRequest(windowMs) {
  const recent = new Map();
  return (req, _res, next) => {
    if (!['POST', 'PATCH', 'DELETE'].includes(req.method)) {
      next();
      return;
    }
    const body = JSON.stringify(req.body || {});
    const fingerprint = crypto.createHash('sha256')
      .update(`${req.ip}|${req.method}|${req.originalUrl}|${body}`)
      .digest('hex');
    const now = Date.now();
    const previous = recent.get(fingerprint);
    if (previous && now - previous < windowMs) {
      throw new HttpError(409, 'Duplicate request');
    }
    recent.set(fingerprint, now);
    next();
  };
}

module.exports = duplicateRequest;
