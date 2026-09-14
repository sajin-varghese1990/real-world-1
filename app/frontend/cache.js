const dns = require("dns").promises;
const { createClient } = require("redis");

const host = process.env.REDIS_HEADLESS_HOST || "";
const port = Number(process.env.REDIS_PORT) || 6379;
const ttlSeconds = Number(process.env.REDIS_TTL_SECONDS) || 60;
const ITEMS_KEY = "shop:items";

async function peerIps() {
  if (!host) {
    return [];
  }
  try {
    return await dns.resolve4(host);
  } catch (err) {
    console.error("headless redis DNS failed", err.message);
    return [];
  }
}

async function withEachPeer(fn) {
  const ips = await peerIps();
  const results = [];
  for (const ip of ips) {
    const client = createClient({
      url: `redis://${ip}:${port}`,
      socket: { connectTimeout: 1500 },
    });
    try {
      await client.connect();
      results.push(await fn(client, ip));
    } catch (err) {
      console.error(`redis ${ip}`, err.message);
    } finally {
      await client.quit().catch(() => undefined);
    }
  }
  return { ips, results };
}

async function getCachedItems() {
  const { ips, results } = await withEachPeer(async (client) => client.get(ITEMS_KEY));
  const hit = results.find((value) => value);
  if (!hit) {
    return { items: null, source: "miss", redisPeers: ips };
  }
  return { items: JSON.parse(hit), source: "cache", redisPeers: ips };
}

async function setCachedItems(items) {
  const payload = JSON.stringify(items);
  const { ips } = await withEachPeer(async (client) =>
    client.set(ITEMS_KEY, payload, { EX: ttlSeconds })
  );
  return ips;
}

async function invalidateItemsCache() {
  const { ips } = await withEachPeer(async (client) => client.del(ITEMS_KEY));
  return ips;
}

module.exports = {
  peerIps,
  getCachedItems,
  setCachedItems,
  invalidateItemsCache,
};
