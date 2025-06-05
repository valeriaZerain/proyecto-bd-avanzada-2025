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