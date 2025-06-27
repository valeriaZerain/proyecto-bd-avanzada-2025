db.createCollection("usuarios");

db.usuarios.insertOne({
  nombre: "Ana López",
  email: "ana@gmail.com",
  telefono: "78945612",
  notificaciones: [
    { mensaje: "Tu pedido fue enviado", leido: false, fecha: ISODate("2025-05-22T10:00:00Z") },
    { mensaje: "Cupón del 20% disponible", leido: true, fecha: ISODate("2025-05-20T08:00:00Z") }
  ]
});

db.createCollection("libros");

db.libros.insertOne({
  titulo: "Cien Años de Soledad",
  autor: "Gabriel García Márquez",
  precio: 25.99,
  stock: 10,
  seguimientos: [
    { usuario_id: ObjectId("665caaa123abcde000000001"), fecha: new Date() },
    { usuario_id: ObjectId("665caaa123abcde000000002"), fecha: new Date() }
  ]
});

db.createCollection("comentarios");

db.comentarios.insertOne({
  libro_id: ObjectId("665caaa123abcde000000010"),
  usuario_id: ObjectId("665caaa123abcde000000003"),
  texto: "Excelente lectura",
  calificacion: 5,
  fecha: new Date(),
  reportes: [
    { motivo: "Spam", fecha: new Date() },
    { motivo: "Inapropiado", fecha: new Date() }
  ]
});

db.createCollection("carritos");

db.carritos.insertOne({
  usuario_id: ObjectId("665caaa123abcde000000004"),
  libros: [
    { libro_id: ObjectId("665caaa123abcde000000010"), cantidad: 2 },
    { libro_id: ObjectId("665caaa123abcde000000011"), cantidad: 1 }
  ],
  total_estimado: 55.98,
  fecha: new Date()
});

db.createCollection("facturas");

db.facturas.insertOne({
  usuario_id: ObjectId("665caaa123abcde000000004"),
  fecha: new Date(),
  total_pagado: 80.00,
  items: [
    { titulo: "Libro A", cantidad: 2, precio_unitario: 20 },
    { titulo: "Libro B", cantidad: 1, precio_unitario: 40 }
  ]
});

db.createCollection("envios");

db.envios.insertOne({
  pedido_id: ObjectId("665caaa123abcde000000020"),
  empresa: "DHL",
  tracking: "DHL987654321",
  estado: "En tránsito",
  fecha_envio: new Date(),
  fecha_estimado: new Date("2025-05-25")
});

db.createCollection("historial_precios");

db.historial_precios.insertMany([
  {
    libro_id: ObjectId("665caaa123abcde000000010"),
    precio_anterior: 25.99,
    precio_nuevo: 22.99,
    fecha_cambio: ISODate("2025-05-20T00:00:00Z")
  },
  {
    libro_id: ObjectId("665caaa123abcde000000010"),
    precio_anterior: 22.99,
    precio_nuevo: 20.99,
    fecha_cambio: ISODate("2025-05-22T00:00:00Z")
  }
]);

    db.createCollection("wishlists");

db.wishlists.insertOne({
  usuario_id: ObjectId("665caaa123abcde000000004"),
  libros: [
    ObjectId("665caaa123abcde000000010"),
    ObjectId("665caaa123abcde000000011")
  ],
  fecha_creacion: new Date()
});


db.createCollection("sesiones");

db.sesiones.insertOne({
  usuario_id: ObjectId("665caaa123abcde000000004"),
  fecha_inicio: ISODate("2025-05-22T09:00:00Z"),
  fecha_fin: ISODate("2025-05-22T10:30:00Z"),
  ip: "192.168.1.10",
  navegador: "Chrome 123"
});


db.createCollection("recomendaciones");

db.recomendaciones.insertOne({
  usuario_id: ObjectId("665caaa123abcde000000004"),
  libros_recomendados: [
    { libro_id: ObjectId("665caaa123abcde000000010"), razon: "Te gustó Realismo Mágico" },
    { libro_id: ObjectId("665caaa123abcde000000011"), razon: "Similares a tus intereses" }
  ],
  fecha_generacion: new Date()
});


///////////////////////////////////CONSULTAS
    //1. Total de ventas por libro
db.facturas.aggregate([
  { $unwind: "$items" },
  { $group: {
    _id: "$items.titulo",
    total_vendido: { $sum: "$items.cantidad" }
  }},
  { $sort: { total_vendido: -1 } }
]);
// 2. Clientes mas rentab les
    db.facturas.aggregate([
  { $group: {
    _id: "$usuario_id",
    total_gastado: { $sum: "$total_pagado" }
  }},
  { $sort: { total_gastado: -1 } }
]);
    //3. Libros con stock menos a 5
db.libros.aggregate([
  { $match: { stock: { $lte: 1 } } },
  { $project: { titulo: 1, stock: 1 } }
]);

