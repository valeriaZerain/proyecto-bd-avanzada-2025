require('dotenv').config();
const app = require('./app');
const { job } = require('./jobs/backupJob');
const initDatabases = require('./db/index');

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    const dbConnections = await initDatabases();

    app.locals.dbs = dbConnections;

    app.listen(PORT, () => {
      console.log(`Servidor ejecutandoce en http://localhost:${PORT}/api`);
    });

    job.start();
    console.log('Cron job iniciado');

  } catch (err) {
    console.error('Error al iniciar el servidor o bases de datos:', err);
    process.exit(1);
  }
}

startServer();