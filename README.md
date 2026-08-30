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

## Part 3 — Monitoring with Prometheus

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm install prom prometheus-community/prometheus \
      -f monitoring/prometheus-values.yaml \
      --namespace monitoring --create-namespace
    kubectl port-forward -n monitoring svc/prom-prometheus-server 9090:80

Open http://localhost:9090.

- monitoring/prometheus-values.yaml — trimmed chart values plus three alerting rules

The values file disables Alertmanager, Pushgateway and persistence, which keeps
the lab light. It defines alerts on scrape target availability, pods stuck
outside the Running phase, and container memory usage above 200 MiB.

Useful queries:

    up                                                    # scrape health
    sum by (namespace) (kube_pod_status_phase{phase="Running"})
    sum by (pod) (rate(container_cpu_usage_seconds_total{container!=""}[5m]))
    sum by (pod) (container_memory_working_set_bytes{container!=""}) / 1024 / 1024

The container!="" filter matters: cAdvisor exposes one series per container plus
a pod-level total, so omitting it double-counts usage.

## Part 4 — Dashboards with Grafana

    helm repo add grafana https://grafana.github.io/helm-charts
    kubectl create configmap grafana-lab-dashboards \
      --from-file=monitoring/dashboards/lab-overview.json -n monitoring
    helm install grafana grafana/grafana \
      -f monitoring/grafana-values.yaml --namespace monitoring
    kubectl port-forward -n monitoring svc/grafana 3000:80

Open http://localhost:3000 and log in with admin / admin.

- monitoring/grafana-values.yaml — datasource and dashboard provider, both provisioned
- monitoring/dashboards/lab-overview.json — dashboard definition

Nothing is configured through the UI. The Prometheus datasource, the dashboard
provider and the dashboard itself are all declared in files, so deleting the
Grafana pod loses nothing. The dashboard uses a namespace template variable, so
one definition covers every namespace in the cluster.

The "Scrape targets down" panel uses count(up == 0) or vector(0): without the
fallback the panel would render "No data" when nothing is down, which reads as a
broken query rather than a healthy cluster.
