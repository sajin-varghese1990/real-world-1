const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.PGHOST,
  port: Number(process.env.PGPORT) || 5432,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  database: process.env.PGDATABASE,
});

async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS items (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      note TEXT DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
}

async function listItems() {
  const result = await pool.query(
    "SELECT id, name, note, created_at FROM items ORDER BY id DESC"
  );
  return result.rows;
}

async function createItem(name, note) {
  const result = await pool.query(
    "INSERT INTO items (name, note) VALUES ($1, $2) RETURNING id, name, note, created_at",
    [name, note || ""]
  );
  return result.rows[0];
}

module.exports = { pool, ensureSchema, listItems, createItem };
