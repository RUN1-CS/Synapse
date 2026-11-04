const http = require('http');
const { port } = require('./config/env');
const migrate = require('./db/migrate');
const app = require('./app');
const initSockets = require('./sockets');

(async () => {
  await migrate();
  const server = http.createServer(app);
  initSockets(server);
  server.listen(port, () => console.log(`API listening on :${port}`));
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
