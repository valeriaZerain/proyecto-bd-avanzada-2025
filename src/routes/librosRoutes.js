const { z } = require('zod');
const express = require('express');
const router = express.Router();

const validLocations = ['location1', 'location2', 'location3', 'location4', 'location5', 'location6'];

const libroSchema = z.object({
  location: z.enum(validLocations),
  isbn: z.number().int().positive(),
  titulo: z.string().min(1),
  descripcion: z.string().min(1),
  precio: z.number().positive(),
  stock: z.number().int().nonnegative(),
  autor_id: z.number().int().positive(),
  categoria_id: z.number().int().positive(),
  editorial_id: z.number().int().positive(),
  publicado: z.boolean().optional().default(true)

});

const locationToShard = {
  location1: 'mysql_shard1',
  location2: 'mysql_shard2',
  location3: 'mysql_shard3',
  location4: 'mysql_shard4',
  location5: 'mysql_shard5',
  location6: 'mysql_shard6',
};

router.post('/', async (req, res) => {
  try {
    const data = libroSchema.parse(req.body);

    const {
      location, isbn, titulo, descripcion, precio,
      stock, autor_id, categoria_id, editorial_id, publicado
    } = data;

    const shardName = locationToShard[location];
    const mysqlClients = req.app.locals.dbs.mysql;

    if (!shardName) {
      return res.status(400).json({ error: 'Ubicación no válida' });
    }

    const insertQuery = `
      INSERT INTO Libros (isbn, titulo, descripcion, precio, stock, autor_id, categoria_id, editorial_id, publicado)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const values = [isbn, titulo, descripcion, precio, stock, autor_id, categoria_id, editorial_id, publicado];


    let targets;
    if (location === 'location1' || location === 'location4') {
      targets = [mysqlClients.find(c => c.name === shardName)];
    } else {
      targets = [
        mysqlClients.find(c => c.name === 'mysql_shard2'),
        mysqlClients.find(c => c.name === 'mysql_shard5'),
      ];
    }

    const insertResults = [];
    for (const target of targets) {
      if (!target) continue;
      const [result] = await target.client.query(insertQuery, values);
      insertResults.push({ shard: target.name, insertId: result.insertId });
    }

    res.json({ insertedInto: insertResults });

  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validación fallida', details: err.errors });
    }

    console.error('Error en insert de libro:', err);
    res.status(500).json({ error: 'Error en el servidor' });
  }
});

module.exports = router;
