#!/usr/bin/env bash
# Remove shop apps and the shop-db namespace (including PVC). Cluster stays up.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"
kubectl delete -f "${K8S_DIR}" --ignore-not-found
kubectl delete -f "${DB_DIR}" --ignore-not-found
kubectl delete pvc --all -n "${DB_NAMESPACE}" --ignore-not-found
kubectl delete namespace "${DB_NAMESPACE}" --ignore-not-found
echo "Shop apps and database removed. Recreate with ./scripts/app-up.sh"
