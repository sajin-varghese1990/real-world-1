const express = require("express");
const os = require("os");
const path = require("path");
const { ensureSchema, listItems } = require("./db");

const app = express();
const port = Number(process.env.PORT) || 8080;

app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.get("/api/info", (_req, res) => {
  res.json({
    hostname: os.hostname(),
    podName: process.env.HOSTNAME || os.hostname(),
    nodeName: process.env.NODE_NAME || "unknown",
    namespace: process.env.POD_NAMESPACE || "unknown",
    pgHost: process.env.PGHOST || "unset",
    tier: "web",
    phase: 3,
  });
});

app.get("/api/items", async (_req, res) => {
  try {
    const items = await listItems();
    res.json({ items });
  } catch (err) {
    console.error(err);
    res.status(503).json({ error: "database unavailable" });
  }
});

ensureSchema()
  .catch((err) => console.error("schema init failed (will retry on request)", err))
  .finally(() => {
    app.listen(port, "0.0.0.0", () => {
      console.log(`shop frontend listening on ${port}`);
    });
  });
