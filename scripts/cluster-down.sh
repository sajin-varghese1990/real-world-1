#!/usr/bin/env bash
# Delete the entire minikube profile (nodes, addons, loaded images).
# App YAML in this repo is not deleted.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

echo "Deleting minikube profile ${MINIKUBE_PROFILE}"
minikube delete -p "${MINIKUBE_PROFILE}"
echo "Cluster gone. Recreate with ./scripts/cluster-up.sh && ./scripts/app-up.sh"
