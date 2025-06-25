-- Cupones
DROP TABLE IF EXISTS Cupones CASCADE;
CREATE TABLE Cupones (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE,
    descuento_porcentaje INT CHECK (descuento_porcentaje BETWEEN 1 AND 100),
    fecha_expiracion DATE,
    max_uso INT,
    usos_actuales INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE
);
-- Carritos
DROP TABLE IF EXISTS Carritos CASCADE;
CREATE TABLE Carritos (
    id SERIAL PRIMARY KEY,
    usuario_id INT, --este se simulara
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CarritoItems
DROP TABLE IF EXISTS CarritoItems CASCADE;
CREATE TABLE CarritoItems (
    id SERIAL PRIMARY KEY,
    carrito_id INT,
    libro_isbn INT, --este dato se simulara
    cantidad INT,
    FOREIGN KEY (carrito_id) REFERENCES Carritos(id)
);

-- Métodos de pago
DROP TABLE IF EXISTS MetodosPago CASCADE;
CREATE TABLE MetodosPago (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(50),
    descripcion VARCHAR(100)
);

-- Pedidos
DROP TABLE IF EXISTS Pedidos CASCADE;
CREATE TABLE Pedidos (
    id SERIAL PRIMARY KEY,
    usuario_id INT, --este dato se simulara
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20),
    total DECIMAL(10,2),
    cupon_id INT,
    metodo_id INT,
    FOREIGN KEY (cupon_id) REFERENCES Cupones(id),
    FOREIGN KEY (metodo_id) REFERENCES MetodosPago(id)
);

-- Detalles del pedido
DROP TABLE IF EXISTS DetallesPedido CASCADE;
CREATE TABLE DetallesPedido (
    id SERIAL PRIMARY KEY,
    pedido_id INT,
    libro_isbn INT,
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    FOREIGN KEY (pedido_id) REFERENCES Pedidos(id)
);

-- Direcciones
DROP TABLE IF EXISTS Direcciones CASCADE;
CREATE TABLE Direcciones (
    id SERIAL PRIMARY KEY,
    usuario_id INT, --este dato se simulara
    direccion TEXT,
    ciudad VARCHAR(100),
    departamento VARCHAR(100),
    pais VARCHAR(100),
    codigo_postal VARCHAR(20)
);

-- Logs de pedidos
DROP TABLE IF EXISTS LogsPedidos CASCADE;
CREATE TABLE LogsPedidos (
    id SERIAL PRIMARY KEY,
    pedido_id INT,
    accion VARCHAR(100),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pedido_id) REFERENCES Pedidos(id)
);