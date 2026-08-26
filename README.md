# k8s-lab — Kubernetes fundamentals, from raw manifests to a Helm chart

Learning project built on a local three-node kind cluster. The repository shows
the same application twice: first as plain Kubernetes manifests, then packaged
as a Helm chart — which makes the duplication problem, and the reason Helm
exists, visible side by side.

## Cluster

One control-plane node and two workers, so pod scheduling across nodes can be
observed. The control-plane carries the ingress-ready label and host port
mappings, so the ingress controller lands there and is reachable from the host.

    kind create cluster --config kind-config.yaml
    kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
    kubectl wait --namespace ingress-nginx --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller --timeout=180s

Add these lines to /etc/hosts:

    127.0.0.1 web.localdev.me
    127.0.0.1 dev.localdev.me

## Part 1 — Raw manifests

    kubectl apply -f manifests/

- manifests/deployment.yaml — nginx Deployment, topology spread constraints, resource limits, readiness and liveness probes, config mounted from a ConfigMap
- manifests/api.yaml — second Deployment and Service
- manifests/service.yaml — ClusterIP Service
- manifests/service-nodeport.yaml — NodePort Service on host port 30080
- manifests/ingress.yaml — path-based routing between both applications
- manifests/configmap.yaml — page content and environment variables
- manifests/secret.yaml.example — template for the gitignored secret manifest
- manifests/pvc.yaml, manifests/writer.yaml — dynamic volume provisioning
- manifests/statefulset.yaml — StatefulSet with per-replica volumes and a headless Service

The label app: web appears in three files and the image tag in two. Deploying
the same application with different replica counts would mean duplicating the
whole directory.

## Part 2 — The same application as a Helm chart

    helm install web ./chart
    helm install dev ./chart -f chart/values-dev.yaml

Two independent releases from one chart: different replica counts, different
page content, different hostnames, no duplicated files.

- chart/Chart.yaml — chart metadata
- chart/values.yaml — default values
- chart/values-dev.yaml — development overrides
- chart/templates/ — templated Deployment, Service, Ingress and ConfigMap

Notable details: selector labels are kept separate from full labels because a
Deployment selector is immutable; a checksum annotation on the pod template
triggers a rolling update whenever the ConfigMap content changes.

## Useful commands

    helm template web ./chart          # render locally, no cluster contact
    helm install web ./chart --dry-run=server   # server-side validation
    helm history web                   # revision history
    helm rollback web 1                # roll back the whole release
    kubectl rollout status deployment/web-mywebapp

## Concepts practiced

Declarative manifests and continuous reconciliation, pods and scheduling,
Deployments, ReplicaSets and StatefulSets, labels and selectors, topology
spread constraints, resource requests and limits, readiness and liveness
probes, Services (ClusterIP, NodePort, headless), cluster DNS, Ingress with
path-based routing, ConfigMaps and Secrets, persistent volumes and dynamic
provisioning, rolling updates and rollback, Helm charts, templating, values
overrides and release history.
