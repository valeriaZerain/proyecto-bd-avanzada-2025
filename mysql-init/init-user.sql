ALTER USER 'root'@'%' IDENTIFIED WITH 'mysql_native_password' BY '${DB_PASSWORD}';
ALTER USER '${DB_USER}'@'%' IDENTIFIED WITH 'mysql_native_password' BY '${DB_PASSWORD}';