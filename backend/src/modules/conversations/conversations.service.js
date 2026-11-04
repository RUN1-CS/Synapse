const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');

async function listUsers(userId, search = '') {
  const { rows } = await db.query(
    `SELECT u.id, u.username, u.display_name AS "displayName", u.avatar_url AS "avatarUrl", u.bio,
       CASE
         WHEN EXISTS (SELECT 1 FROM friend_requests f WHERE f.status = 'accepted'
           AND ((f.requester_id = $1 AND f.recipient_id = u.id)
             OR (f.requester_id = u.id AND f.recipient_id = $1))) THEN 'accepted'
         WHEN EXISTS (SELECT 1 FROM friend_requests f WHERE f.status = 'pending'
           AND f.requester_id = u.id AND f.recipient_id = $1) THEN 'incoming'
         WHEN EXISTS (SELECT 1 FROM friend_requests f WHERE f.status = 'pending'
           AND f.requester_id = $1 AND f.recipient_id = u.id) THEN 'outgoing'
         ELSE 'none'
       END AS "friendStatus",
       EXISTS (SELECT 1 FROM muted_users m WHERE m.muter_id = $1 AND m.muted_id = u.id) AS muted,
       EXISTS (SELECT 1 FROM blocked_users b WHERE b.blocker_id = $1 AND b.blocked_id = u.id) AS blocked,
       EXISTS (SELECT 1 FROM blocked_users b WHERE b.blocker_id = u.id AND b.blocked_id = $1) AS "blockedByUser"
     FROM users u WHERE u.id <> $1
       AND (u.username ILIKE $2 OR u.display_name ILIKE $2)
     ORDER BY u.display_name`,
    [userId, `%${search}%`]
  );
  return rows;
}

async function profile(userId, otherUserId) {
  const rows = await listUsers(userId);
  const user = rows.find((item) => item.id === Number(otherUserId));
  if (!user) throw new HttpError(404, 'User not found');
  return user;
}

async function assertFriends(userId, otherUserId) {
  const { rows } = await db.query(
    `SELECT EXISTS (SELECT 1 FROM friend_requests f WHERE f.status = 'accepted'
       AND ((f.requester_id = $1 AND f.recipient_id = $2)
         OR (f.requester_id = $2 AND f.recipient_id = $1))) AS friends,
       EXISTS (SELECT 1 FROM blocked_users b
         WHERE (b.blocker_id = $1 AND b.blocked_id = $2)
            OR (b.blocker_id = $2 AND b.blocked_id = $1)) AS blocked`,
    [userId, otherUserId]
  );
  if (!rows[0].friends) throw new HttpError(403, 'You must be friends before starting a chat');
  if (rows[0].blocked) throw new HttpError(403, 'This user is blocked');
}

async function requestFriend(userId, otherUserId) {
  const other = Number(otherUserId);
  if (!Number.isInteger(other) || other <= 0 || other === userId) {
    throw new HttpError(400, 'Choose another user');
  }
  const { rows } = await db.query(
    `SELECT 1 FROM blocked_users
     WHERE (blocker_id = $1 AND blocked_id = $2) OR (blocker_id = $2 AND blocked_id = $1)`,
    [userId, other]
  );
  if (rows[0]) throw new HttpError(403, 'Cannot request friendship with a blocked user');
  const pending = await db.query(
    `SELECT id, status FROM friend_requests
     WHERE requester_id = $1 AND recipient_id = $2 AND status = 'pending'`,
    [userId, other]
  );
  if (pending.rows[0]) return pending.rows[0];
  const result = await db.query(
    `INSERT INTO friend_requests (requester_id, recipient_id, status)
     VALUES ($1, $2, 'pending')
     ON CONFLICT (requester_id, recipient_id)
     DO UPDATE SET status = 'pending', created_at = now()
     RETURNING id, status`,
    [userId, other]
  );
  await db.query(
    `INSERT INTO notifications (recipient_id, actor_id, type, friend_request_id)
     VALUES ($1, $2, 'friend_request', $3)`,
    [other, userId, result.rows[0].id]
  );
  return result.rows[0];
}

async function respondFriend(userId, otherUserId, accept) {
  const other = Number(otherUserId);
  const result = await db.query(
    `UPDATE friend_requests SET status = $1
     WHERE requester_id = $2 AND recipient_id = $3 AND status = 'pending'
     RETURNING id`,
    [accept ? 'accepted' : 'rejected', other, userId]
  );
  if (!result.rows[0]) throw new HttpError(404, 'Friend request not found');
  return result.rows[0];
}

async function setMuted(userId, otherUserId, muted) {
  if (muted) {
    await db.query(
      `INSERT INTO muted_users (muter_id, muted_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [userId, Number(otherUserId)]
    );
  } else {
    await db.query('DELETE FROM muted_users WHERE muter_id = $1 AND muted_id = $2',
      [userId, Number(otherUserId)]);
  }
}

async function setBlocked(userId, otherUserId, blocked) {
  if (blocked) {
    await db.query(
      `INSERT INTO blocked_users (blocker_id, blocked_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [userId, Number(otherUserId)]
    );
  } else {
    await db.query('DELETE FROM blocked_users WHERE blocker_id = $1 AND blocked_id = $2',
      [userId, Number(otherUserId)]);
  }
}

async function listForUser(userId) {
  const { rows } = await db.query(
    `SELECT c.id,
            other.id AS "userId",
            other.username,
            other.display_name AS "displayName",
            other.avatar_url AS "avatarUrl",
            latest.content AS "latestContent",
            latest.user_id AS "latestUserId",
            latest.username AS "latestUsername",
            latest.display_name AS "latestDisplayName",
            latest.avatar_url AS "latestAvatarUrl",
            latest.created_at AS "latestCreatedAt"
     FROM conversations c
     JOIN users other ON other.id = CASE
       WHEN c.user_one_id = $1 THEN c.user_two_id ELSE c.user_one_id END
     LEFT JOIN LATERAL (
       SELECT m.content, m.user_id, u.username, u.display_name, u.avatar_url, m.created_at
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
  await assertFriends(userId, other);
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
    `SELECT id, user_one_id, user_two_id FROM conversations
     WHERE id = $1 AND (user_one_id = $2 OR user_two_id = $2)`,
    [conversationId, userId]
  );
  if (!rows[0]) throw new HttpError(403, 'You are not part of this conversation');
  const other = rows[0].user_one_id === userId ? rows[0].user_two_id : rows[0].user_one_id;
  await assertFriends(userId, other);
}

module.exports = {
  listUsers, profile, listForUser, getOrCreate, assertMember, requestFriend,
  respondFriend, setMuted, setBlocked,
};
