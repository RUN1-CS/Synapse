const test = require('node:test');
const assert = require('node:assert/strict');

const db = require('../src/config/db');
const conversations = require('../src/modules/conversations/conversations.service');
const messages = require('../src/modules/messages/messages.service');

const originalQuery = db.query;
const originalAssertMember = conversations.assertMember;

test.afterEach(() => {
  db.query = originalQuery;
  conversations.assertMember = originalAssertMember;
});

test('create returns the persisted message for an idempotent retry', async () => {
  const persisted = {
    id: 21,
    conversationId: 7,
    userId: 3,
    clientMessageId: 'client-1',
    content: 'hello',
    status: 'sent',
  };
  let calls = 0;
  conversations.assertMember = async () => {};
  db.query = async (sql) => {
    calls += 1;
    if (sql.includes('WHERE m.user_id = $1 AND m.client_message_id = $3')) {
      return { rows: [persisted] };
    }
    throw new Error(`Unexpected query: ${sql}`);
  };

  const result = await messages.create({
    conversationId: 7,
    userId: 3,
    content: 'hello',
    clientMessageId: 'client-1',
  });

  assert.deepEqual(result, persisted);
  assert.equal(calls, 1);
});

test('create rejects an invalid client message ID before persistence', async () => {
  conversations.assertMember = async () => {};
  db.query = async () => {
    throw new Error('database should not be queried');
  };

  await assert.rejects(
    messages.create({
      conversationId: 7,
      userId: 3,
      content: 'hello',
      clientMessageId: 'x'.repeat(129),
    }),
    (error) => error.status === 400 &&
      error.message === 'Invalid client message ID'
  );
});

test('listByConversation applies after cursor in ascending order', async () => {
  let query;
  conversations.assertMember = async () => {};
  db.query = async (sql, params) => {
    query = { sql, params };
    return { rows: [{ id: 22 }, { id: 23 }] };
  };

  const result = await messages.listByConversation(7, 3, {
    limit: 2,
    after: 21,
  });

  assert.deepEqual(result, [{ id: 22 }, { id: 23 }]);
  assert.match(query.sql, /m\.id > \$3/);
  assert.match(query.sql, /ORDER BY m\.id ASC/);
  assert.deepEqual(query.params, [7, 3, 21, 2]);
});

test('markDelivered is idempotent at the database boundary', async () => {
  let query;
  db.query = async (sql, params) => {
    query = { sql, params };
    return { rows: [{ messageId: 21 }] };
  };

  const result = await messages.markDelivered(21, 4);

  assert.deepEqual(result, { messageId: 21 });
  assert.match(query.sql, /ON CONFLICT DO NOTHING/);
  assert.deepEqual(query.params, [21, 4]);
});

test('markRead requires conversation membership and returns the read cursor', async () => {
  let query;
  let memberCheck;
  conversations.assertMember = async (...args) => {
    memberCheck = args;
  };
  db.query = async (sql, params) => {
    query = { sql, params };
    return { rows: [{ messageId: 21 }] };
  };

  const result = await messages.markRead(7, 4, 21);

  assert.deepEqual(memberCheck, [7, 4]);
  assert.deepEqual(result, { messageId: 21 });
  assert.match(query.sql, /conversation_reads/);
  assert.deepEqual(query.params, [7, 4, 21]);
});
