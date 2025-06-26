--Aplicar un descuento automático si el cliente tiene más de 10 compras.
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
--Insertar en un log cuando se descuenta el stock por una venta.
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
--Si el stock de un libro llega a 0 lo marca como no disponible.
--Insertar un log de compra luego de realizar y completar un pedido.
--Registra un log si se elimina un pedido.
create or replace function fn_trg_log_transaccion_compra()
returns trigger as $$
    begin
        insert into logspedidos(pedido_id, accion, descripcion)
        values (new.id,'create',concat('nueva transacción del usuario ', new.usuario_id));
        return new;
    end;
$$ language plpgsql;

create trigger trg_log_transaccion_compra
after insert on pedidos
for each ROW
execute function fn_trg_log_transaccion_compra();

create or replace function fn_trg_log_transaccion_compra_delete()
returns trigger as $$
    begin
        insert into logspedidos(pedido_id, accion, descripcion)
        values (old.id,'delete',concat('se elimino una transacción del usuario ', old.usuario_id));
        return old;
    end;
$$ language plpgsql;

create trigger trg_log_transaccion_compra_delete
before delete on pedidos
for each ROW
execute function fn_trg_log_transaccion_compra_delete();
--Muestra mensaje si el nuevo cliente fue referido.