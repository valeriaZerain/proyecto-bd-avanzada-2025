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

select  fn_compras_por_cliente(2237);


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

CREATE OR REPLACE PROCEDURE sp_realizar_pedido(
    cliente_id INT,
    items JSONB,
    direccion_id INT,
    metodo_pago_id INT,
    cupon_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    nuevo_pedido_id INT;
    total DECIMAL := 0;
    item JSONB;
    libro_id INT;
    cantidad INT;
    precio_unitario DECIMAL := 50; -- Simulación de precio
    descuento DECIMAL := 0;
BEGIN
    -- Calcular total
    FOR item IN SELECT * FROM jsonb_array_elements(items) LOOP
        libro_id := (item ->> 'libro_isbn')::INT;
        cantidad := (item ->> 'cantidad')::INT;
        total := total + cantidad * precio_unitario;

        -- Validaciones de stock simuladas
        IF cantidad > 10 THEN
            RAISE EXCEPTION 'No hay suficiente stock para el libro %', libro_id;
        END IF;
    END LOOP;

    -- Aplicar cupón
    IF cupon_id IS NOT NULL THEN
        SELECT descuento_porcentaje INTO descuento
        FROM Cupones
        WHERE id = cupon_id AND activo = TRUE AND fecha_expiracion > CURRENT_DATE
        AND usos_actuales < max_uso;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cupón inválido o expirado';
        END IF;

        total := total * (1 - descuento / 100.0);
        UPDATE Cupones SET usos_actuales = usos_actuales + 1 WHERE id = cupon_id;
    END IF;

    -- Insertar pedido
    INSERT INTO Pedidos(usuario_id, fecha_pedido, estado, total, cupon_id)
    VALUES (cliente_id, CURRENT_TIMESTAMP, 'Pendiente', total, cupon_id)
    RETURNING id INTO nuevo_pedido_id;

    -- Insertar detalles
    FOR item IN SELECT * FROM jsonb_array_elements(items) LOOP
        libro_id := (item ->> 'libro_isbn')::INT;
        cantidad := (item ->> 'cantidad')::INT;
        INSERT INTO DetallesPedido(pedido_id, libro_isbn, cantidad, precio_unitario)
        VALUES (nuevo_pedido_id, libro_id, cantidad, precio_unitario);
    END LOOP;

    -- Log
    INSERT INTO LogsPedidos(pedido_id, accion, descripcion)
    VALUES (nuevo_pedido_id, 'Pedido creado', 'Pedido registrado con éxito');
END;
$$;

CALL sp_realizar_pedido(
    1,
    '[{"libro_isbn":101, "cantidad":2}, {"libro_isbn":102, "cantidad":1}]',
    1,
    1,
    NULL
);

CREATE OR REPLACE PROCEDURE sp_realizar_pago(pedido_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Iniciar una transacción
    BEGIN
        -- Simular validación de método de pago
        IF RANDOM() > 0.8 THEN -- 20% de error simulado
            RAISE EXCEPTION 'Fallo en el método de pago';
        END IF;

        -- Actualizar estado del pedido
        UPDATE Pedidos SET estado = 'Pagado' WHERE id = pedido_id;

        -- Log
        INSERT INTO LogsPedidos(pedido_id, accion, descripcion)
        VALUES (pedido_id, 'Pago exitoso', 'El pago fue procesado correctamente');

        -- Confirmar la transacción
    EXCEPTION WHEN OTHERS THEN
        -- Log de error
        INSERT INTO LogsPedidos(pedido_id, accion, descripcion)
        VALUES (pedido_id, 'Error de pago', SQLERRM);

        -- Deshacer la transacción
        ROLLBACK;
        RAISE;
    END;
END;
$$;

-- Llamar al procedimiento
CALL sp_realizar_pago(1);
