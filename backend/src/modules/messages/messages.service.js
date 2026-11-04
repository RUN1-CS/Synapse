const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');
const conversations = require('../conversations/conversations.service');
const {
  messageMaxLength,
  messageRateLimitWindowSeconds,
  messageRateLimitMaxMessages,
  messageHistoryPageSize,
} = require('../../config/env');
const { text: validateText } = require('../../middleware/validate');

function columns() {
  return `m.id, m.conversation_id AS "conversationId", m.user_id AS "userId",
    m.client_message_id AS "clientMessageId", u.username,
    u.display_name AS "displayName", u.avatar_url AS "avatarUrl",
    m.content, m.created_at AS "createdAt",
    CASE
      WHEN m.user_id = $2 THEN
        CASE WHEN EXISTS (
          SELECT 1 FROM conversation_reads cr
          WHERE cr.conversation_id = m.conversation_id
            AND cr.user_id <> m.user_id
            AND cr.last_read_message_id >= m.id
        ) THEN 'read'
        WHEN EXISTS (
          SELECT 1 FROM message_deliveries md
          WHERE md.message_id = m.id AND md.user_id <> m.user_id
        ) THEN 'delivered'
        ELSE 'sent' END
      WHEN EXISTS (
        SELECT 1 FROM message_deliveries md
        WHERE md.message_id = m.id AND md.user_id = $2
      ) THEN 'delivered'
      ELSE 'sent'
    END AS status`;
}

async function listByConversation(conversationId, userId, { limit, before, after } = {}) {
  await conversations.assertMember(conversationId, userId);
  if ((before !== undefined && !Number.isSafeInteger(Number(before))) ||
      (after !== undefined && !Number.isSafeInteger(Number(after)))) {
    throw new HttpError(400, 'Invalid message cursor');
  }
  const pageSize = Math.min(Number(limit) || messageHistoryPageSize, messageHistoryPageSize);
  let where = 'm.conversation_id = $1';
  const params = [conversationId, userId];
  if (before) {
    params.push(Number(before));
    where += ` AND m.id < $${params.length}`;
  }
  if (after) {
    params.push(Number(after));
    where += ` AND m.id > $${params.length}`;
  }
  params.push(pageSize);
  const { rows } = await db.query(
    `SELECT ${columns()} FROM messages m JOIN users u ON u.id = m.user_id
     WHERE ${where} ORDER BY m.id ${after ? 'ASC' : 'DESC'} LIMIT $${params.length}`,
    params
  );
  return after ? rows : rows.reverse();
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
      `SELECT ${columns()} FROM messages m JOIN users u ON u.id = m.user_id
       WHERE m.user_id = $1 AND m.client_message_id = $3`,
      [userId, userId, clientMessageId]
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
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, client_message_id)
       WHERE client_message_id IS NOT NULL DO NOTHING
       RETURNING *
     ) SELECT ${columns()} FROM m JOIN users u ON u.id = m.user_id`,
    [conversationId, userId, messageText, clientMessageId || null]
  );
  if (!rows[0] && clientMessageId) {
    const existing = await db.query(
      `SELECT ${columns()} FROM messages m JOIN users u ON u.id = m.user_id
       WHERE m.user_id = $1 AND m.client_message_id = $3`,
      [userId, userId, clientMessageId]
    );
    if (existing.rows[0]) return existing.rows[0];
    throw new HttpError(409, 'Message submission conflict');
  }
  const message = rows[0];
  const recipient = await db.query(
    `SELECT CASE WHEN user_one_id = $1 THEN user_two_id ELSE user_one_id END AS "recipientId"
     FROM conversations WHERE id = $2`,
    [userId, conversationId]
  );
  if (recipient.rows[0]) {
    const recipientId = recipient.rows[0].recipientId;
    const suppressed = await db.query(
      `SELECT EXISTS (SELECT 1 FROM muted_users WHERE muter_id = $1 AND muted_id = $2) AS muted,
              EXISTS (SELECT 1 FROM blocked_users WHERE
                (blocker_id = $1 AND blocked_id = $2) OR
                (blocker_id = $2 AND blocked_id = $1)) AS blocked`,
      [recipientId, userId]
    );
    if (!suppressed.rows[0].muted && !suppressed.rows[0].blocked) {
      await db.query(
        `INSERT INTO notifications (recipient_id, actor_id, type, conversation_id)
         VALUES ($1, $2, 'message', $3)`,
        [recipientId, userId, conversationId]
      );
    }
  }
  return message;
}

async function markDelivered(messageId, userId) {
  const result = await db.query(
    `INSERT INTO message_deliveries (message_id, user_id)
     SELECT m.id, $2 FROM messages m
     JOIN conversations c ON c.id = m.conversation_id
     WHERE m.id = $1 AND m.user_id <> $2
       AND (c.user_one_id = $2 OR c.user_two_id = $2)
     ON CONFLICT DO NOTHING
     RETURNING message_id AS "messageId"`,
    [messageId, userId]
  );
  return result.rows[0] || null;
}

async function markRead(conversationId, userId, messageId) {
  await conversations.assertMember(conversationId, userId);
  const result = await db.query(
    `INSERT INTO conversation_reads (conversation_id, user_id, last_read_message_id)
     SELECT $1, $2, m.id FROM messages m
     WHERE m.id = $3 AND m.conversation_id = $1
     ON CONFLICT (conversation_id, user_id)
     DO UPDATE SET last_read_message_id = GREATEST(
       conversation_reads.last_read_message_id, EXCLUDED.last_read_message_id
     ), read_at = now()
     RETURNING last_read_message_id AS "messageId"`,
    [conversationId, userId, messageId]
  );
  return result.rows[0] || null;
}

module.exports = { listByConversation, create, markDelivered, markRead };
