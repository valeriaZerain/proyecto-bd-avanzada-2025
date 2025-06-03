import os
import random
from faker import Faker
import mysql.connector
import psycopg2
from dotenv import load_dotenv
from datetime import datetime, timedelta

# Configuraciones de cantidad
NUM_USUARIOS = 500
NUM_AUTORES = 700
NUM_EDITORIALES = 40
NUM_LIBROS = 1500
NUM_FAVORITOS = 600
NUM_REFERIDOS = 200
NUM_CUPONES = 100
NUM_PEDIDOS = 30000
NUM_CARRITOS = 700
METODOS_PAGO = ["Tarjeta","Paypal","Qr","Crypto"]
NUM_DIRECCIONES = 500
NUM_LOGS_PEDIDOS = 1000
CATEGORIAS_MANUALES = ["Ficción", "Tecnología", "Historia", "Ciencia", "Autoayuda"]



# Inicializar Faker en español
fake = Faker("es_ES")

# Cargar variables de entorno
load_dotenv()
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

# Conexión a MySQL
mysql_conn = mysql.connector.connect(
    host="localhost",
    port=3306,
    user=DB_USER,
    password=DB_PASSWORD,
    database="inventario"
)
mysql_cursor = mysql_conn.cursor()

# Conexión a PostgreSQL
pg_conn = psycopg2.connect(
    host="localhost",
    port=5432,
    user=DB_USER,
    password=DB_PASSWORD,
    dbname="clientes"
)
pg_cursor = pg_conn.cursor()

usuarios_ids = []
autores_ids = []
categorias_ids = []
editoriales_ids = []
libros_isbn = []

