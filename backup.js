const cron = require('cron');
const { exec } = require('child_process');
require('dotenv').config()

const job = new cron.CronJob(
    '0 3 */1 * *', 
	function () {
		console.log('You will backup every day at 3:00 AM');

        const postgresUser = 'postgres';
        const postgresContainer = 'clientes-postgres';
        const mysqlContainer = 'inventario-mysql';

        const DBUser = process.env.DB_USER;
        const DBPassword = process.env.DB_PASSWORD;
        const postgresDB = 'clientes';
        const mysqlDB = 'inventario';

        const folder = '/tmp';
        const currentDate = new Date();
        const dateStr = currentDate.toISOString().slice(0, 10);


        const pgFileName = `pg_backup_${dateStr}.dump`;
        const pgBackupCommand = `docker exec -u ${postgresUser} ${postgresContainer} \
            pg_dump -U ${DBUser} -F c -d ${postgresDB} -f ${folder}/${pgFileName}`;
        const pgCopyCommand = `docker cp ${postgresContainer}:${folder}/${pgFileName} ./backups/${pgFileName}`;

        const mysqlFileName = `mysql_backup_${dateStr}.sql`;
        const mysqlBackupCommand = `docker exec ${mysqlContainer} \
            sh -c "mysqldump -u ${DBUser} -p${DBPassword} ${mysqlDB} > ${folder}/${mysqlFileName}"`;
        const mysqlCopyCommand = `docker cp ${mysqlContainer}:${folder}/${mysqlFileName} ./backups/${mysqlFileName}`;

        exec(pgBackupCommand, (pgErr, pgStdout, pgStderr) => {
            if (pgErr) {
                console.error(`PostgreSQL backup failed: ${pgErr.message}`);
            } else {
                exec(pgCopyCommand, (pgCopyErr, pgCopyOut) => {
                    if (pgCopyErr) {
                        console.error(`Error copying PostgreSQL file: ${pgCopyErr.message}`);
                    } else {
                        console.log(`PostgreSQL backup copied: ${pgFileName}`);
                    }
                });
                console.log(`PostgreSQL backup successful`);
            }
        });

        exec(mysqlBackupCommand, (myErr, myStdout, myStderr) => {
            if (myErr) {
                console.error(`MySQL backup failed: ${myErr.message}`);
            } else {
                exec(mysqlCopyCommand, (myCopyErr, myCopyOut) => {
                    if (myCopyErr) {
                        console.error(`Error copying MySQL file: ${myCopyErr.message}`);
                    } else {
                        console.log(`MySQL backup copied: ${mysqlFileName}`);
                    }
                });
                console.log(`MySQL backup successful`);
            }
        });
    },
    true,
);

job.start();
console.log('Cron job started. It will backup every day at 3:00am.');