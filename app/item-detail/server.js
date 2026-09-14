const express = require("express");
const os = require("os");
const path = require("path");
const { ensureSchema, getItemById } = require("./db");

const app = express();
const port = Number(process.env.PORT) || 8080;
const basePath = process.env.BASE_PATH || "/item";

app.use(basePath, express.static(path.join(__dirname, "public")));

app.get(`${basePath}/health`, (_req, res) => {
  res.json({ status: "ok", app: "item-detail" });
});

app.get(`${basePath}/api/info`, (_req, res) => {
  res.json({
    app: "item-detail",
    hostname: os.hostname(),
    podName: process.env.HOSTNAME || os.hostname(),
    nodeName: process.env.NODE_NAME || "unknown",
    namespace: process.env.POD_NAMESPACE || "unknown",
    pgHost: process.env.PGHOST || "unset",
    tier: "item-detail",
    phase: 4,
    basePath,
  });
});

app.get(`${basePath}/api/items/:id`, async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) {
    res.status(400).json({ error: "invalid item id" });
    return;
  }
  try {
    const item = await getItemById(id);
    if (!item) {
      res.status(404).json({ error: "item not found" });
      return;
    }
    res.json({ item });
  } catch (err) {
    console.error(err);
    res.status(503).json({ error: "database unavailable" });
  }
});

// Catch-all for /item/<id>: serves the static detail page, which then fetches
// the API route above client-side. Registered last so it doesn't shadow the
// more specific routes.
app.get(`${basePath}/:id`, (_req, res) => {
  res.sendFile(path.join(__dirname, "public", "detail.html"));
});

ensureSchema()
  .catch((err) => console.error("schema init failed (will retry on request)", err))
  .finally(() => {
    app.listen(port, "0.0.0.0", () => {
      console.log(`shop item-detail listening on ${port} at ${basePath}`);
    });
  });
