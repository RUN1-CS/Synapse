DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS rooms;

CREATE TABLE conversations (
  id SERIAL PRIMARY KEY,
  user_one_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_two_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (user_one_id < user_two_id),
  UNIQUE (user_one_id, user_two_id)
);

CREATE TABLE messages (
  id BIGSERIAL PRIMARY KEY,
  conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_conversation_id_id ON messages (conversation_id, id DESC);
