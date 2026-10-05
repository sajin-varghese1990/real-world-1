import * as k8s from "@kubernetes/client-node";

const NAMESPACE = process.env.POD_NAMESPACE || "shop";

// Lazy: loadFromCluster() reads the ServiceAccount token/CA files
// synchronously and throws if they don't exist. Deferring it to first use
// means list_items/get_item still work even if this ever runs outside a
// real pod (local testing, no cluster), instead of crashing on import.
let api;
function client() {
  if (!api) {
    const kc = new k8s.KubeConfig();
    kc.loadFromCluster();
    api = kc.makeApiClient(k8s.CoreV1Api);
  }
  return api;
}

export async function getPodStatus() {
  const res = await client().listNamespacedPod({ namespace: NAMESPACE });
  return res.items.map((pod) => {
    const name = pod.metadata.name;
    const phase = pod.status.phase;
    const containers = pod.status.containerStatuses || [];
    const ready = containers.length > 0 && containers.every((c) => c.ready);
    const restarts = containers.reduce((sum, c) => sum + c.restartCount, 0);
    return { name, phase, ready, restarts };
  });
}
