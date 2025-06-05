PROCEdimiento

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
        COMMIT;
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


le puse que cree un logstock porque por las tablas no puedo cambiar el stock pipipi