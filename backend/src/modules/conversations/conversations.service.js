const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');

async function listUsers(userId) {
  const { rows } = await db.query(
    'SELECT id, username FROM users WHERE id <> $1 ORDER BY username',
    [userId]
  );
  return rows;
}

async function listForUser(userId) {
  const { rows } = await db.query(
    `SELECT c.id,
            other.id AS "userId",
            other.username,
            latest.content AS "latestContent",
            latest.user_id AS "latestUserId",
            latest.username AS "latestUsername",
            latest.created_at AS "latestCreatedAt"
     FROM conversations c
     JOIN users other ON other.id = CASE
       WHEN c.user_one_id = $1 THEN c.user_two_id ELSE c.user_one_id END
     LEFT JOIN LATERAL (
       SELECT m.content, m.user_id, u.username, m.created_at
       FROM messages m
       JOIN users u ON u.id = m.user_id
       WHERE m.conversation_id = c.id
       ORDER BY m.id DESC
       LIMIT 1
     ) latest ON true
     WHERE c.user_one_id = $1 OR c.user_two_id = $1
     ORDER BY latest.created_at DESC NULLS LAST, c.created_at DESC`,
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

module.exports = { listUsers, listForUser, getOrCreate, assertMember };
