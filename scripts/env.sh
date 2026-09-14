# Shared settings for recreate scripts. Source from other scripts; do not run alone.
# Cluster profile (not the default "minikube" profile).

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-localk8s}"
K8S_CONTEXT="${K8S_CONTEXT:-localk8s}"
DRIVER="${DRIVER:-docker}"
NODES="${NODES:-3}"
CNI="${CNI:-calico}"
K8S_VERSION="${K8S_VERSION:-v1.35.1}"
IMAGE="${IMAGE:-shop-frontend:1.3}"
ADMIN_IMAGE="${ADMIN_IMAGE:-shop-admin:1.3}"
DB_NAMESPACE="${DB_NAMESPACE:-shop-db}"
CACHE_NAMESPACE="${CACHE_NAMESPACE:-shop-cache}"
NAMESPACE="${NAMESPACE:-shop}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="${ROOT}/k8s/base"
DB_DIR="${ROOT}/k8s/db"
CACHE_DIR="${ROOT}/k8s/cache"
FRONTEND_DIR="${ROOT}/app/frontend"
ADMIN_DIR="${ROOT}/app/admin"
ARGOCD_INSTALL_DIR="${ROOT}/argocd/install"
ARGOCD_ROOT_APP="${ROOT}/argocd/root-app.yaml"
