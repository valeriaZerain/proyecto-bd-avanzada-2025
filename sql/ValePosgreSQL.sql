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

CREATE OR REPLACE PROCEDURE sp_registrar_cupon(cupon_codigo varchar)
LANGUAGE plpgsql AS $$
    DECLARE
        cupon RECORD;
    BEGIN
        SELECT max_uso, usos_actuales, fecha_expiracion, activo
        INTO cupon
        FROM cupones
        WHERE codigo = cupon_codigo;
        IF cupon.activo AND cupon.fecha_expiracion > CURRENT_DATE AND cupon.usos_actuales + 1 <= cupon.max_uso THEN
            UPDATE cupones
            SET usos_actuales = cupon.usos_actuales + 1
            WHERE codigo = cupon_codigo;
            RAISE NOTICE 'El cupón con código % es válido, se registrará su uso', cupon_codigo;
        ELSE
            RAISE EXCEPTION 'El cupón con código % no es válido, no se registrará', cupon_codigo;
        END IF;
    END;
$$;

CALL sp_registrar_cupon('CUPON-mFOKc');

CREATE OR REPLACE FUNCTION descuento_por_cantidad_compras()
RETURNS trigger AS $$
BEGIN
    IF (SELECT COUNT(*) FROM pedidos WHERE usuario_id = NEW.usuario_id and pedidos.estado != 'cancelado' GROUP BY usuario_id) >= 10 THEN
        NEW.total = NEW.total*0.9;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_descuento_por_cantidad_de_compras
BEFORE INSERT ON pedidos
FOR EACH ROW
EXECUTE FUNCTION descuento_por_cantidad_compras();

CREATE TABLE log_stock (
    id SERIAL PRIMARY KEY,
    libro_id INT,
    cambio INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    motivo TEXT
);

CREATE OR REPLACE FUNCTION log_cambio_stock()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log_stock(libro_id, cambio, motivo)
    VALUES (NEW.libro_isbn, -NEW.cantidad, 'Venta');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_cambio_stock
AFTER INSERT ON detallesPedido
FOR EACH ROW
EXECUTE FUNCTION log_cambio_stock();


