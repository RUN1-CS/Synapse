const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');

const COLUMNS = `m.id, m.room_id AS "roomId", m.user_id AS "userId", u.username,
                 m.content, m.created_at AS "createdAt"`;

async function listByRoom(roomId, limit = 50) {
  const { rows } = await db.query(
    `SELECT ${COLUMNS} FROM messages m JOIN users u ON u.id = m.user_id
     WHERE m.room_id = $1 ORDER BY m.id DESC LIMIT $2`,
    [roomId, limit]
  );
  return rows.reverse();
}

async function create({ roomId, userId, content }) {
  const text = (content || '').trim();
  if (!text) throw new HttpError(400, 'Message is empty');
  const { rows } = await db.query(
    `WITH m AS (
       INSERT INTO messages (room_id, user_id, content) VALUES ($1, $2, $3) RETURNING *
     ) SELECT ${COLUMNS} FROM m JOIN users u ON u.id = m.user_id`,
    [roomId, userId, text]
  );
  return rows[0];
}

module.exports = { listByRoom, create };
