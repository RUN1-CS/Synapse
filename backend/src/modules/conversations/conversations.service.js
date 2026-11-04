const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');

async function listUsers(userId) {
  const { rows } = await db.query(
    'SELECT id, username FROM users WHERE id <> $1 ORDER BY username',
    [userId]
  );
  return rows;
}

async function getOrCreate(userId, otherUserId) {
  const other = Number(otherUserId);
  if (!Number.isInteger(other) || other <= 0 || other === userId) {
    throw new HttpError(400, 'Choose another user');
  }

  const first = Math.min(userId, other);
  const second = Math.max(userId, other);
  const { rows } = await db.query(
    `INSERT INTO conversations (user_one_id, user_two_id) VALUES ($1, $2)
     ON CONFLICT (user_one_id, user_two_id) DO UPDATE SET user_one_id = EXCLUDED.user_one_id
     RETURNING id`,
    [first, second]
  );
  return rows[0];
}

async function assertMember(conversationId, userId) {
  const { rows } = await db.query(
    `SELECT id FROM conversations
     WHERE id = $1 AND (user_one_id = $2 OR user_two_id = $2)`,
    [conversationId, userId]
  );
  if (!rows[0]) throw new HttpError(403, 'You are not part of this conversation');
}

module.exports = { listUsers, getOrCreate, assertMember };
