-- Crear el rol contable con herencia (acceso automático a permisos)
-- Solo tiene permiso de Lectura (POSTGRES)
CREATE ROLE contable INHERIT;
GRANT SELECT ON
    Pedidos,
    DetallesPedido,
    MetodosPago,
    Cupones,
    LogsPedidos
TO contable;

-- PostgreSQL
CREATE USER contable_user WITH PASSWORD 'clave_contable_2025';
GRANT contable TO contable_user;
-- Este usuario tendrá automáticamente permisos de solo lectura sobre tablas contables.


-- Crear el rol administrador con herencia
-- Puede Administrar temas contables, pero no carritos (POSTGRES)
CREATE ROLE admin_operaciones INHERIT;
GRANT SELECT, INSERT, UPDATE, DELETE ON
    Cupones,
    Pedidos,
    DetallesPedido,
    MetodosPago,
    LogsPedidos
TO admin_operaciones;

-- PostgreSQL
CREATE USER admin_ops WITH PASSWORD 'clave_admin_2025';
GRANT admin_operaciones TO admin_ops;
-- Este usuario puede crear, modificar y eliminar registros en las tablas asignadas.


-- Crear el rol de usuario base
-- le da permisos de solo lectura a los productos
CREATE ROLE 'user';
GRANT SELECT ON tu_base_de_datos.Libros TO 'user';
GRANT SELECT ON tu_base_de_datos.Autores TO 'user';
GRANT SELECT ON tu_base_de_datos.Categorias TO 'user';
GRANT SELECT ON tu_base_de_datos.Editoriales TO 'user';

-- MySQL
CREATE USER 'cliente_user'@'%' IDENTIFIED BY 'clave_cliente_2025';

-- Asignar el rol previamente creado
GRANT 'user' TO 'cliente_user';

-- Establecer el rol por defecto para que no tenga que activarlo manualmente
SET DEFAULT ROLE 'user' TO 'cliente_user';
