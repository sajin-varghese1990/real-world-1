const express = require("express");
const os = require("os");
const path = require("path");
const { ensureSchema, listItems } = require("./db");
const { getCachedItems, setCachedItems, peerIps } = require("./cache");

const app = express();
const port = Number(process.env.PORT) || 8080;

app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.get("/api/info", async (_req, res) => {
  const redisPeers = await peerIps();
  res.json({
    hostname: os.hostname(),
    podName: process.env.HOSTNAME || os.hostname(),
    nodeName: process.env.NODE_NAME || "unknown",
    namespace: process.env.POD_NAMESPACE || "unknown",
    pgHost: process.env.PGHOST || "unset",
    redisHeadless: process.env.REDIS_HEADLESS_HOST || "unset",
    redisPeers,
    tier: "web",
    phase: 4,
  });
});

app.get("/api/items", async (_req, res) => {
  try {
    const cached = await getCachedItems();
    if (cached.items) {
      res.json({ items: cached.items, source: cached.source, redisPeers: cached.redisPeers });
      return;
    }
    const items = await listItems();
    const redisPeers = await setCachedItems(items);
    res.json({ items, source: "database", redisPeers });
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
