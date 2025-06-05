CREATE VIEW vista_libros_detallada AS
SELECT
    l.isbn,
    l.titulo,
    l.precio,
    a.nombre AS autor,
    e.editorial,
    c.categoria
FROM Libros l
JOIN Autores a ON l.autor_id = a.id
JOIN Editoriales e ON l.editorial_id = e.id
JOIN Categorias c ON l.categoria_id = c.id;

SELECT * from vista_libros_detallada;

DROP PROCEDURE IF EXISTS sp_aplicar_descuento_por_categoria;
CREATE PROCEDURE sp_aplicar_descuento_por_categoria(IN categoria VARCHAR(100), IN descuento DECIMAL(10,2))
    BEGIN
    IF descuento < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El porcentaje de descuento debe ser mayor a 0';
    end if;
    UPDATE Libros l
    JOIN Categorias c ON c.id = l.categoria_id
    SET precio = precio * (1 - descuento / 100)
    WHERE c.categoria = categoria;
END
