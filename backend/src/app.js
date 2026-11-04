const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', require('./modules/auth/auth.routes'));
app.use('/api/conversations', require('./modules/conversations/conversations.routes'));
app.use('/api/notifications', require('./modules/notifications/notifications.routes'));

// Error handler
app.use((err, _req, res, _next) => {
  if (!err.status) console.error(err);
  res.status(err.status || 500).json({ error: err.status ? err.message : 'Internal server error' });
});

module.exports = app;
