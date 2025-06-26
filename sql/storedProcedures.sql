--Realizar el pago de un pedido, simulando la validación del pago.
--Postgres
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
--Realizar un pedido completo, aplicando cupones, stock, cálculos e inserciones.
--postgres
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
--Validar y registrar el uso de un cupón.
--Postgres
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
--Aplicar descuento masivo por categoría de libros.
-- MySQL
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

--Registrar cliente con validación de correos y opcionalmente tener un referido
create PROCEDURE sp_registrar_cliente(
    IN in_nombre varchar(50),
    in in_apellido varchar(50),
    in in_email varchar(100),
    in in_password varchar(100),
    in in_referido_id int
)
begin
    declare user_id int;
    IF EXISTS (
        SELECT 1 FROM Usuarios u WHERE u.email = in_email
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico ya está registrado.';
    end if;

    insert into  Usuarios (nombre, apellido, email, password)
        values (in_nombre,in_apellido,in_email,in_password);

    select id into user_id
    from Usuarios
    order by fecha_registro desc
    limit 1;

    IF (in_referido_id is not null)
    then
        insert into Referidos (cliente_id, referido_id)
            VALUES (user_id, in_referido_id);
    end if;
end;
--Devolver los clientes que más han influenciado en las referencias de otros clientes.
CREATE PROCEDURE sp_clientes_mas_influencia()
BEGIN
    SELECT CONCAT(u.nombre, ' ', u.apellido) AS full_name,
           COUNT(r.cliente_id) AS numero_de_referencias
    FROM Referidos r
    inner JOIN Usuarios u ON r.referido_id = u.id
    group by r.referido_id
    order by numero_de_referencias desc
    limit 10;
END;

call sp_clientes_mas_influencia();
