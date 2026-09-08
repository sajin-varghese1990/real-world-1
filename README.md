# Kubernetes learning lab

Phase 3 of a shop app on a local **3-node minikube** cluster (Calico CNI). Admin writes catalog items to **Postgres in namespace `shop-db`**. The main UI on `/` reads the same table. Reach the UIs through Ingress on `shop.local`.

Later phases reuse this namespace and grow the app (backend, Postgres, NetworkPolicies, HPA, RBAC). See the roadmap in [docs/lessons.md](docs/lessons.md).

## Recreate from this repo (source of truth)

Kubernetes does not remember your app after `minikube delete` or `kubectl delete`. **This git repo** is what persists:

| Persist in git | Recreated at apply time |
| --- | --- |
| [`app/frontend/`](app/frontend/) and [`app/admin/`](app/admin/) | Images `shop-frontend:1.1` and `shop-admin:1.1` |
| [`k8s/base/`](k8s/base/) | Namespace `shop`, Deployments, Services, Ingress, db ConfigMap/Secret |
| [`k8s/db/`](k8s/db/) | Namespace `shop-db`, Postgres Secret, StatefulSet, PVC, Service |
| [`scripts/`](scripts/) (cluster flags, addon, load, apply) | 3-node Calico cluster + ingress addon |

Not stored in git (you already handle this): `/etc/hosts` → `127.0.0.1 shop.local`. Also not stored: the default ServiceAccount and `kube-root-ca.crt` ConfigMap (the API server recreates those).

**Wipe the app only, keep the cluster:**

```bash
./scripts/app-down.sh
./scripts/app-up.sh
```

**Wipe the whole minikube profile and bring it back:**

```bash
./scripts/cluster-down.sh          # minikube delete -p localk8s
./scripts/cluster-up.sh            # 3 nodes, Calico, k8s v1.35.1, ingress addon
./scripts/app-up.sh                # build, load image, apply manifests
```

Then in a **separate** terminal (sudo, leave open):

```bash
minikube -p localk8s tunnel
```

Settings live in [`scripts/env.sh`](scripts/env.sh) (`localk8s`, 3 nodes, Calico, `v1.35.1`).

## Prerequisites

- Docker Desktop (or another minikube driver you already use)
- A **3-node** minikube profile with Calico. This repo was verified against profile **`localk8s`** (`kubectl` context `localk8s`). The default profile named `minikube` may be a different, stopped cluster.

```bash
# if you still need to create a 3-node cluster:
# minikube start -p localk8s --nodes 3 --cni calico
kubectl config use-context localk8s
kubectl get nodes -o wide
```

- Ingress addon on **that** profile:

```bash
minikube -p localk8s addons enable ingress
kubectl get pods -n ingress-nginx
```

## Build and load the image (multi-node)

Do **not** use `eval $(minikube docker-env)` on a multi-node cluster. That only points Docker at the primary node. Build locally and load onto **all** nodes:

```bash
docker build -t shop-frontend:1.1 app/frontend
minikube -p localk8s image load shop-frontend:1.1
```

`imagePullPolicy: IfNotPresent` in the Deployment lets kubelet use the loaded image instead of pulling from a registry.

## Deploy

```bash
kubectl apply -f k8s/base
kubectl rollout status deployment/frontend -n shop
kubectl get pods -n shop -o wide
```

Two frontend pods should become Ready. With 3 nodes they often land on different machines.

## Open in the browser

### Port-forward (easiest on Mac + Docker driver)

This maps Service port 80 to your laptop. Leave the command running, then open [http://127.0.0.1:18080](http://127.0.0.1:18080).

```bash
kubectl port-forward -n shop svc/frontend 18080:80
```

### NodePort

Service `frontend` is type `NodePort` on port **30080**. From **inside** a cluster node this works even when the Mac cannot reach the node IP:

```bash
minikube -p localk8s ssh -- curl -sS http://127.0.0.1:30080/health
```

From the Mac, Docker driver usually needs a helper that **keeps a terminal open**:

```bash
minikube -p localk8s service frontend -n shop
```

`minikube ip` plus `:30080` is often **not** reachable from macOS with the Docker driver.

### Ingress (`shop.local`) without editing `/etc/hosts`

The Ingress object is applied and the controller is running. Send the Host header yourself:

```bash
minikube -p localk8s ssh -- 'curl -sS -H "Host: shop.local" http://127.0.0.1/health'
```

To type `http://shop.local` in a browser later, you would add a hosts entry (skipped for now) or run `minikube -p localk8s tunnel` and point `shop.local` at `127.0.0.1`.

## Useful commands

```bash
kubectl get ns shop
kubectl get deploy,svc,ingress -n shop
kubectl describe ingress frontend -n shop
kubectl logs -n shop -l app=frontend --tail=50
kubectl exec -n shop deploy/frontend -- wget -qO- http://127.0.0.1:8080/api/info
```

## Tear down

App only (cluster stays):

```bash
./scripts/app-down.sh
```

Entire `localk8s` profile:

```bash
./scripts/cluster-down.sh
```

Stop `minikube tunnel` with Ctrl+C in that terminal. `/etc/hosts` is unchanged.
