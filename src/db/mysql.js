const mysql = require('mysql2/promise');

const MYSQL_PORTS = [3306, 3307, 3308, 3309, 3310, 3311];

async function connectMySQLInstances() {
  const connections = [];

  for (let i = 0; i < MYSQL_PORTS.length; i++) {
    const port = MYSQL_PORTS[i];
    const connection = await mysql.createConnection({
      host: 'localhost',
      port,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.MYSQL_DB_SHARD,
    });

    connections.push({
      name: `mysql_shard${i + 1}`,
      client: connection,
    });
  }

  return connections;
}

module.exports = connectMySQLInstances;
