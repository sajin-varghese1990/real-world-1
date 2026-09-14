#!/usr/bin/env bash
# Apply the committed Argo CD manifests, then bootstrap the app-of-apps root
# Application. From there Argo CD syncs shop-base/shop-db/shop-cache itself
# from GitHub main. Cluster and shop apps are untouched by this script.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"

echo "Applying Argo CD (namespace ${ARGOCD_NAMESPACE})"
# Server-side apply: the ApplicationSet CRD's schema is too large for the
# last-applied-configuration annotation client-side apply would write.
kubectl apply --server-side --force-conflicts -f "${ARGOCD_INSTALL_DIR}"
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deploy/argocd-server --timeout=180s
kubectl -n "${ARGOCD_NAMESPACE}" rollout status statefulset/argocd-application-controller --timeout=180s

echo "Bootstrapping app-of-apps root Application"
kubectl apply --server-side --force-conflicts -f "${ARGOCD_ROOT_APP}"

echo
echo "Argo CD is up. Initial admin password:"
echo "  kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo "UI (separate terminal, leave running):"
echo "  kubectl -n ${ARGOCD_NAMESPACE} port-forward svc/argocd-server 8080:80"
echo "Check sync status:"
echo "  kubectl -n ${ARGOCD_NAMESPACE} get applications"
