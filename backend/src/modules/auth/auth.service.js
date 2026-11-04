const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const {
  jwtSecret,
  maxTokenLifetimeDays,
  accessTokenLifetimeMinutes,
} = require('../../config/env');
const { HttpError } = require('../../utils/httpError');

const hashRefreshToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

function accessToken(user, sessionId) {
  return jwt.sign(
    {
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
      sid: sessionId,
    },
    jwtSecret,
    { expiresIn: `${accessTokenLifetimeMinutes}m` }
  );
}

function verifyToken(token) {
  return jwt.verify(token, jwtSecret);
}

async function createSession(user, userAgent) {
  const sessionId = crypto.randomUUID();
  const familyId = crypto.randomUUID();
  const secret = crypto.randomBytes(48).toString('base64url');
  const refreshToken = `${sessionId}.${secret}`;
  await db.query(
    `INSERT INTO auth_sessions
       (id, user_id, family_id, refresh_token_hash, expires_at, user_agent)
     VALUES ($1, $2, $3, $4, now() + ($5 * interval '1 day'), $6)`,
    [sessionId, user.id, familyId, hashRefreshToken(refreshToken),
      maxTokenLifetimeDays, userAgent || null]
  );
  const token = accessToken(user, sessionId);
  return {
    token,
    accessToken: token,
    refreshToken,
  };
}

async function validateToken(token) {
  const payload = verifyToken(token);
  const { rows } = await db.query(
    `SELECT 1 FROM auth_sessions
     WHERE id = $1 AND user_id = $2 AND revoked_at IS NULL AND expires_at > now()`,
    [payload.sid, payload.id]
  );
  if (!rows[0]) throw new HttpError(401, 'Unauthorized');
  return payload;
}

