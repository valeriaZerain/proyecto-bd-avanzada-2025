-- Usuarios
DROP TABLE IF EXISTS Usuarios CASCADE;
CREATE TABLE Usuarios (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    email VARCHAR(100),
    password VARCHAR(100),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Autores
DROP TABLE IF EXISTS Autores CASCADE;
CREATE TABLE Autores (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    nacionalidad VARCHAR(100)
);

-- Categorías
DROP TABLE IF EXISTS Categorias CASCADE;
CREATE TABLE Categorias (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    categoria VARCHAR(100)
);

-- Editoriales
DROP TABLE IF EXISTS Editoriales CASCADE;
CREATE TABLE Editoriales (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    editorial VARCHAR(150),
    pais VARCHAR(100)
);

-- Libros
DROP TABLE IF EXISTS Libros CASCADE;
CREATE TABLE Libros (
    isbn INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(200),
    descripcion VARCHAR(1000),
    precio DECIMAL(10,2),
    stock INT,
    autor_id INT UNSIGNED,
    categoria_id INT UNSIGNED,
    editorial_id INT UNSIGNED,
    publicado BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (autor_id) REFERENCES Autores(id),
    FOREIGN KEY (categoria_id) REFERENCES Categorias(id),
    FOREIGN KEY (editorial_id) REFERENCES Editoriales(id)
);

-- Favoritos
DROP TABLE IF EXISTS Favoritos CASCADE;
CREATE TABLE Favoritos (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT UNSIGNED,
    libro_id INT UNSIGNED,
    fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(id),
    FOREIGN KEY (libro_id) REFERENCES Libros(isbn)
);

-- Referidos (clientes con código de referencia)
DROP TABLE IF EXISTS Referidos CASCADE;
CREATE TABLE Referidos (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT UNSIGNED,
    referido_id INT UNSIGNED,
    fecha_referencia TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES Usuarios(id),
    FOREIGN KEY (referido_id) REFERENCES Usuarios(id)
);