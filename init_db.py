import os
import random
from faker import Faker
import mysql.connector
import psycopg2
from dotenv import load_dotenv
from datetime import datetime, timedelta

# Configuraciones
NUM_USUARIOS = 500
NUM_AUTORES = 700
NUM_EDITORIALES = 40
NUM_LIBROS = 1500
NUM_FAVORITOS = 600
NUM_REFERIDOS = 200
NUM_CUPONES = 100
NUM_PEDIDOS = 30000
NUM_CARRITOS = 700
METODOS_PAGO = ["Tarjeta", "Paypal", "Qr", "Crypto"]
NUM_DIRECCIONES = 500
NUM_LOGS_PEDIDOS = 1000
CATEGORIAS_MANUALES = ["Ficción", "Tecnología", "Historia", "Ciencia", "Autoayuda"]

fake = Faker("es_ES")
load_dotenv()
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
POSTGRES_DB_SHARD = os.getenv("POSTGRES_DB_SHARD")
MYSQL_DB_SHARD = os.getenv("MYSQL_DB_SHARD")

# Conexiones MySQL Sharding
mysql1 = mysql.connector.connect(
  host="localhost",
  port=3306,
  user=DB_USER,
  password=DB_PASSWORD,
  database=MYSQL_DB_SHARD
)
mysql2 = mysql.connector.connect(
  host="localhost",
  port=3309,
  user=DB_USER,
  password=DB_PASSWORD,
  database=MYSQL_DB_SHARD
)

# Conexiones PostgreSQL Sharding
pg1 = psycopg2.connect(
  host="localhost",
  port=5432,
  user=DB_USER,
  password=DB_PASSWORD,
  dbname=POSTGRES_DB_SHARD
)
pg2 = psycopg2.connect(
  host="localhost",
  port=5435,
  user=DB_USER,
  password=DB_PASSWORD,
  dbname=POSTGRES_DB_SHARD
)

mysql1_cur = mysql1.cursor()
mysql2_cur = mysql2.cursor()
pg1_cur = pg1.cursor()
pg2_cur = pg2.cursor()

usuarios = []
autores = []
categorias = []
editoriales = []
libros_shard1 = []
libros_shard2 = []
libros_compartidos = []

isbn_counter = 1000000000
isbn_libros = {}

def distribuir_libros():
    total = list(range(NUM_LIBROS))
    random.shuffle(total)
    num_45 = int(NUM_LIBROS * 0.45)
    num_10 = NUM_LIBROS - (2 * num_45)
    return total[:num_45], total[num_45:num_45*2], total[-num_10:]

