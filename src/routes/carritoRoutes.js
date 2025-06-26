// src/routes/cartRoutes.js
const express = require("express");
const { z } = require("zod");
const router = express.Router();

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

const CART_KEY_PREFIX = "cart:";

async function getCartCache(userId, redisClient) {
  const key = `${CART_KEY_PREFIX}${userId}`;
  const cached = await redisClient.get(key);
  if (cached) return JSON.parse(cached);
  return null;
}

async function setCartCache(userId, data, redisClient, ttlSeconds = 600) {
  const key = `${CART_KEY_PREFIX}${userId}`;
  const stringifiedData = JSON.stringify(data);
  await redisClient.set(key, stringifiedData, 'EX', ttlSeconds);
}

async function getCartDB(userId, pgClient) {
  const query = `
    SELECT c.id AS cart_id, ci.libro_isbn, ci.cantidad
    FROM Carritos c
    JOIN CarritoItems ci ON ci.carrito_id = c.id
    WHERE c.usuario_id = $1
  `;
  const values = [userId];

  const result = await pgClient.query(query, values);
  return result.rows;
}


async function getCart(userId, pgClient, redisClient) {
  const cached = await getCartCache(userId, redisClient);
  if (cached) return { cart: cached, source: "cache" };

  const dbData = await getCartDB(userId, pgClient);
  await setCartCache(userId, dbData, redisClient);
  return { cart: dbData, source: "db" };
}

router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const validation = schema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: "Ubicación inválida",
        details: validation.error.errors,
      });
    }
    const { location } = validation.data;

    const shardName = locationToShardMap[location];
    if (!shardName) {
      return res.status(400).json({ error: "Shard no definido para esta ubicación" });
    }

    const pgClientWrapper = req.app.locals.dbs.postgres.find(db => db.name === shardName);
    if (!pgClientWrapper) {
      return res.status(500).json({ error: "Conexión al shard no encontrada" });
    }
    const pgClient = pgClientWrapper.client;

    const redisClient = req.app.locals.dbs.redis;
    if (!redisClient) {
      return res.status(500).json({ error: "Conexión Redis no configurada" });
    }

    const { cart, source } = await getCart(userId, pgClient, redisClient);

    res.json({ userId, location, source, cart });

  } catch (err) {
    console.error("Error en /cart/:userId", err);
    res.status(500).json({ error: "Error interno del servidor" });
  }
});

module.exports = router;
