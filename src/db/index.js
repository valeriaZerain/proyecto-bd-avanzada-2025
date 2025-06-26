const connectPostgresInstances = require('./postgres');
const connectMySQLInstances = require('./mysql');
const connectRedis = require('./redis');
const connectMongo = require('./mongo');

async function initDatabases() {
  const postgresClients = connectPostgresInstances();
  const mysqlClients = await connectMySQLInstances();
  const redisClient = connectRedis();
  const mongoConnection = await connectMongo();

  return {
    postgres: postgresClients,
    mysql: mysqlClients,
    redis: redisClient,
    mongo: mongoConnection,
  };
}

module.exports = initDatabases;
