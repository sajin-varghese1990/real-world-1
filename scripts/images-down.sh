#!/usr/bin/env bash
# Remove shop app images from minikube nodes and Docker Desktop.
# Does not delete cluster objects (use app-down.sh) or postgres:16-alpine
# unless you set IMAGES_DOWN_POSTGRES=1.
#
# If shop pods are still running, they may go ImagePullBackOff after this.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

remove_one() {
  local img="$1"
  echo "Removing ${img} from minikube profile ${MINIKUBE_PROFILE}"
  if ! minikube -p "${MINIKUBE_PROFILE}" image rm "${img}" 2>/dev/null \
    && ! minikube -p "${MINIKUBE_PROFILE}" image rm "docker.io/library/${img}" 2>/dev/null; then
    echo "  (not on minikube, skipped)"
  fi
  echo "Removing ${img} from Docker Desktop"
  if ! docker image rm "${img}" 2>/dev/null \
    && ! docker image rm "docker.io/library/${img}" 2>/dev/null; then
    echo "  (not on Docker Desktop, skipped)"
  fi
}

# Env tags plus older lab tags that may still sit on the nodes.
for img in \
  "${IMAGE}" \
  "${ADMIN_IMAGE}" \
  shop-frontend:1.0 \
  shop-frontend:1.1 \
  shop-frontend:1.2 \
  shop-admin:1.0 \
  shop-admin:1.1
do
  remove_one "${img}"
done

if [[ "${IMAGES_DOWN_POSTGRES:-}" == "1" ]]; then
  remove_one postgres:16-alpine
fi

echo
echo "Done. Remaining shop-related images:"
minikube -p "${MINIKUBE_PROFILE}" image ls 2>/dev/null | grep -E 'shop-frontend|shop-admin|postgres:16' || true
docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'shop-frontend|shop-admin|^postgres:16' || true
echo
echo "Rebuild with ./scripts/app-up.sh"
