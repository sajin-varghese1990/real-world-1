const express = require("express");
const os = require("os");
const path = require("path");
const { ensureSchema, listItems, createItem } = require("./db");

const app = express();
const port = Number(process.env.PORT) || 8080;
const basePath = process.env.BASE_PATH || "/admin";

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(basePath, express.static(path.join(__dirname, "public")));

app.get(`${basePath}/health`, (_req, res) => {
  res.json({ status: "ok", app: "admin" });
});

app.get(`${basePath}/api/info`, (_req, res) => {
  res.json({
    app: "admin",
    hostname: os.hostname(),
    podName: process.env.HOSTNAME || os.hostname(),
    nodeName: process.env.NODE_NAME || "unknown",
    namespace: process.env.POD_NAMESPACE || "unknown",
    pgHost: process.env.PGHOST || "unset",
    tier: "admin",
    phase: 3,
    basePath,
  });
});

app.get(`${basePath}/api/items`, async (_req, res) => {
  try {
    const items = await listItems();
    res.json({ items });
  } catch (err) {
    console.error(err);
    res.status(503).json({ error: "database unavailable" });
  }
});

app.post(`${basePath}/api/items`, async (req, res) => {
  const name = String(req.body.name || "").trim();
  const note = String(req.body.note || "").trim();
  if (!name) {
    res.status(400).json({ error: "name is required" });
    return;
  }
  try {
    const item = await createItem(name, note);
    res.status(201).json({ item });
  } catch (err) {
    console.error(err);
    res.status(503).json({ error: "database unavailable" });
  }
});

ensureSchema()
  .catch((err) => console.error("schema init failed (will retry on request)", err))
  .finally(() => {
    app.listen(port, "0.0.0.0", () => {
      console.log(`shop admin listening on ${port} at ${basePath}`);
    });
  });
