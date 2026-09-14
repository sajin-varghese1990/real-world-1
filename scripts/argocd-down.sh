#!/usr/bin/env bash
# Remove Argo CD and everything it manages (shop-base/shop-db/shop-cache
# Applications, then Argo CD itself). Cluster stays up.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"
kubectl delete -f "${ARGOCD_ROOT_APP}" --ignore-not-found
kubectl delete -f "${ROOT}/argocd/apps" --ignore-not-found
kubectl delete -f "${ARGOCD_INSTALL_DIR}" --ignore-not-found
kubectl delete namespace "${ARGOCD_NAMESPACE}" --ignore-not-found
echo "Argo CD removed. Recreate with ./scripts/argocd-up.sh"
