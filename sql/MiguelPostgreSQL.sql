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