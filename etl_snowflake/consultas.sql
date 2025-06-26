SELECT
    m.tipo AS metodo_pago,
    COUNT(*) AS cantidad_usos
FROM hechos_ventas h
JOIN dimension_metodopago m ON h.id_métodopago = m.id
GROUP BY m.tipo
ORDER BY cantidad_usos DESC;

SELECT
    c.tipo_categoria,
    SUM(h.cantidad) AS total_vendido
FROM hechos_ventas h
JOIN dimension_libro l ON h.id_libro = l.id_libro
JOIN dimension_categoria c ON l.id_categoria = c.id
GROUP BY c.tipo_categoria
ORDER BY total_vendido DESC;

SELECT
    u.id AS id_cliente,
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(h.total_pagado) AS total_gastado
FROM hechos_ventas h
JOIN dimension_usuario u ON h.id_cliente = u.id
GROUP BY u.id, u.nombre, u.apellido
ORDER BY total_gastado DESC
LIMIT 10;


SELECT
    ROUND(COUNT(DISTINCT id_pedido) * 1.0 / COUNT(DISTINCT id_cliente), 2) AS promedio_pedidos_por_cliente
FROM hechos_ventas;

SELECT COUNT(*) AS total_ventas_con_cupon
FROM hechos_ventas
WHERE cupon_codigo IS NOT NULL;

SELECT COUNT(*) AS total_ventas_sin_cupon
FROM hechos_ventas
WHERE cupon_codigo IS NULL;