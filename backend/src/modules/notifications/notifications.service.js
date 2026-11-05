const db = require('../../config/db');

async function list(userId) {
  const { rows } = await db.query(
    `SELECT n.id, n.type, n.created_at AS "createdAt",
            a.id AS "actorId", a.username, a.display_name AS "displayName",
            a.avatar_url AS "avatarUrl", a.bio,
            n.friend_request_id AS "friendRequestId",
            n.conversation_id AS "conversationId"
     FROM notifications n
     LEFT JOIN users a ON a.id = n.actor_id
     WHERE n.recipient_id = $1 AND n.read_at IS NULL
     ORDER BY n.id DESC`,
    [userId]
  );
  return rows;
}

async function markRead(userId, notificationId) {
  await db.query(
    'UPDATE notifications SET read_at = now() WHERE id = $1 AND recipient_id = $2',
    [notificationId, userId]
  );
}

async function markConversationRead(userId, conversationId) {
  await db.query(
    `UPDATE notifications SET read_at = now()
     WHERE recipient_id = $1 AND conversation_id = $2 AND read_at IS NULL`,
    [userId, conversationId]
  );
}

async function markAllRead(userId) {
  await db.query(
    'UPDATE notifications SET read_at = now() WHERE recipient_id = $1 AND read_at IS NULL',
    [userId]
  );
}

module.exports = { list, markRead, markConversationRead, markAllRead };
