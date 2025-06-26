const Redis = require('ioredis');

function connectRedis() {
  const redis = new Redis({
    host: 'localhost',
    port: 6379,
    password: 'password123',
  });

  return redis;
}

module.exports = connectRedis;
