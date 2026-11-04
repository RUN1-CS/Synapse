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
  return rows[0];
}

module.exports = { listByConversation, create };
