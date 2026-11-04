const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');
const conversations = require('../conversations/conversations.service');

const COLUMNS = `m.id, m.conversation_id AS "conversationId", m.user_id AS "userId", u.username,
                 u.display_name AS "displayName",
                 u.avatar_url AS "avatarUrl",
                 m.content, m.created_at AS "createdAt"`;

async function listByConversation(conversationId, userId, limit = 50) {
  await conversations.assertMember(conversationId, userId);
  const { rows } = await db.query(
    `SELECT ${COLUMNS} FROM messages m JOIN users u ON u.id = m.user_id
     WHERE m.conversation_id = $1 ORDER BY m.id DESC LIMIT $2`,
    [conversationId, limit]
  );
  return rows.reverse();
}

async function create({ conversationId, userId, content }) {
  await conversations.assertMember(conversationId, userId);
  const text = (content || '').trim();
  if (!text) throw new HttpError(400, 'Message is empty');
  const { rows } = await db.query(
    `WITH m AS (
       INSERT INTO messages (conversation_id, user_id, content) VALUES ($1, $2, $3) RETURNING *
     ) SELECT ${COLUMNS} FROM m JOIN users u ON u.id = m.user_id`,
    [conversationId, userId, text]
  );
  const message = rows[0];
  const recipient = await db.query(
    `SELECT CASE WHEN user_one_id = $1 THEN user_two_id ELSE user_one_id END AS "recipientId"
     FROM conversations WHERE id = $2`,
    [userId, conversationId]
  );
  if (recipient.rows[0]) {
    const suppressed = await db.query(
      `SELECT EXISTS (SELECT 1 FROM muted_users WHERE muter_id = $1 AND muted_id = $2) AS muted,
              EXISTS (SELECT 1 FROM blocked_users WHERE
                (blocker_id = $1 AND blocked_id = $2) OR
                (blocker_id = $2 AND blocked_id = $1)) AS blocked`,
      [recipient.rows[0].recipientId, userId]
    );
    if (suppressed.rows[0].muted || suppressed.rows[0].blocked) return message;
    await db.query(
      `INSERT INTO notifications (recipient_id, actor_id, type, conversation_id)
       VALUES ($1, $2, 'message', $3)`,
      [recipient.rows[0].recipientId, userId, conversationId]
    );
  }
  return message;
}

module.exports = { listByConversation, create };
