ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT '';

CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  recipient_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  actor_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(32) NOT NULL,
  conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
  friend_request_id INTEGER REFERENCES friend_requests(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at TIMESTAMPTZ
);

CREATE INDEX idx_notifications_recipient_unread
  ON notifications (recipient_id, read_at, id DESC);
