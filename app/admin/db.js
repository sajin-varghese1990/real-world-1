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
      icon TEXT DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
  // Existing PVCs pre-date the icon column; init SQL only runs on a fresh volume.
  await pool.query(`ALTER TABLE items ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT ''`);
}

async function listItems() {
  const result = await pool.query(
    "SELECT id, name, note, icon, created_at FROM items ORDER BY id DESC"
  );
  return result.rows;
}

async function createItem(name, note, icon) {
  const result = await pool.query(
    "INSERT INTO items (name, note, icon) VALUES ($1, $2, $3) RETURNING id, name, note, icon, created_at",
    [name, note || "", icon || ""]
  );
  return result.rows[0];
}

module.exports = { pool, ensureSchema, listItems, createItem };
