import express from "express";
import { createMcpHandler, McpServer } from "@modelcontextprotocol/server";
import { toNodeHandler } from "@modelcontextprotocol/node";
import * as z from "zod/v4";
import { ensureSchema, listItems, getItemById } from "./db.js";

const port = Number(process.env.PORT) || 8080;
const basePath = process.env.BASE_PATH || "/mcp";

function formatItem(item) {
  const icon = item.icon ? ` (icon: ${item.icon})` : "";
  return `#${item.id} ${item.name} — ${item.note || "no description"}${icon}`;
}

function createServer() {
  const server = new McpServer({ name: "shop-catalog", version: "1.0.0" });

  server.registerTool(
    "list_items",
    {
      title: "List catalog items",
      description: "List all items in the shop catalog (id, name, description, icon).",
      inputSchema: z.object({}),
    },
    async () => {
      const items = await listItems();
      if (!items.length) {
        return { content: [{ type: "text", text: "The catalog is empty." }] };
      }
      return { content: [{ type: "text", text: items.map(formatItem).join("\n") }] };
    }
  );

  server.registerTool(
    "get_item",
    {
      title: "Get one catalog item",
      description: "Get a single catalog item by id.",
      inputSchema: z.object({ id: z.number().int().describe("Item id") }),
    },
    async ({ id }) => {
      const item = await getItemById(id);
      if (!item) {
        return { content: [{ type: "text", text: `No item with id ${id}.` }], isError: true };
      }
      return { content: [{ type: "text", text: formatItem(item) }] };
    }
  );

  return server;
}

// Deliberately plain express(), not @modelcontextprotocol/express's
// createMcpExpressApp(): that wrapper's DNS-rebinding guard only allowlists
// 127.0.0.1/localhost by default, and would 403 kubelet's health probes
// (which hit this pod's IP directly, not shop.local) the moment it binds
// 0.0.0.0. NetworkPolicy already restricts who can reach this pod at all.
const handler = createMcpHandler(createServer);
const node = toNodeHandler(handler);

const app = express();
app.use(express.json());

app.get(`${basePath}/health`, (_req, res) => {
  res.json({ status: "ok", app: "mcp-catalog" });
});

app.all(basePath, (req, res) => void node(req, res, req.body));

ensureSchema()
  .catch((err) => console.error("schema init failed (will retry on request)", err))
  .finally(() => {
    app.listen(port, "0.0.0.0", () => {
      console.log(`shop mcp-catalog listening on ${port} at ${basePath}`);
    });
  });
