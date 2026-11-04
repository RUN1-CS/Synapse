require('dotenv').config();

const maxTokenLifetimeDays = Number.parseInt(
  process.env.JWT_MAX_LIFETIME_DAYS || '7',
  10
);
const accessTokenLifetimeMinutes = Number.parseInt(
  process.env.JWT_ACCESS_LIFETIME_MINUTES || '15',
  10
);
const jwtSecret = process.env.JWT_SECRET || 'dev-secret';
const integer = (name, fallback, minimum = 1) => {
  const value = Number.parseInt(process.env[name] || fallback, 10);
  if (!Number.isInteger(value) || value < minimum) {
    throw new Error(`${name} must be an integer >= ${minimum}`);
  }
  return value;
};

if (!Number.isInteger(maxTokenLifetimeDays) || maxTokenLifetimeDays < 1 ||
    !Number.isInteger(accessTokenLifetimeMinutes) || accessTokenLifetimeMinutes < 1) {
  throw new Error('JWT lifetime settings must be positive integers');
}
if (process.env.NODE_ENV === 'production' &&
    (jwtSecret === 'dev-secret' || jwtSecret.length < 32)) {
  throw new Error('JWT_SECRET must be at least 32 characters in production');
}

module.exports = {
  port: process.env.PORT || 3000,
  jwtSecret,
  maxTokenLifetimeDays,
  accessTokenLifetimeMinutes,
  jsonBodyLimitBytes: integer('JSON_BODY_LIMIT_BYTES', '1048576'),
  avatarMaxBytes: integer('AVATAR_MAX_BYTES', '5242880'),
  multipartMaxFields: integer('MULTIPART_MAX_FIELDS', '8'),
  multipartMaxParts: integer('MULTIPART_MAX_PARTS', '10'),
  httpRateLimitWindowSeconds: integer('HTTP_RATE_LIMIT_WINDOW_SECONDS', '60'),
  httpRateLimitMaxRequests: integer('HTTP_RATE_LIMIT_MAX_REQUESTS', '120'),
  authRateLimitWindowSeconds: integer('AUTH_RATE_LIMIT_WINDOW_SECONDS', '900'),
  authRateLimitMaxRequests: integer('AUTH_RATE_LIMIT_MAX_REQUESTS', '10'),
  messageRateLimitWindowSeconds: integer('MESSAGE_RATE_LIMIT_WINDOW_SECONDS', '60'),
  messageRateLimitMaxMessages: integer('MESSAGE_RATE_LIMIT_MAX_MESSAGES', '30'),
  messageMaxLength: integer('MESSAGE_MAX_LENGTH', '4000'),
  messageHistoryPageSize: integer('MESSAGE_HISTORY_PAGE_SIZE', '50'),
  websocketRateLimitWindowSeconds: integer('WEBSOCKET_RATE_LIMIT_WINDOW_SECONDS', '10'),
  websocketRateLimitMaxEvents: integer('WEBSOCKET_RATE_LIMIT_MAX_EVENTS', '40'),
  websocketConnectionWindowSeconds: integer('WEBSOCKET_CONNECTION_WINDOW_SECONDS', '60'),
  websocketConnectionMaxAttempts: integer('WEBSOCKET_CONNECTION_MAX_ATTEMPTS', '20'),
  duplicateRequestWindowSeconds: integer('DUPLICATE_REQUEST_WINDOW_SECONDS', '10'),
  databaseUrl: process.env.DATABASE_URL || 'postgres://chat:chat_password@localhost:5432/chat',
};
