# Lessons: Phase 1 objects

This lab maps each Kubernetes object you applied to a CKA-style idea and a command to try. Stay in namespace `shop` unless noted.

## Namespace

A namespace is a scope for names (Deployments, Services, pods). Cluster-scoped objects (Nodes, PersistentVolumes) are not inside it.

```bash
kubectl get ns shop
kubectl get all -n shop
```

Why a custom namespace: it matches how real teams isolate apps, and later NetworkPolicies / RBAC bind to `shop` instead of `default`.

## Labels and selectors

The Deployment template and the Service share:

- `app: frontend`
- `tier: web`

The Service **selector** must match **pod** labels, not Deployment metadata labels.

```bash
kubectl get pods -n shop --show-labels
kubectl get pods -n shop -l app=frontend,tier=web
```

## Deployment and ReplicaSet

A Deployment owns a ReplicaSet, which keeps `replicas: 2` pods running. Deleting a pod should recreate it.

```bash
kubectl get deploy,rs,pods -n shop
kubectl delete pod -n shop -l app=frontend --field-selector=status.phase=Running | head
# wait, then:
kubectl get pods -n shop
```

`kubectl get pods -n shop -o wide` shows **which node** each replica landed on. With three nodes you often see spread without extra affinity (Phase 10 will make that explicit).

## Pod identity (`/api/info`)

The container reads:

- `HOSTNAME` — Kubernetes sets this to the pod name
- `NODE_NAME` — `fieldRef: spec.nodeName`
- `POD_NAMESPACE` — `fieldRef: metadata.namespace`

Refresh the page a few times. The Service load-balances, so the hostname can change between the two replicas.

```bash
kubectl exec -n shop deploy/frontend -- wget -qO- http://127.0.0.1:8080/api/info
```

## Service: ClusterIP + NodePort

`type: NodePort` still allocates a **ClusterIP**. Other pods can use DNS:

`frontend.shop.svc.cluster.local` (or `frontend.shop.svc`) on port **80**, which maps to container port **8080**.

NodePort **30080** is the same Service, exposed on every node. That is your first browser path.

```bash
kubectl get svc frontend -n shop -o yaml
kubectl get endpointslices -n shop
```

Endpoints should list both pod IPs once they are Ready.

## Ingress

Ingress is L7 HTTP routing. The controller (nginx addon) matches `Host: shop.local` and proxies to Service `frontend:80`.

```bash
kubectl get ingress -n shop
kubectl describe ingress frontend -n shop
kubectl get pods -n ingress-nginx
```

`ingressClassName: nginx` selects the minikube ingress addon.

## Path-based routing (same Ingress)

One Ingress object, one host (`shop.local`), two paths:

- Prefix `/admin` → Service `admin` (ClusterIP only)
- Prefix `/` → Service `frontend`

ingress-nginx picks the **longest matching prefix**. `/admin/health` is not sent to the frontend even though `/` also matches.

There is **no** `rewrite-target` annotation. That annotation applies to the whole Ingress and would break `/`. The admin app therefore serves routes under `/admin` itself (`BASE_PATH`).

```bash
kubectl describe ingress frontend -n shop
curl -sS http://shop.local/health
curl -sS http://shop.local/admin/health
```

Probes for admin use `/admin/health` because kubelet talks to the **pod** directly, not through Ingress.

## Two-tier data: Postgres in `shop-db`

Apps stay in `shop`. The database is a **different namespace** so you practice cross-namespace DNS:

`postgres.shop-db.svc.cluster.local:5432`

A Service IP is only visible inside the cluster. Ingress does **not** expose Postgres.

Secrets do **not** cross namespaces. `k8s/db/01-secret.yaml` is for the StatefulSet; `k8s/base/07-db-secret.yaml` is the password copy for frontend/admin. Host/user/db names are a ConfigMap (`db-config`).

```bash
kubectl get pods,svc,sts,pvc -n shop-db
kubectl exec -n shop deploy/frontend -- wget -qO- http://127.0.0.1:8080/api/items
```

StatefulSet + PVC: deleting the pod keeps the catalog. `./scripts/app-down.sh` deletes the PVC too so a recreate starts empty.

## Probes

Readiness: kubelet must see `/health` before adding the pod to Endpoints (traffic).

Liveness: repeated failure restarts the container.

```bash
kubectl get pods -n shop -o jsonpath='{range .items[*]}{.metadata.name}{" ready="}{.status.containerStatuses[0].ready}{"\n"}{end}'
```

## Images on multi-node minikube

`minikube -p localk8s image load shop-frontend:1.0` copies the image into each node’s container runtime. Combined with `imagePullPolicy: IfNotPresent`, pods start without a public registry. Always pass `-p localk8s` so you do not load into the default `minikube` profile.

If a pod is `ErrImagePull` / `ImagePullBackOff`, the image is missing on **that** node:

```bash
minikube -p localk8s image ls | grep shop-frontend
minikube -p localk8s image load shop-frontend:1.0
```

## Roadmap (later sessions)

Same `shop` namespace; do not throw Phase 1 away.

| Phase | App change | Concepts |
| --- | --- | --- |
| 2 | Admin app on `/admin` (same Ingress) | Extra Deployment/Service, path-based Ingress, ClusterIP-only |
| 2b | Split `/api` into a backend Deployment; frontend calls `http://backend.shop.svc` | In-cluster DNS |
| 3 | Postgres in `shop-db`; admin writes, shop reads | Cross-namespace DNS, Secret, ConfigMap, StatefulSet, PVC |
| 4 | ConfigMap; tighten probes; requests/limits | ConfigMap, QoS |
| 5 | Calico NetworkPolicies: frontend → backend → db only | NetworkPolicy, default-deny |
| 6 | metrics-server; HPA on frontend | metrics-server, HPA |
| 7 | App ServiceAccount + Role/RoleBinding | RBAC |
| 8 | Nightly report CronJob | Jobs / CronJobs |
| 9 | Rolling update and rollback of `shop-frontend` | rollout, revision history |
| 10 | podAntiAffinity / topology spread across 3 nodes | scheduling, optional taints |
