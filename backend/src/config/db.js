const { Pool } = require('pg');
const { databaseUrl } = require('./env');

const pool = new Pool({ connectionString: databaseUrl });

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
