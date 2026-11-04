const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const { jwtSecret } = require('../../config/env');
const { HttpError } = require('../../utils/httpError');

const signToken = (user) => jwt.sign(
  {
    id: user.id,
    username: user.username,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
  },
  jwtSecret,
  { expiresIn: '7d' }
);
const verifyToken = (token) => jwt.verify(token, jwtSecret);

async function register(username, password, displayName = username) {
  if (!username || username.length < 3) throw new HttpError(400, 'Username must be at least 3 characters');
  if (!password || password.length < 6) throw new HttpError(400, 'Password must be at least 6 characters');
  const name = displayName.trim();
  if (!name) throw new HttpError(400, 'Display name is required');
  const hash = await bcrypt.hash(password, 10);
  try {
    const { rows } = await db.query(
      'INSERT INTO users (username, display_name, password_hash) VALUES ($1, $2, $3) RETURNING id, username, display_name AS "displayName", avatar_url AS "avatarUrl"',
      [username, name, hash]
    );
    return { user: rows[0], token: signToken(rows[0]) };
  } catch (e) {
    if (e.code === '23505') throw new HttpError(409, 'Username already taken');
    throw e;
  }
}

async function login(username, password) {
  const { rows } = await db.query('SELECT * FROM users WHERE username = $1', [username]);
  const row = rows[0];
  if (!row || !(await bcrypt.compare(password || '', row.password_hash))) {
    throw new HttpError(401, 'Invalid username or password');
  }
  const user = {
    id: row.id,
    username: row.username,
    displayName: row.display_name,
    avatarUrl: row.avatar_url,
  };
  return { user, token: signToken(user) };
}

async function updateDisplayName(userId, displayName) {
  const name = (displayName || '').trim();
  if (!name) throw new HttpError(400, 'Display name is required');
  if (name.length > 64) throw new HttpError(400, 'Display name must be at most 64 characters');
  const { rows } = await db.query(
    'UPDATE users SET display_name = $1 WHERE id = $2 RETURNING id, username, display_name AS "displayName", avatar_url AS "avatarUrl"',
    [name, userId]
  );
  return rows[0];
}

async function updateAvatar(userId, filename) {
  const previous = await db.query(
    'SELECT avatar_url AS "avatarUrl" FROM users WHERE id = $1',
    [userId]
  );
  const { rows } = await db.query(
    `UPDATE users SET avatar_url = $1
     WHERE id = $2
     RETURNING id, username, display_name AS "displayName", avatar_url AS "avatarUrl"`,
    [`/uploads/${filename}`, userId]
  );
  return { user: rows[0], oldAvatarUrl: previous.rows[0]?.avatarUrl };
}

module.exports = {
  register,
  login,
  updateDisplayName,
  updateAvatar,
  verifyToken,
  signToken,
};
