import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime
from dotenv import load_dotenv
import os

dotenv_path = os.path.join(os.path.dirname(__file__), '../.env')
load_dotenv(dotenv_path)

# Parámetros de conexión PostgreSQL
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = 'localhost'
DB_PORT = '5432'
DB_NAME = os.getenv("POSTGRES_DB_SHARD")

engine = create_engine(f'postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}')

# Leer CSV
base_path = os.path.dirname(__file__)
usuarios = pd.read_csv(os.path.join(base_path, 'inventario_Usuarios.csv'))
libros = pd.read_csv(os.path.join(base_path, 'inventario_vista_libros_detallada.csv'))
pedidos = pd.read_csv(os.path.join(base_path, 'moduloContable_publi_vw_pedidos_completos.csv'))
libros = libros.rename(columns={'isbn': 'id_libro'})
# ---------------------------
# DIMENSION_USUARIO
# ---------------------------
dim_usuario = usuarios[['id', 'nombre', 'apellido']].drop_duplicates()
dim_usuario.columns = ['id', 'nombre', 'apellido']

# ---------------------------
# DIMENSION_METODOPAGO
# ---------------------------
dim_metodo = pedidos[['tipo']].drop_duplicates().reset_index(drop=True)
dim_metodo['id'] = dim_metodo.index + 1
dim_metodo.columns = ['tipo', 'id']

# ---------------------------
# DIMENSION_TIEMPO
# ---------------------------
pedidos['fecha_venta'] = pd.to_datetime(pedidos['fecha_pedido'])
dim_tiempo = pedidos[['fecha_venta']].drop_duplicates().copy()
dim_tiempo['día'] = dim_tiempo['fecha_venta'].dt.day
dim_tiempo['mes'] = dim_tiempo['fecha_venta'].dt.month
dim_tiempo['año'] = dim_tiempo['fecha_venta'].dt.year
dim_tiempo['id'] = dim_tiempo.reset_index().index + 1
dim_tiempo['fecha'] = dim_tiempo['fecha_venta']

# ---------------------------
# DIMENSION_AUTOR
# ---------------------------
dim_autor = libros[['autor']].drop_duplicates().reset_index(drop=True)
dim_autor['id'] = dim_autor.index + 1

# ---------------------------
# DIMENSION_EDITORIAL
# ---------------------------
dim_editorial = libros[['editorial']].drop_duplicates().reset_index(drop=True)
dim_editorial['id'] = dim_editorial.index + 1

# ---------------------------
# DIMENSION_CATEGORIA
# ---------------------------
dim_categoria = libros[['categoria']].drop_duplicates().reset_index(drop=True)
dim_categoria['id'] = dim_categoria.index + 1
dim_categoria.columns = ['tipo_categoria', 'id']

# ---------------------------
# DIMENSION_LIBRO
# ---------------------------
libros = libros.merge(dim_autor, on='autor')
libros = libros.merge(dim_editorial, on='editorial')
libros = libros.merge(dim_categoria, left_on='categoria', right_on='tipo_categoria')
libros = libros.rename(columns={
    'id_x': 'id_autor',
    'id_y': 'id_editorial',
    'id': 'id_categoria'
})
dim_libro = libros[['id_libro', 'titulo', 'id_categoria', 'id_editorial', 'id_autor']]

# ---------------------------
# HECHOS_VENTAS
# ---------------------------
pedidos = pedidos.merge(dim_metodo, left_on='tipo', right_on='tipo')
pedidos = pedidos.merge(dim_tiempo[['id', 'fecha_venta']], on='fecha_venta')

# Renombramos columnas para que coincidan con el esquema de hechos
pedidos = pedidos.rename(columns={
    'libro_isbn': 'id_libro',
    'usuario_id': 'id_cliente',
    'pedido_id': 'id_pedido',
    'total': 'total_pagado',
    'id_x': 'id_métodopago', 
    'id_y': 'id de tiempo'
})
pedidos['id_venta'] = range(1, len(pedidos) + 1)

hechos_ventas = pedidos[[
    'id_venta', 'id_libro', 'id_cliente', 'id_métodopago', 'id_pedido',
    'cantidad', 'precio_unitario', 'total_pagado', 'fecha_venta', 'cupon_codigo'
]]

# ---------------------------
# SUBIR A POSTGRESQL
# ---------------------------
dim_usuario.to_sql('dimension_usuario', engine, if_exists='replace', index=False)
dim_metodo.to_sql('dimension_metodopago', engine, if_exists='replace', index=False)
dim_tiempo.to_sql('dimension_tiempo', engine, if_exists='replace', index=False)
dim_autor.to_sql('dimension_autor', engine, if_exists='replace', index=False)
dim_editorial.to_sql('dimension_editorial', engine, if_exists='replace', index=False)
dim_categoria.to_sql('dimension_categoria', engine, if_exists='replace', index=False)
dim_libro.to_sql('dimension_libro', engine, if_exists='replace', index=False)
hechos_ventas.to_sql('hechos_ventas', engine, if_exists='replace', index=False)

print("¡Datos cargados exitosamente en PostgreSQL!")