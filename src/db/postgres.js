const { Pool } = require('pg');

const PG_PORTS = [5432, 5433, 5434, 5435, 5436, 5437]; // puertos de tus contenedores

function connectPostgresInstances() {
  return PG_PORTS.map((port, index) => {
    const pool = new Pool({
      host: 'localhost',
      port,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.POSTGRES_DB_SHARD,
    });

    return {
      name: `pg_shard${index + 1}`,
      client: pool,
    };
  });
}

module.exports = connectPostgresInstances;