def insertar_mysql():
    global usuarios_ids, autores_ids, categorias_ids, editoriales_ids, libros_isbn

    for _ in range(NUM_USUARIOS):
        mysql_cursor.execute("""
            INSERT INTO Usuarios (nombre, apellido, email, password)
            VALUES (%s, %s, %s, %s)
        """, (fake.first_name(), fake.last_name(), fake.email(), fake.password()))
        usuarios_ids.append(mysql_cursor.lastrowid)

    for _ in range(NUM_AUTORES):
        mysql_cursor.execute("""
            INSERT INTO Autores (nombre, nacionalidad)
            VALUES (%s, %s)
        """, (fake.name(), fake.country()))
        autores_ids.append(mysql_cursor.lastrowid)

    for categoria in CATEGORIAS_MANUALES:
        mysql_cursor.execute("INSERT INTO Categorias (categoria) VALUES (%s)", (categoria,))
        categorias_ids.append(mysql_cursor.lastrowid)

    for _ in range(NUM_EDITORIALES):
        mysql_cursor.execute("""
            INSERT INTO Editoriales (editorial, pais)
            VALUES (%s, %s)
        """, (fake.company(), fake.country()))
        editoriales_ids.append(mysql_cursor.lastrowid)

    for _ in range(NUM_LIBROS):
        autor_id = random.choice(autores_ids)
        categoria_id = random.choice(categorias_ids)
        editorial_id = random.choice(editoriales_ids)
        mysql_cursor.execute("""
            INSERT INTO Libros (titulo, descripcion, precio, stock, autor_id, categoria_id, editorial_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            fake.sentence(nb_words=5),
            fake.text(max_nb_chars=200),
            round(random.uniform(10, 100), 2),
            random.randint(1, 50),
            autor_id, categoria_id, editorial_id
        ))
        libros_isbn.append(mysql_cursor.lastrowid)

    for _ in range(NUM_FAVORITOS):
        mysql_cursor.execute(
            "INSERT INTO Favoritos (usuario_id, libro_id) VALUES (%s, %s)",
            (random.choice(usuarios_ids), random.choice(libros_isbn))
        )

    for _ in range(NUM_REFERIDOS):
        cliente_id, referido_id = random.sample(usuarios_ids, 2)
        mysql_cursor.execute(
            "INSERT INTO Referidos (cliente_id, referido_id) VALUES (%s, %s)",
            (cliente_id, referido_id)
        )
    
    mysql_conn.commit()

def vaciar_mysql():
    mysql_cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    mysql_cursor.execute("DELETE FROM Favoritos")
    mysql_cursor.execute("DELETE FROM Referidos")
    mysql_cursor.execute("DELETE FROM Libros")
    mysql_cursor.execute("DELETE FROM Autores")
    mysql_cursor.execute("DELETE FROM Editoriales")
    mysql_cursor.execute("DELETE FROM Categorias")
    mysql_cursor.execute("DELETE FROM Usuarios")
    mysql_cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    mysql_conn.commit()

def insertar_postgres():
    for _ in range(NUM_CUPONES):
        pg_cursor.execute("""
            INSERT INTO Cupones (codigo, descuento_porcentaje, fecha_expiracion, max_uso)
            VALUES (%s, %s, %s, %s)
        """, (
            fake.lexify(text='CUPON-?????'),
            random.randint(5, 50),
            fake.date_between(start_date='today', end_date='+30d'),
            random.randint(5, 100)
        ))

    for _ in range(NUM_CARRITOS):
        usuario_id = random.choice(usuarios_ids)
        pg_cursor.execute("INSERT INTO Carritos (usuario_id) VALUES (%s) RETURNING id", (usuario_id,))
        carrito_id = pg_cursor.fetchone()[0]
        for _ in range(random.randint(1, 4)):
            libro_id = random.choice(libros_isbn)
            pg_cursor.execute("""
                INSERT INTO CarritoItems (carrito_id, libro_isbn, cantidad)
                VALUES (%s, %s, %s)
            """, (carrito_id, libro_id, random.randint(1, 3)))

    for _ in range(NUM_PEDIDOS):
        usuario_id = random.choice(usuarios_ids)
        estado = random.choice(['pendiente', 'enviado', 'entregado'])
        total = round(random.uniform(20, 500), 2)
        pg_cursor.execute("""
            INSERT INTO Pedidos (usuario_id, estado, total)
            VALUES (%s, %s, %s)
            RETURNING id
        """, (usuario_id, estado, total))
        pedido_id = pg_cursor.fetchone()[0]

        for _ in range(random.randint(1, 3)):
            libro_id = random.choice(libros_isbn)
            pg_cursor.execute("""
                INSERT INTO DetallesPedido (pedido_id, libro_isbn, cantidad, precio_unitario)
                VALUES (%s, %s, %s, %s)
            """, (pedido_id, libro_id, random.randint(1, 2), round(random.uniform(10, 100), 2)))

    for metodo in METODOS_PAGO:
        pg_cursor.execute("""
            INSERT INTO MetodosPago (tipo, descripcion)
            VALUES (%s, %s)
        """, (metodo, fake.text(max_nb_chars=50)))

    for _ in range(NUM_DIRECCIONES):
        usuario_id = random.choice(usuarios_ids)
        pg_cursor.execute("""
            INSERT INTO Direcciones (usuario_id, direccion, ciudad, departamento, pais, codigo_postal)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            usuario_id,
            fake.address(), fake.city(), fake.state(), fake.country(), fake.postcode()
        ))

    for _ in range(NUM_LOGS_PEDIDOS):
        pg_cursor.execute("SELECT id FROM Pedidos ORDER BY RANDOM() LIMIT 1")
        pedido = pg_cursor.fetchone()
        if pedido:
            pedido_id = pedido[0]
            pg_cursor.execute("""
                INSERT INTO LogsPedidos (pedido_id, accion, descripcion)
                VALUES (%s, %s, %s)
            """, (
                pedido_id,
                random.choice(["Creado", "Pagado", "Cancelado", "Enviado"]),
                fake.sentence()
            ))

    pg_conn.commit()
    
def vaciar_postgres():
    pg_cursor.execute("TRUNCATE TABLE LogsPedidos CASCADE")
    pg_cursor.execute("TRUNCATE TABLE DetallesPedido CASCADE")
    pg_cursor.execute("TRUNCATE TABLE Pedidos CASCADE")
    pg_cursor.execute("TRUNCATE TABLE CarritoItems CASCADE")
    pg_cursor.execute("TRUNCATE TABLE Carritos CASCADE")
    pg_cursor.execute("TRUNCATE TABLE Direcciones CASCADE")
    pg_cursor.execute("TRUNCATE TABLE Cupones CASCADE")
    pg_cursor.execute("TRUNCATE TABLE MetodosPago CASCADE")
    
if __name__ == "__main__":
    print("Reiniciando MySQL... ")
    vaciar_mysql()
    print("Reiniciando PostgreSQL")
    vaciar_postgres()
    print("Insertando en MySQL...")
    insertar_mysql()
    print("Insertando en PostgreSQL...")
    insertar_postgres()
    print("Proceso finalizado.")

    mysql_cursor.close()
    mysql_conn.close()
    pg_cursor.close()
    pg_conn.close()
