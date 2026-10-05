// Lightweight pattern-matching "chatbot" for the catalog popup -- no LLM, no
// API key. It only recognizes a couple of phrasings and forwards to
// mcp-catalog's real MCP tools rather than querying Postgres itself, so the
// tool logic stays in one place.
const MCP_URL = process.env.MCP_CATALOG_URL || "http://mcp-catalog.shop.svc.cluster.local/mcp";

async function callMcpTool(name, args) {
  const res = await fetch(MCP_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json, text/event-stream" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name, arguments: args } }),
  });
  const raw = await res.text();
  const line = raw.split("\n").find((l) => l.startsWith("data: "));
  if (!line) {
    throw new Error("unexpected response from mcp-catalog");
  }
  const parsed = JSON.parse(line.slice("data: ".length));
  if (parsed.error) {
    throw new Error(parsed.error.message);
  }
  return parsed.result?.content?.[0]?.text || "";
}

async function answer(question) {
  const text = String(question || "").trim();

  if (/\b(list|all items|show|catalog|what.*have)\b/i.test(text)) {
    return callMcpTool("list_items", {});
  }

  if (/\b(pod|pods|status|health|running)\b/i.test(text)) {
    return callMcpTool("get_pod_status", {});
  }

  const idMatch = text.match(/#?\s*(\d+)/);
  if (idMatch && /\b(item|id|detail|describe|tell)\b/i.test(text)) {
    return callMcpTool("get_item", { id: Number(idMatch[1]) });
  }

  return 'Try asking "list all items", "tell me about item 3", or "pod status".';
}

module.exports = { answer };
