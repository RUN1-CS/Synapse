const { HttpError } = require('../utils/httpError');

const text = (value, name, max, required = true) => {
  if (typeof value !== 'string') {
    if (!required && (value === undefined || value === null)) return '';
    throw new HttpError(400, `${name} must be text`);
  }
  const result = value.trim();
  if (required && !result) throw new HttpError(400, `${name} is required`);
  if (result.length > max) throw new HttpError(400, `${name} is too long`);
  return result;
};

function bodySize(maxBytes) {
  return (req, _res, next) => {
    const length = Number(req.headers['content-length'] || 0);
    if (length > maxBytes) throw new HttpError(413, 'Request payload is too large');
    next();
  };
}

module.exports = { text, bodySize };
