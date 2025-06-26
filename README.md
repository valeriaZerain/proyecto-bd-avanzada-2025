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

# Guía rápida para levantar el Backend y conocer sus rutas
¡Hola! Aquí te dejo los pasos para levantar el backend y una explicación sencilla de las rutas que encontrarás en la API.

---

## Requisitos previos
- Tener instalado Node.js (recomendamos versión 16 o superior).
- Docker instalado para levantar las bases de datos con Docker Compose.

---

## Cómo levantar el backend

1. **Instala las dependencias del proyecto**
Abre tu terminal en la carpeta del proyecto y ejecuta:

```bash
npm install
````

2. **Levanta las bases de datos y servicios con Docker Compose**
Ejecuta este comando para iniciar todos los contenedores necesarios (Postgres, MySQL, Redis, Mongo, etc.) usando tu archivo `.env`:

```bash
docker-compose --env-file .env up -d
```

3. **Inicia el servidor**
Finalmente, arranca el backend con:

```bash
npm run start
```

---

## Rutas disponibles en la API
Todas las rutas están bajo el prefijo `/api`.

### 1. `/api/jobs/backup`
- **¿Qué hace?**  
    Permite ejecutar manualmente un job, para crear backups cuando quieras.    

---
### 2. `/api/sale`
- **¿Qué hace?**  
    Obtiene información de ventas desde una de las bases de datos con sharding según la ubicación.
- **Ejemplo de body para solicitar datos de una ubicación:**

```JSON
{
  "location": "location1"
}
```

---

### 3. `/api/books`
- **¿Qué hace?**  
    Permite insertar libros en la base de datos con sharding correspondiente según la ubicación.
- **Ejemplo de body para agregar un libro:**

```JSON
{
  "location": "location1",
  "isbn": 4444,
  "titulo": "Zod en acción",
  "descripcion": "Un gran libro",
  "precio": 150.99,
  "stock": 10,
  "autor_id": 3501,
  "categoria_id": 26,
  "editorial_id": 201,
  "publicado": true
}
```

---

### 4. `/api/cart/:id`
- **¿Qué hace?**  
    Maneja el carrito de compras con caché en Redis para mejorar la velocidad de respuesta.
- **Ejemplo de body para obtener el carrito según ubicación:**

```JSON
{
  "location": "location1"
}
```