//4. Comentarios libro, alcular calificación promedio y número de opiniones.
    db.comentarios.aggregate([
  { $group: {
    _id: "$libro_id",
    total_comentarios: { $sum: 1 },
    promedio_calificacion: { $avg: "$calificacion" }
  }},
  { $sort: { promedio_calificacion: -1 } }
]);

//.5Mostrar qué libros y por qué se recomendaron.
    db.recomendaciones.aggregate([
  { $unwind: "$libros_recomendados" },
  { $lookup: {
    from: "libros",
    localField: "libros_recomendados.libro_id",
    foreignField: "_id",
    as: "libro_detalle"
  }},
  { $project: {
    usuario_id: 1,
    razon: "$libros_recomendados.razon",
    titulo: { $arrayElemAt: ["$libro_detalle.titulo", 0] }
  }}
]);
//6.etectar usuarios posiblemente inactivos o saturados de notificaciones.
//
    db.usuarios.aggregate([
  { $project: {
    nombre: 1,
    notificaciones_no_leidas: {
      $size: {
        $filter: {
          input: "$notificaciones",
          as: "n",
          cond: { $eq: ["$$n.leido", false] }
        }
      }
    }
  }},
  { $match: { notificaciones_no_leidas: { $gt: 5 } } }
]);
//7.Detectar clientes que compran seguido.
db.facturas.aggregate([
  { $group: {
    _id: "$usuario_id",
    total_compras: { $sum: 1 }
  }},
  { $match: { total_compras: { $gte: 3 } } },
  { $sort: { total_compras: -1 } }
]);


    db.cupones.aggregate([
  { $project: {
    codigo: 1,
    veces_usado: { $size: "$usuarios_que_lo_usaron" }
  }},
  { $sort: { veces_usado: -1 } }
]);
//9. Analizar comportamiento de compra. promedio por libro
   db.carritos.aggregate([
  { $project: {
    cantidad_libros: { $size: "$libros" }
  }},
  { $group: {
    _id: null,
    promedio_libros: { $avg: "$cantidad_libros" }
  }}
]);
//10.
    db.facturas.aggregate([
  { $lookup: {
    from: "usuarios",
    localField: "usuario_id",
    foreignField: "_id",
    as: "usuario"
  }},
  { $unwind: "$usuario" },
  { $group: {
    _id: "$usuario.direccion.pais",
    total: { $sum: "$total_pagado" }
  }},
  { $sort: { total: -1 } }
]);


    //11 libros mas deseado
    db.wishlists.aggregate([
  { $unwind: "$libros" },
  { $group: {
    _id: "$libros",
    veces_deseado: { $sum: 1 }
  }},
  { $sort: { veces_deseado: -1 } }
]);


    //12 Total de metodo de pago
    db.facturas.aggregate([
  { $group: {
    _id: "$metodo_pago",
    total: { $sum: "$total_pagado" }
  }}
]);
 //13. Libros que quieron los clientes
    db.libros.aggregate([
  { $project: {
    titulo: 1,
    seguimiento_count: { $size: "$seguimientos" }
  }},
  { $sort: { seguimiento_count: -1 } }
]);


    //14. Usuarios ,as activos
    db.sesiones.aggregate([
  { $group: {
    _id: "$usuario_id",
    sesiones: { $sum: 1 }
  }},
  { $sort: { sesiones: -1 } }
]);

    //15.Libros con frecios similiares
    db.historial_precios.aggregate([
  { $group: {
    _id: "$libro_id",
    cambios: { $sum: 1 }
  }},
  { $sort: { cambios: -1 } }
]);
//16
db.favoritos.aggregate([
  { $group: {
    _id: "$usuario_email",
    cantidad: { $sum: 1 }
  }},
  { $sort: { cantidad: -1 } }
]);

    //17 Facturacion por mes
    db.facturas.aggregate([
  { $group: {
    _id: { $month: "$fecha" },
    total_mes: { $sum: "$total_pagado" }
  }},
  { $sort: { "_id": 1 } }
]);

    //18 Libros sin comentarios
    db.libros.aggregate([
  { $lookup: {
    from: "comentarios",
    localField: "_id",
    foreignField: "libro_id",
    as: "comentarios"
  }},
  { $match: { comentarios: { $eq: [] } } },
  { $project: { titulo: 1 } }
]);


//19 promedio de calificacion por cliente
    db.comentarios.aggregate([
  { $group: {
    _id: "$usuario_id",
    promedio: { $avg: "$calificacion" }
  }},
  { $sort: { promedio: -1 } }
]);

//20
db.facturas.aggregate([
  { $unwind: "$items" },
  { $lookup: {
    from: "libros",
    localField: "items.libro_id",
    foreignField: "_id",
    as: "libro"
  }},
  { $unwind: "$libro" },
  { $group: {
    _id: "$libro.categoria",
    cantidad_total: { $sum: "$items.cantidad" }
  }},
  { $sort: { cantidad_total: -1 } }
]);