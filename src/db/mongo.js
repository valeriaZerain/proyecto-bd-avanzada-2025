const mongoose = require('mongoose');

async function connectMongo() {
  const user = process.env.DB_USER;
  const password = process.env.DB_PASSWORD;

  const uri = `mongodb://${user}:${password}@localhost:27017/?authSource=admin`;

  await mongoose.connect(uri);
  return mongoose.connection;
}

module.exports = connectMongo;
