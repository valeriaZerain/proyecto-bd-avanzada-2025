// src/routes/pedidos.js
const express = require('express');
const router = express.Router();
const { z } = require('zod');

const schema = z.object({
  location: z.enum(['location1', 'location2', 'location3', 'location4', 'location5', 'location6']),
});

const locationToShardMap = {
  location1: 'pg_shard1',
  location2: 'pg_shard2',
  location3: 'pg_shard3',
  location4: 'pg_shard4',
  location5: 'pg_shard5',
  location6: 'pg_shard6',
};

router.get('/', async (req, res) => {
  try {
    const { location } = schema.parse(req.body);

    const shardName = locationToShardMap[location];
    if (!shardName) {
      return res.status(400).json({ error: 'Location no mapeado a shard' });
    }

    const pgShard = req.app.locals.dbs.postgres.find(db => db.name === shardName);

    if (!pgShard) {
      return res.status(500).json({ error: `Conexión no encontrada para shard: ${shardName}` });
    }

    const query = `
      SELECT *
      FROM Pedidos
      WHERE fecha_pedido >= $1 AND fecha_pedido < $2;
    `;

    const values = ['2022-12-01', '2023-01-01'];

    const result = await pgShard.client.query(query, values);

    res.json({ shard: shardName, pedidos: result.rows });

  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validación fallida', issues: err.errors });
    }
    console.error(err);
    res.status(500).json({ error: 'Error en servidor' });
  }
});

module.exports = router;