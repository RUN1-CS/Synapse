const test = require('node:test');
const assert = require('node:assert/strict');

const db = require('../src/config/db');
const auth = require('../src/modules/auth/auth.service');

const originalQuery = db.query;

test.afterEach(() => {
  db.query = originalQuery;
});

test('register rejects usernames containing unsupported characters', async () => {
  db.query = async () => {
    throw new Error('database should not be queried');
  };

  await assert.rejects(
    auth.register('bad-name', 'password', 'Display'),
    (error) => error.status === 400 &&
      error.message.includes('Username may contain only')
  );
});

test('register rejects passwords shorter than six characters', async () => {
  db.query = async () => {
    throw new Error('database should not be queried');
  };

  await assert.rejects(
    auth.register('valid_user', 'short', 'Display'),
    (error) => error.status === 400 &&
      error.message === 'Password must be at least 6 characters'
  );
});

test('login rejects malformed usernames without querying the database', async () => {
  db.query = async () => {
    throw new Error('database should not be queried');
  };

  await assert.rejects(
    auth.login('not valid', 'password'),
    (error) => error.status === 401 &&
      error.message === 'Invalid username or password'
  );
});
