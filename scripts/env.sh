# Shared settings for recreate scripts. Source from other scripts; do not run alone.
# Cluster profile (not the default "minikube" profile).

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-localk8s}"
K8S_CONTEXT="${K8S_CONTEXT:-localk8s}"
DRIVER="${DRIVER:-docker}"
NODES="${NODES:-3}"
CNI="${CNI:-calico}"
K8S_VERSION="${K8S_VERSION:-v1.35.1}"
IMAGE="${IMAGE:-shop-frontend:1.1}"
ADMIN_IMAGE="${ADMIN_IMAGE:-shop-admin:1.1}"
DB_NAMESPACE="${DB_NAMESPACE:-shop-db}"
NAMESPACE="${NAMESPACE:-shop}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="${ROOT}/k8s/base"
DB_DIR="${ROOT}/k8s/db"
FRONTEND_DIR="${ROOT}/app/frontend"
ADMIN_DIR="${ROOT}/app/admin"
