#!/usr/bin/env bash
# Build app images, apply Postgres in shop-db then apps in shop.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "Cluster is not reachable. Run ./scripts/cluster-up.sh first." >&2
  exit 1
fi

echo "Ensuring ingress addon is enabled"
minikube -p "${MINIKUBE_PROFILE}" addons enable ingress >/dev/null
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s

echo "Applying database in ${DB_NAMESPACE}"
kubectl apply -f "${DB_DIR}"
kubectl rollout status statefulset/postgres -n "${DB_NAMESPACE}" --timeout=180s
kubectl wait --for=condition=ready pod -l app=postgres -n "${DB_NAMESPACE}" --timeout=180s

echo "Building ${IMAGE} and ${ADMIN_IMAGE}"
docker build -t "${IMAGE}" "${FRONTEND_DIR}"
docker build -t "${ADMIN_IMAGE}" "${ADMIN_DIR}"

echo "Loading images onto all nodes in ${MINIKUBE_PROFILE}"
minikube -p "${MINIKUBE_PROFILE}" image load "${IMAGE}"
minikube -p "${MINIKUBE_PROFILE}" image load "${ADMIN_IMAGE}"

echo "Applying apps in ${NAMESPACE}"
kubectl apply -f "${K8S_DIR}"
# Same image tags (:1.0) reuse the node cache; restart so new layers run.
kubectl rollout restart deployment/frontend deployment/admin -n "${NAMESPACE}"
kubectl rollout status deployment/frontend -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/admin -n "${NAMESPACE}" --timeout=120s
kubectl get pods,svc,ingress -n "${NAMESPACE}" -o wide
kubectl get pods,svc,sts,pvc -n "${DB_NAMESPACE}" -o wide

echo
echo "Two-tier shop is up (keep tunnel running):"
echo "  minikube -p ${MINIKUBE_PROFILE} tunnel"
echo "  curl -sS http://shop.local/api/items"
echo "  curl -sS -X POST http://shop.local/admin/api/items -H 'Content-Type: application/json' -d '{\"name\":\"apples\",\"note\":\"from admin\"}'"
echo "Hosts file (you manage): 127.0.0.1 shop.local"
