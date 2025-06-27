drop table logspedidos;
create table logspedidos(
    id SERIAL,
    pedido_id INT,
    accion VARCHAR(100),
    descripcion TEXT,
    fecha date DEFAULT current_date
) partition by RANGE (fecha);
create table logspedidos_2022 partition of logspedidos for values from ('2022-01-01') to ('2023-01-01');
create table logspedidos_2023 partition of logspedidos for values from ('2023-01-01') to ('2024-01-01');
create table logspedidos_2024 partition of logspedidos for values from ('2024-01-01') to ('2025-01-01');
create table logspedidos_2025 partition of logspedidos for values from ('2025-01-01') to ('2026-01-01');

explain analyse
select m.tipo, count(dp.id) as cantidad_de_pedidos, sum(dp.cantidad) as total_pedido
from detallespedido dp
inner join pedidos p on p.id = dp.pedido_id
inner join metodospago m on m.id = p.metodo_id
group by m.tipo;
--- p time 8.048 ms e time 212.743 ms sin index
--- p time 1.081 ms e time 118.795 ms con index

create index idx_pedido_id on detallespedido(pedido_id);
create index idx_metodos_id on pedidos(metodo_id);

drop  index  idx_metodos_id;
drop  index  idx_pedido_id;