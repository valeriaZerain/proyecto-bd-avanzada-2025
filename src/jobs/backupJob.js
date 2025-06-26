const cron = require('cron');
const { exec } = require('child_process');
require('dotenv').config();

function runBackup() {
  console.log('Iniciando backup múltiple...');

  const DBUser = process.env.DB_USER;
  const DBPassword = process.env.DB_PASSWORD;

  const postgresUser = 'postgres';
  const postgresDB = process.env.POSTGRES_DB_SHARD;
  const mysqlDB = process.env.MYSQL_DB_SHARD;

  const postgresContainers = ['postgres_shard1_primary', 'postgres_shard2_primary'];
  const mysqlContainers = ['mysql_shard1_master', 'mysql_shard2_master'];

  const folder = '/tmp';
  const currentDate = new Date();
  const dateStr = currentDate.toISOString().slice(0, 10);

  postgresContainers.forEach((container, index) => {
    const pgFileName = `pg_backup_shard${index + 1}_${dateStr}.dump`;
    const pgBackupCommand = `docker exec -u ${postgresUser} ${container} \
    sh -c "PGPASSWORD='${DBPassword}' pg_dump -U ${DBUser} -F c -d ${postgresDB} -f ${folder}/${pgFileName}"`;
    const pgCopyCommand = `docker cp ${container}:${folder}/${pgFileName} ./backups/${pgFileName}`;

    exec(pgBackupCommand, (err) => {
      if (err) {
        console.error(`[PostgreSQL ${container}] Backup falló: ${err.message}`);
      } else {
        exec(pgCopyCommand, (copyErr) => {
          if (copyErr) {
            console.error(`[PostgreSQL ${container}] Error al copiar: ${copyErr.message}`);
          } else {
            console.log(`[PostgreSQL ${container}] Backup copiado: ${pgFileName}`);
          }
        });
        console.log(`[PostgreSQL ${container}] Backup exitoso`);
      }
    });
  });

  mysqlContainers.forEach((container, index) => {
    const mysqlFileName = `mysql_backup_shard${index + 1}_${dateStr}.sql`;
    const mysqlBackupCommand = `docker exec ${container} \
            sh -c "mysqldump -u ${DBUser} -p${DBPassword} ${mysqlDB} > ${folder}/${mysqlFileName}"`;
    const mysqlCopyCommand = `docker cp ${container}:${folder}/${mysqlFileName} ./backups/${mysqlFileName}`;

    exec(mysqlBackupCommand, (err) => {
      if (err) {
        console.error(`[MySQL ${container}] Backup falló: ${err.message}`);
      } else {
        exec(mysqlCopyCommand, (copyErr) => {
          if (copyErr) {
            console.error(`[MySQL ${container}] Error al copiar: ${copyErr.message}`);
          } else {
            console.log(`[MySQL ${container}] Backup copiado: ${mysqlFileName}`);
          }
        });
        console.log(`[MySQL ${container}] Backup exitoso`);
      }
    });
  });
}


const job = new cron.CronJob('0 3 * * *', runBackup);

module.exports = {
  job,
  runBackup,
};
