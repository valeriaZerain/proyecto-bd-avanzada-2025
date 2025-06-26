--Monto total monetario de ventas por mes en un año específico.
--Postgres
CREATE OR REPLACE FUNCTION fn_monto_ventas_por_mes(anio INT)
RETURNS TABLE(mes INT, total_ventas NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT
        EXTRACT(MONTH FROM fecha_pedido)::INT AS mes,
        SUM(total) AS total_ventas
    FROM Pedidos
    WHERE EXTRACT(YEAR FROM fecha_pedido) = anio
    GROUP BY mes
    ORDER BY mes;
END;
$$ LANGUAGE plpgsql;

select fn_monto_ventas_por_mes(2025);
--Cantidad de ventas por mes en un año específico.
--Postgres
CREATE OR REPLACE FUNCTION ventas_por_mes(
    anio INT
)
RETURNS TABLE (mes INT, ventas_realizadas INT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        EXTRACT(MONTH FROM fecha_pedido)::INT AS mes,
        COUNT(*):: INT AS ventas_realizadas
    FROM Pedidos
    WHERE EXTRACT(YEAR FROM fecha_pedido) = anio AND estado != 'cancelado'
    GROUP BY mes
    ORDER BY mes DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM ventas_por_mes(2025);
--Contar cuántas compras realizó un cliente.
--Postgres
CREATE OR REPLACE FUNCTION fn_compras_por_cliente(cliente_id INT)
RETURNS INT AS $$
DECLARE
    cantidad INT;
BEGIN
    SELECT COUNT(*) INTO cantidad
    FROM Pedidos
    WHERE usuario_id = cliente_id;

    RETURN cantidad;
END;
$$ LANGUAGE plpgsql;

select  fn_compras_por_cliente(501);
--Para los filtrados se genera un json con categorías como clave y la lista de los libros como valores.
--MySQL
DELIMITER $$
DROP FUNCTION IF EXISTS fn_libros_por_categoria;

CREATE FUNCTION fn_libros_por_categoria()
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE resultado JSON;

    SELECT JSON_OBJECTAGG(
        c.categoria,
        (
            SELECT JSON_ARRAYAGG(l.titulo)
            FROM Libros l
            WHERE l.categoria_id = c.id
        )
    )
    INTO resultado
    FROM Categorias c;

    RETURN resultado;
END $$
--Ranking de clientes con más referencias.
--Mysql
create function fn_clientes_mas_influencia()
returns INT
deterministic
begin
    declare most_referenced_id int;

    select r.referido_id into most_referenced_id
    from Referidos r
    group by r.referido_id
    order by count(*) desc
    limit 1;

    return  most_referenced_id;
end;

select fn_clientes_mas_influencia();
--Recuperar toda la información detallada de un pedido en específico.
--Postgres
create or replace function fn_detalle_compra(in_pedido_id INT)
returns table(
    pedido_id int,
    usuario_id int,
    fecha_pedido timestamp,
    estado varchar(25),
    total numeric,
    cupon_codigo varchar(25),
    libro_isbn integer,
    cantidad int,
    precio_unitario numeric) as $$
    begin
        return query
        select * from vw_pedidos_completos vw
        where vw.pedido_id = in_pedido_id;
    end;
$$ language plpgsql;

select fn_detalle_compra(120);
