ALTER TABLE messages ADD COLUMN client_message_id TEXT;
CREATE UNIQUE INDEX uq_messages_user_client_id
  ON messages (user_id, client_message_id)
  WHERE client_message_id IS NOT NULL;