async function refresh(refreshToken, userAgent) {
  const parts = (refreshToken || '').split('.');
  if (parts.length !== 2) throw new HttpError(401, 'Invalid refresh token');
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      `SELECT s.*, u.username, u.display_name AS "displayName",
              u.avatar_url AS "avatarUrl", u.bio
       FROM auth_sessions s JOIN users u ON u.id = s.user_id
       WHERE s.id = $1 FOR UPDATE`,
      [parts[0]]
    );
    const session = result.rows[0];
    if (!session || session.refresh_token_hash !== hashRefreshToken(refreshToken)) {
      if (session) {
        await client.query(
          'UPDATE auth_sessions SET revoked_at = COALESCE(revoked_at, now()) WHERE family_id = $1',
          [session.family_id]
        );
      }
      throw new HttpError(401, 'Invalid refresh token');
    }
    if (session.revoked_at) {
      await client.query(
        'UPDATE auth_sessions SET revoked_at = COALESCE(revoked_at, now()) WHERE family_id = $1',
        [session.family_id]
      );
      throw new HttpError(401, 'Refresh token reuse detected');
    }
    if (new Date(session.expires_at) <= new Date()) {
      throw new HttpError(401, 'Refresh token expired');
    }
    const user = {
      id: session.user_id,
      username: session.username,
      displayName: session.displayName,
      avatarUrl: session.avatarUrl,
      bio: session.bio,
    };
    const nextId = crypto.randomUUID();
    const secret = crypto.randomBytes(48).toString('base64url');
    const nextRefresh = `${nextId}.${secret}`;
    await client.query(
      `UPDATE auth_sessions SET revoked_at = now(), last_used_at = now()
       WHERE id = $1`,
      [session.id]
    );
    await client.query(
      `INSERT INTO auth_sessions
         (id, user_id, family_id, refresh_token_hash, expires_at, user_agent)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [nextId, session.user_id, session.family_id, hashRefreshToken(nextRefresh),
        session.expires_at, userAgent || session.user_agent]
    );
    await client.query('COMMIT');
    return {
      user,
      token: accessToken(user, nextId),
      accessToken: accessToken(user, nextId),
      refreshToken: nextRefresh,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function register(username, password, displayName = username, userAgent) {
  if (!username || username.length < 3) throw new HttpError(400, 'Username must be at least 3 characters');
  if (!password || password.length < 6) throw new HttpError(400, 'Password must be at least 6 characters');
  const name = displayName.trim();
  if (!name) throw new HttpError(400, 'Display name is required');
  const hash = await bcrypt.hash(password, 12);
  try {
    const { rows } = await db.query(
      `INSERT INTO users (username, display_name, password_hash)
       VALUES ($1, $2, $3)
       RETURNING id, username, display_name AS "displayName",
                 avatar_url AS "avatarUrl", bio`,
      [username, name, hash]
    );
    return { user: rows[0], ...(await createSession(rows[0], userAgent)) };
  } catch (e) {
    if (e.code === '23505') throw new HttpError(409, 'Username already taken');
    throw e;
  }
}

async function login(username, password, userAgent) {
  const { rows } = await db.query('SELECT * FROM users WHERE username = $1', [username]);
  const row = rows[0];
  if (!row || !(await bcrypt.compare(password || '', row.password_hash))) {
    throw new HttpError(401, 'Invalid username or password');
  }
  const user = {
    id: row.id, username: row.username, displayName: row.display_name,
    avatarUrl: row.avatar_url, bio: row.bio,
  };
  return { user, ...(await createSession(user, userAgent)) };
}

async function updateDisplayName(userId, displayName) {
  const name = (displayName || '').trim();
  if (!name) throw new HttpError(400, 'Display name is required');
  if (name.length > 64) throw new HttpError(400, 'Display name must be at most 64 characters');
  const { rows } = await db.query(
    'UPDATE users SET display_name = $1 WHERE id = $2 RETURNING id, username, display_name AS "displayName", avatar_url AS "avatarUrl", bio',
    [name, userId]
  );
  return rows[0];
}

async function updateBio(userId, bio) {
  const text = (bio || '').trim();
  if (text.length > 500) throw new HttpError(400, 'Bio must be at most 500 characters');
  const { rows } = await db.query(
    `UPDATE users SET bio = $1 WHERE id = $2
     RETURNING id, username, display_name AS "displayName", avatar_url AS "avatarUrl", bio`,
    [text, userId]
  );
  return rows[0];
}

async function updateAvatar(userId, filename) {
  const previous = await db.query('SELECT avatar_url AS "avatarUrl" FROM users WHERE id = $1', [userId]);
  const { rows } = await db.query(
    `UPDATE users SET avatar_url = $1 WHERE id = $2
     RETURNING id, username, display_name AS "displayName", avatar_url AS "avatarUrl", bio`,
    [`/uploads/${filename}`, userId]
  );
  return { user: rows[0], oldAvatarUrl: previous.rows[0]?.avatarUrl };
}

async function revokeSession(userId, sessionId) {
  await db.query(
    'UPDATE auth_sessions SET revoked_at = COALESCE(revoked_at, now()) WHERE id = $1 AND user_id = $2',
    [sessionId, userId]
  );
}

async function revokeAllSessions(userId) {
  await db.query(
    'UPDATE auth_sessions SET revoked_at = COALESCE(revoked_at, now()) WHERE user_id = $1',
    [userId]
  );
}

async function changePassword(userId, currentPassword, newPassword, userAgent) {
  if (!newPassword || newPassword.length < 6) throw new HttpError(400, 'New password must be at least 6 characters');
  const existing = await db.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  if (!existing.rows[0] || !(await bcrypt.compare(currentPassword || '', existing.rows[0].password_hash))) {
    throw new HttpError(401, 'Current password is incorrect');
  }
  if (await bcrypt.compare(newPassword, existing.rows[0].password_hash)) {
    throw new HttpError(400, 'New password must differ from the current password');
  }
  const hash = await bcrypt.hash(newPassword, 12);
  const { rows } = await db.query(
    `UPDATE users SET password_hash = $1 WHERE id = $2
     RETURNING id, username, display_name AS "displayName", avatar_url AS "avatarUrl", bio`,
    [hash, userId]
  );
  await revokeAllSessions(userId);
  return { user: rows[0], ...(await createSession(rows[0], userAgent)) };
}

async function listSessions(userId, currentSessionId) {
  const { rows } = await db.query(
    `SELECT id, created_at AS "createdAt", last_used_at AS "lastUsedAt",
            expires_at AS "expiresAt", user_agent AS "userAgent",
            (id = $2) AS "current"
     FROM auth_sessions
     WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > now()
     ORDER BY last_used_at DESC`,
    [userId, currentSessionId]
  );
  return rows;
}

module.exports = {
  register, login, refresh, updateDisplayName, updateBio, updateAvatar,
  changePassword, revokeSession, revokeAllSessions, listSessions,
  verifyToken, validateToken,
};
