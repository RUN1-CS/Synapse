const express = require('express');
const cors = require('cors');
const path = require('path');
const {
  jsonBodyLimitBytes,
  httpRateLimitWindowSeconds,
  httpRateLimitMaxRequests,
  duplicateRequestWindowSeconds,
} = require('./config/env');
const rateLimit = require('./middleware/rateLimit');
const { bodySize } = require('./middleware/validate');
const duplicateRequest = require('./middleware/duplicateRequest');

const app = express();
app.use(cors());
app.use(bodySize(jsonBodyLimitBytes));
app.use(express.json({ limit: jsonBodyLimitBytes }));
app.use(rateLimit({
  windowMs: httpRateLimitWindowSeconds * 1000,
  max: httpRateLimitMaxRequests,
}));
app.use(duplicateRequest(duplicateRequestWindowSeconds * 1000));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', require('./modules/auth/auth.routes'));
app.use('/api/conversations', require('./modules/conversations/conversations.routes'));
app.use('/api/notifications', require('./modules/notifications/notifications.routes'));

// Error handler
app.use((err, _req, res, _next) => {
  if (err.code === 'LIMIT_FILE_SIZE' || err.type === 'entity.too.large') {
    res.status(413).json({ error: 'Uploaded file is too large' });
    return;
  }
  if (err.message === 'Profile picture must be an image') {
    res.status(400).json({ error: err.message });
    return;
  }
  if (err instanceof SyntaxError && err.status === 400 && err.type === 'entity.parse.failed') {
    res.status(400).json({ error: 'Invalid JSON payload' });
    return;
  }
  if (!err.status) console.error(err);
  res.status(err.status || 500).json({ error: err.status ? err.message : 'Internal server error' });
});

module.exports = app;
