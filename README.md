# Guía de Inicialización de la Base de Datos

Esta guía describe, en cuatro fases claras y amigables, los pasos necesarios para ejecutar por primera vez tu arquitectura de bases de datos con replicación MySQL. Sigue cada sección en orden para asegurar una instalación exitosa.

---

## 1. Creación de Contenedores

En esta fase levantarás los contenedores Docker que alojarán tus instancias de MySQL.

1. **Definir variables de entorno**
   - Crea un archivo `.env` en la raíz de tu proyecto.
   - Agrega las siguientes variables (ajusta según tu configuración):
 ```env
DB_USER=admin
DB_PASSWORD=pass123

# PostgreSQL
POSTGRES_DB_SHARD=modContable

# MySQL
MYSQL_DB_SHARD=modUsuarioStock
 ```

2. **Levantar los contenedores**
   - Abre una terminal en la carpeta donde tienes tu `docker-compose.yml`.
   - Ejecuta:
 ```bash
docker-compose --env-file .env up -d
 ```

---

## 2. Configuración de Replicación

En esta etapa prepararás los maestros y esclavos para que puedan sincronizar datos.
> [!NOTE]
> La notación `${}` indica un dato el cual debe

1. **Crear usuarios de replicación**
   - Conéctate al contenedor maestro:
 ```bash
 docker exec ${contenedor} mysql -uroot -p${DB_PASSWORD} -e "
     CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'replpass';
     GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
     FLUSH PRIVILEGES;
   "
 ```

2. **Obtener estado del binlog**
   - En el maestro, obtén el archivo y la posición actuales:
 ```bash
docker exec -it ${contenedor_master} mysql -uroot -p${env_DB_PASSWORD} -e "SHOW BINARY LOG STATUS;"
 ```
   - Anota el valor de `File` y `Position`.

3. **Configurar los esclavos**
   - Conéctate al contenedor esclavo:
 ```bash
docker exec ${contenedor_slave} mysql -uroot -p${env_DB_PASSWORD} -e "
  CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='${contenedor_master}',
    SOURCE_PORT=3306,
    SOURCE_USER='repl',
    SOURCE_PASSWORD='replpass',
    SOURCE_LOG_FILE='${File}',
    SOURCE_LOG_POS=${Position},
    GET_SOURCE_PUBLIC_KEY=1;
  START REPLICA;
  SHOW REPLICA STATUS\G
"
 ```
   - Verifica el estado donde debe mostrar las siguientes características:
```
Replica_IO_Running: Yes
Replica_SQL_Running: Yes
 ```
 
   > [!IMPORTANT] 
   > Realizar los pasos para ambas replicaciones de _MySQL_, tanto maestros y sus correspondientes esclavos

---

## 3. Inicialización de Tablas

Ahora que los contenedores están activos y replicándose, crea las estructuras de datos.

1. **Conéctate con tu cliente favorito**
   - Abre DBeaver, DataGrip o tu SGBD preferido.
   - Conecta a los endpoints definidos en el archivo `docker-compose.yml`.

2. **Ejecuta los scripts SQL**
   - Importa o ejecuta los archivos `mysql.sql`, `postgresql.sql`, etc.
   - Asegúrate de que cada script termine sin errores.

---

## 4. Inicialización de Datos

Con las tablas listas, carga datos de prueba o iniciales.

1. **Instalar dependencias de Python**
   - Instala los paquetes necesarios:
 ```bash
 pip install -r requirements.txt
 ```

2. **Ejecutar el inicializador**
   - Lanza el script `init_db.py` para poblar las tablas:
 ```bash
 python init_db.py
 ```
   - Verifica en tu SGBD que los registros se hayan insertado correctamente.