libros1_idx, libros2_idx, libros_both_idx = distribuir_libros()
usuarios_postgres1 = set(random.sample(range(NUM_USUARIOS), NUM_USUARIOS // 2))
usuarios_postgres2 = set(range(NUM_USUARIOS)) - usuarios_postgres1

def insertar_datos_mysql():
    global autores, categorias_ids, editoriales, isbn_counter

    for i in range(NUM_USUARIOS):
        nombre, apellido, email, password = fake.first_name(), fake.last_name(), fake.email(), fake.password()
        for cur in [mysql1_cur, mysql2_cur]:
            cur.execute("INSERT INTO Usuarios (nombre, apellido, email, password) VALUES (%s, %s, %s, %s)", (nombre, apellido, email, password))
        usuarios.append(i + 1)

    autores = []
    autores_shard2 = []
    for _ in range(NUM_AUTORES):
        nombre, nacionalidad = fake.name(), fake.country()
        mysql1_cur.execute("INSERT INTO Autores (nombre, nacionalidad) VALUES (%s, %s)", (nombre, nacionalidad))
        id1 = mysql1_cur.lastrowid
        mysql2_cur.execute("INSERT INTO Autores (nombre, nacionalidad) VALUES (%s, %s)", (nombre, nacionalidad))
        id2 = mysql2_cur.lastrowid
        autores.append(id1)
        autores_shard2.append(id2)

    categorias_ids = []
    for cat in CATEGORIAS_MANUALES:
        mysql1_cur.execute("INSERT INTO Categorias (categoria) VALUES (%s)", (cat,))
        id1 = mysql1_cur.lastrowid
        mysql2_cur.execute("INSERT INTO Categorias (categoria) VALUES (%s)", (cat,))
        id2 = mysql2_cur.lastrowid
        categorias_ids.append((id1, id2))

    editoriales = []
    editoriales_shard2 = []
    for _ in range(NUM_EDITORIALES):
        editorial, pais = fake.company(), fake.country()
        mysql1_cur.execute("INSERT INTO Editoriales (editorial, pais) VALUES (%s, %s)", (editorial, pais))
        id1 = mysql1_cur.lastrowid
        mysql2_cur.execute("INSERT INTO Editoriales (editorial, pais) VALUES (%s, %s)", (editorial, pais))
        id2 = mysql2_cur.lastrowid
        editoriales.append(id1)
        editoriales_shard2.append(id2)

    for idx in range(NUM_LIBROS):
        isbn = isbn_counter
        isbn_counter += 1
        isbn_libros[idx] = isbn
        titulo = fake.sentence(nb_words=5)
        descripcion = fake.text(max_nb_chars=200)
        precio = round(random.uniform(10, 100), 2)
        stock = random.randint(1, 50)
        cat_idx = random.randint(0, len(categorias_ids) - 1)
        editorial_idx = random.randint(0, len(editoriales) - 1)

        if idx in libros1_idx:
            autor_id = autores[random.randint(0, len(autores) - 1)]
            mysql1_cur.execute("""
                INSERT INTO Libros (isbn, titulo, descripcion, precio, stock, autor_id, categoria_id, editorial_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (isbn, titulo, descripcion, precio, stock, autor_id, categorias_ids[cat_idx][0], editoriales[editorial_idx]))
            libros_shard1.append(isbn)

        elif idx in libros2_idx:
            autor_id = autores_shard2[random.randint(0, len(autores_shard2) - 1)]
            mysql2_cur.execute("""
                INSERT INTO Libros (isbn, titulo, descripcion, precio, stock, autor_id, categoria_id, editorial_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (isbn, titulo, descripcion, precio, stock, autor_id, categorias_ids[cat_idx][1], editoriales_shard2[editorial_idx]))
            libros_shard2.append(isbn)

        else:
            autor_idx = random.randint(0, len(autores) - 1)
            autor_id1 = autores[autor_idx]
            autor_id2 = autores_shard2[autor_idx]
            mysql1_cur.execute("""
                INSERT INTO Libros (isbn, titulo, descripcion, precio, stock, autor_id, categoria_id, editorial_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (isbn, titulo, descripcion, precio, stock, autor_id1, categorias_ids[cat_idx][0], editoriales[editorial_idx]))
            mysql2_cur.execute("""
                INSERT INTO Libros (isbn, titulo, descripcion, precio, stock, autor_id, categoria_id, editorial_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (isbn, titulo, descripcion, precio, stock, autor_id2, categorias_ids[cat_idx][1], editoriales_shard2[editorial_idx]))
            libros_compartidos.append((isbn, isbn))

    mysql1.commit()
    mysql2.commit()

def fechas_ordenadas(base_date, total, anios=3):
    fechas = []
    for i in range(total):
        offset_dias = int((i / total) * (anios * 365))
        fecha = base_date + timedelta(days=offset_dias)
        fechas.append(fecha)
    return fechas

def insertar_datos_postgres():
    base_fecha = datetime.now() - timedelta(days=3*365)
    fechas_pedidos = fechas_ordenadas(base_fecha, NUM_PEDIDOS)
    fechas_carritos = fechas_ordenadas(base_fecha, NUM_CARRITOS)
    fechas_logs = fechas_ordenadas(base_fecha, NUM_LOGS_PEDIDOS)
    pedidos_pg1 = []
    pedidos_pg2 = []
    idx_carrito, idx_pedido, idx_log = 0, 0, 0

    for cur in [pg1_cur, pg2_cur]:
        for _ in range(NUM_CUPONES // 2):
            cur.execute("INSERT INTO Cupones (codigo, descuento_porcentaje, fecha_expiracion, max_uso) VALUES (%s, %s, %s, %s)",
                        (fake.lexify('CUPON-?????'), random.randint(5, 50), fake.date_between('today', '+30d'), random.randint(5, 100)))
        for metodo in METODOS_PAGO:
            cur.execute("INSERT INTO MetodosPago (tipo, descripcion) VALUES (%s, %s)", (metodo, fake.text(max_nb_chars=50)))

    for i in range(NUM_CARRITOS):
        uid = random.randint(1, NUM_USUARIOS)
        cur = pg1_cur if uid - 1 in usuarios_postgres1 else pg2_cur
        fecha = fechas_carritos[idx_carrito]; idx_carrito += 1
        cur.execute("INSERT INTO Carritos (usuario_id, fecha_creacion) VALUES (%s, %s) RETURNING id", (uid, fecha))
        carrito_id = cur.fetchone()[0]
        for _ in range(random.randint(1, 4)):
            libro = random.choice(list(isbn_libros.values()))
            cur.execute("INSERT INTO CarritoItems (carrito_id, libro_isbn, cantidad) VALUES (%s, %s, %s)", (carrito_id, libro, random.randint(1, 3)))

    for i in range(NUM_PEDIDOS):
        uid = random.randint(1, NUM_USUARIOS)
        cur = pg1_cur if uid - 1 in usuarios_postgres1 else pg2_cur
        cur.execute("SELECT id FROM MetodosPago ORDER BY RANDOM() LIMIT 1")
        metodo_id = cur.fetchone()[0]
        cur.execute("SELECT id FROM Cupones ORDER BY RANDOM() LIMIT 1")
        cupon_id = cur.fetchone()[0] if random.random() < 0.3 else None
        estado = random.choice(['pendiente', 'enviado', 'entregado'])
        total = round(random.uniform(20, 500), 2)
        fecha = fechas_pedidos[idx_pedido]; idx_pedido += 1
        cur.execute("INSERT INTO Pedidos (usuario_id, fecha_pedido, estado, total, metodo_id, cupon_id) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id", (uid, fecha, estado, total, metodo_id, cupon_id))
        pedido_id = cur.fetchone()[0]
        if cur == pg1_cur:
            pedidos_pg1.append(pedido_id)
        else:
            pedidos_pg2.append(pedido_id)
        for _ in range(random.randint(1, 3)):
            libro = random.choice(list(isbn_libros.values()))
            cur.execute("INSERT INTO DetallesPedido (pedido_id, libro_isbn, cantidad, precio_unitario) VALUES (%s, %s, %s, %s)", (pedido_id, libro, random.randint(1, 2), round(random.uniform(10, 100), 2)))

    for i in range(NUM_DIRECCIONES):
        uid = random.randint(1, NUM_USUARIOS)
        cur = pg1_cur if uid - 1 in usuarios_postgres1 else pg2_cur
        cur.execute("INSERT INTO Direcciones (usuario_id, direccion, ciudad, departamento, pais, codigo_postal) VALUES (%s, %s, %s, %s, %s, %s)", (uid, fake.address(), fake.city(), fake.state(), fake.country(), fake.postcode()))

    for _ in range(NUM_LOGS_PEDIDOS):
        cur = pg1_cur if random.random() < 0.5 else pg2_cur
        pedido_list = pedidos_pg1 if cur == pg1_cur else pedidos_pg2
        if pedido_list:
            pedido_id = random.choice(pedido_list)
            fecha = fechas_logs[idx_log]; idx_log += 1
            cur.execute("INSERT INTO LogsPedidos (pedido_id, accion, descripcion, fecha) VALUES (%s, %s, %s, %s)", (pedido_id, random.choice(["Creado", "Pagado", "Cancelado", "Enviado"]), fake.sentence(), fecha))

    pg1.commit()
    pg2.commit()

def vaciar_mysql():
    for cur in [mysql1_cur, mysql2_cur]:
        cur.execute("SET FOREIGN_KEY_CHECKS = 0")
        for tabla in ["Favoritos", "Referidos", "Libros", "Autores", "Editoriales", "Categorias", "Usuarios"]:
            cur.execute(f"DELETE FROM {tabla}")
        cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    mysql1.commit()
    mysql2.commit()

def vaciar_postgres():
    for cur in [pg1_cur, pg2_cur]:
        cur.execute("""
            TRUNCATE TABLE DetallesPedido CASCADE;
            TRUNCATE TABLE Pedidos CASCADE;
            TRUNCATE TABLE CarritoItems CASCADE;
            TRUNCATE TABLE Carritos CASCADE;
            TRUNCATE TABLE Direcciones CASCADE;
            TRUNCATE TABLE Cupones CASCADE;
            TRUNCATE TABLE MetodosPago CASCADE;
            TRUNCATE TABLE LogsPedidos CASCADE;
        """)
    pg1.commit()
    pg2.commit()

if __name__ == "__main__":
    print("Vaciando bases de datos...")
    vaciar_mysql()
    vaciar_postgres()
    print("Insertando en MySQL...")
    insertar_datos_mysql()
    print("Insertando en PostgreSQL...")
    insertar_datos_postgres()
    print("Finalizado.")

    for cur in [mysql1_cur, mysql2_cur, pg1_cur, pg2_cur]:
        cur.close()
    for conn in [mysql1, mysql2, pg1, pg2]:
        conn.close()
