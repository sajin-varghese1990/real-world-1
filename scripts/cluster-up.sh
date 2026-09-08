#!/usr/bin/env bash
# Recreate the 3-node Calico minikube cluster (profile localk8s) and enable Ingress.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

echo "Starting minikube profile ${MINIKUBE_PROFILE} (${NODES} nodes, cni=${CNI}, k8s=${K8S_VERSION})"
minikube start \
  -p "${MINIKUBE_PROFILE}" \
  --driver="${DRIVER}" \
  --nodes="${NODES}" \
  --cni="${CNI}" \
  --kubernetes-version="${K8S_VERSION}"

kubectl config use-context "${K8S_CONTEXT}"
kubectl get nodes -o wide

echo "Enabling ingress addon"
minikube -p "${MINIKUBE_PROFILE}" addons enable ingress
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s

echo "Cluster is ready. Next: ./scripts/app-up.sh"
echo "Then keep this running in another terminal: minikube -p ${MINIKUBE_PROFILE} tunnel"
