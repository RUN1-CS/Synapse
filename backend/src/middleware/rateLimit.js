const { HttpError } = require('../utils/httpError');

function rateLimit({ windowMs, max, key = (req) => req.ip }) {
  const buckets = new Map();
  return (req, _res, next) => {
    const now = Date.now();
    const id = key(req);
    const current = buckets.get(id);
    if (!current || now - current.startedAt >= windowMs) {
      if (buckets.size > 10000) {
        for (const [bucket, value] of buckets) {
          if (now - value.startedAt >= windowMs) buckets.delete(bucket);
        }
      }
      buckets.set(id, { startedAt: now, count: 1 });
      next();
      return;
    }
    current.count += 1;
    if (current.count > max) {
      const retryAfter = Math.ceil((windowMs - (now - current.startedAt)) / 1000);
      throw new HttpError(429, `Too many requests. Try again in ${retryAfter} seconds`);
    }
    next();
  };
}

module.exports = rateLimit;
