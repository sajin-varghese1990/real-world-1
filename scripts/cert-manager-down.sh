#!/usr/bin/env bash
# Remove cert-manager and the self-signed CA/ClusterIssuer. Any Certificate
# resources in other namespaces (e.g. k8s/base) that reference the deleted
# ClusterIssuer will stop renewing, but their already-issued TLS Secrets stay
# put. Cluster, Argo CD/Rollouts, and the shop apps stay up.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"
kubectl delete -f "${CERT_MANAGER_PKI_DIR}" --ignore-not-found
kubectl delete -f "${CERT_MANAGER_INSTALL_DIR}" --ignore-not-found
kubectl delete namespace "${CERT_MANAGER_NAMESPACE}" --ignore-not-found
echo "cert-manager removed. Recreate with ./scripts/cert-manager-up.sh"
