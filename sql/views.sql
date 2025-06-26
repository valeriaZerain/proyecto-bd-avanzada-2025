-- Vista de libros
-- MySQL
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

-- Vista de pedidos completos
-- PostgreSQL
CREATE OR REPLACE VIEW vw_pedidos_completos AS
SELECT
    p.id AS pedido_id,
    p.usuario_id,
    p.fecha_pedido,
    p.estado,
    p.total,
    c.codigo AS cupon_codigo,
    d.libro_isbn,
    d.cantidad,
    d.precio_unitario
FROM Pedidos p
LEFT JOIN Cupones c ON p.cupon_id = c.id
JOIN DetallesPedido d ON d.pedido_id = p.id;


SELECT * FROM vw_pedidos_completos;