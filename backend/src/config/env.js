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
  databaseUrl: process.env.DATABASE_URL || 'postgres://chat:chat_password@localhost:5432/chat',
};
