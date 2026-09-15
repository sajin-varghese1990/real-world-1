#!/usr/bin/env bash
# Apply the committed Argo Rollouts manifests (controller + CRDs). Cluster,
# Argo CD, and the shop apps are untouched by this script.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"

echo "Applying Argo Rollouts (namespace ${ARGO_ROLLOUTS_NAMESPACE})"
# Server-side apply: same oversized-CRD-schema issue we hit installing Argo CD
# (last-applied-configuration annotation exceeds etcd's 256KB annotation limit).
kubectl apply --server-side --force-conflicts -f "${ARGO_ROLLOUTS_INSTALL_DIR}"
kubectl -n "${ARGO_ROLLOUTS_NAMESPACE}" rollout status deploy/argo-rollouts --timeout=180s

echo
echo "Argo Rollouts is up. Verify the CRDs:"
echo "  kubectl get crd | grep argoproj.io"
echo "Install the kubectl plugin for get/promote/abort/dashboard (one-time, local):"
echo "  brew install argoproj/tap/kubectl-argo-rollouts"
