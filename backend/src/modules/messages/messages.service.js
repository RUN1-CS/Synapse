const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');
const conversations = require('../conversations/conversations.service');
const {
  messageMaxLength,
  messageRateLimitWindowSeconds,
  messageRateLimitMaxMessages,
} = require('../../config/env');
const { text: validateText } = require('../../middleware/validate');

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

async function create({ conversationId, userId, content, clientMessageId }) {
  await conversations.assertMember(conversationId, userId);
  const messageText = validateText(content, 'Message', messageMaxLength);
  if (clientMessageId !== undefined &&
      (typeof clientMessageId !== 'string' || clientMessageId.length > 128)) {
    throw new HttpError(400, 'Invalid client message ID');
  }
  if (clientMessageId) {
    const existing = await db.query(
      `SELECT ${COLUMNS} FROM messages m JOIN users u ON u.id = m.user_id
       WHERE m.user_id = $1 AND m.client_message_id = $2`,
      [userId, clientMessageId]
    );
    if (existing.rows[0]) return existing.rows[0];
  }
  const recent = await db.query(
    `SELECT COUNT(*)::int AS count FROM messages
     WHERE user_id = $1 AND created_at >= now() - ($2 * interval '1 second')`,
    [userId, messageRateLimitWindowSeconds]
  );
  if (recent.rows[0].count >= messageRateLimitMaxMessages) {
    throw new HttpError(429, 'Message sending limit reached');
  }
  const { rows } = await db.query(
    `WITH m AS (
       INSERT INTO messages (conversation_id, user_id, content, client_message_id)
       VALUES ($1, $2, $3, $4) RETURNING *
     ) SELECT ${COLUMNS} FROM m JOIN users u ON u.id = m.user_id`,
    [conversationId, userId, messageText, clientMessageId || null]
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
