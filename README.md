## Ejecutar la base de datos
1. Crear un archivo .env en la raiz de la carpeta con los siguientes datos

```
DB_USER=user
DB_PASSWORD=password
```

2. Abrir Git Bash o PowerShell dentro del proyecto
3. Ejecutar el siguiente comando:

```shell
docker-compose --env-file .env up -d
```
4. Abrir un SGBD y Realizar la Conexión con las bases de datos.
5. ejecutar `mysql.sql` en la base de datos *MySQL* para crear las tablas (Primera Vez)
6. ejecutar `postgresql.sql` en la base de datos *PostgreSQL* para crear las tablas (Primera Vez)
7. Instalar dependencias de python (Primera vez)

```shell
pip install -r requirements.txt
```

8. ejecutar init_db.py (Primera Vez)

```shell
python .\init_db.py  
```

>[!NOTE]
>Este proceso puede tardar un tiempo.