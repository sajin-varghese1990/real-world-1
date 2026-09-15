#!/usr/bin/env bash
# Remove Argo Rollouts (controller + CRDs). Deleting the CRDs also deletes any
# Rollout/AnalysisTemplate/etc. objects still using them. Cluster, Argo CD,
# and the shop apps' Deployments/Services/Ingress stay up.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"
kubectl delete -f "${ARGO_ROLLOUTS_INSTALL_DIR}" --ignore-not-found
kubectl delete namespace "${ARGO_ROLLOUTS_NAMESPACE}" --ignore-not-found
echo "Argo Rollouts removed. Recreate with ./scripts/argo-rollouts-up.sh"
