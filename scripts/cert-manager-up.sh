#!/usr/bin/env bash
# Apply the committed cert-manager manifests, then bootstrap the self-signed
# CA (bootstrap Issuer -> CA Certificate -> CA ClusterIssuer). Cluster, Argo
# CD/Rollouts, and the shop apps are untouched by this script.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

kubectl config use-context "${K8S_CONTEXT}"

echo "Applying cert-manager (namespace ${CERT_MANAGER_NAMESPACE})"
# Server-side apply: same oversized-CRD-schema issue as Argo CD/Rollouts.
kubectl apply --server-side --force-conflicts -f "${CERT_MANAGER_INSTALL_DIR}"
kubectl -n "${CERT_MANAGER_NAMESPACE}" rollout status deploy/cert-manager --timeout=180s
kubectl -n "${CERT_MANAGER_NAMESPACE}" rollout status deploy/cert-manager-webhook --timeout=180s
kubectl -n "${CERT_MANAGER_NAMESPACE}" rollout status deploy/cert-manager-cainjector --timeout=180s

echo "Waiting for the webhook to actually accept requests (not just Ready)"
until kubectl apply --dry-run=server -f "${CERT_MANAGER_PKI_DIR}/00-bootstrap-issuer.yaml" >/dev/null 2>&1; do
  sleep 3
done

echo "Bootstrapping the self-signed CA"
kubectl apply -f "${CERT_MANAGER_PKI_DIR}"
kubectl -n "${CERT_MANAGER_NAMESPACE}" wait --for=condition=Ready certificate/shop-local-ca --timeout=120s

echo
echo "cert-manager is up. ClusterIssuer: shop-local-ca-issuer"
echo "To trust it in your browser (one-time, until you actually wire up a Certificate using it):"
echo "  kubectl -n ${CERT_MANAGER_NAMESPACE} get secret shop-local-ca-tls -o jsonpath='{.data.tls\\.crt}' | base64 -d > /tmp/shop-local-ca.crt"
echo "  open /tmp/shop-local-ca.crt   # then add to Keychain Access and trust it"
