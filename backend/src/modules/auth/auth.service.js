const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const { jwtSecret } = require('../../config/env');
const { HttpError } = require('../../utils/httpError');

const signToken = (user) => jwt.sign({ id: user.id, username: user.username }, jwtSecret, { expiresIn: '7d' });
const verifyToken = (token) => jwt.verify(token, jwtSecret);

async function register(username, password) {
  if (!username || username.length < 3) throw new HttpError(400, 'Username must be at least 3 characters');
  if (!password || password.length < 6) throw new HttpError(400, 'Password must be at least 6 characters');
  const hash = await bcrypt.hash(password, 10);
  try {
    const { rows } = await db.query(
      'INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id, username',
      [username, hash]
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
  const user = { id: row.id, username: row.username };
  return { user, token: signToken(user) };
}

module.exports = { register, login, verifyToken };
