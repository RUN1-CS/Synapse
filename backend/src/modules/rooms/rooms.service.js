const db = require('../../config/db');
const { HttpError } = require('../../utils/httpError');

async function list() {
  const { rows } = await db.query('SELECT id, name FROM rooms ORDER BY name');
  return rows;
}

async function create(name) {
  const clean = (name || '').trim();
  if (clean.length < 2) throw new HttpError(400, 'Room name must be at least 2 characters');
  try {
    const { rows } = await db.query('INSERT INTO rooms (name) VALUES ($1) RETURNING id, name', [clean]);
    return rows[0];
  } catch (e) {
    if (e.code === '23505') throw new HttpError(409, 'Room already exists');
    throw e;
  }
}

module.exports = { list, create };
