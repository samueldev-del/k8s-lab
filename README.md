# k8s-lab — Kubernetes fundamentals on a local multi-node cluster

Learning project: a three-node Kubernetes cluster running locally with kind,
used to practice core workload, scheduling and networking objects.

## Cluster

One control-plane node and two workers, so pod scheduling across nodes can be
observed. The control-plane carries the ingress-ready label and host port
mappings, so the ingress controller lands there and is reachable from the host.

    kind create cluster --config kind-config.yaml
    kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
    kubectl wait --namespace ingress-nginx --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller --timeout=180s
    kubectl apply -f manifests/

Add this line to /etc/hosts:

    127.0.0.1 web.localdev.me

## Manifests

- kind-config.yaml — three-node cluster, ingress-ready label, host port mappings
- manifests/deployment.yaml — web Deployment, 3 replicas, topology spread constraints, resource requests and limits
- manifests/api.yaml — second Deployment and Service, 2 replicas
- manifests/service.yaml — ClusterIP Service for the web app
- manifests/service-nodeport.yaml — NodePort Service, exposed on host port 30080
- manifests/ingress.yaml — path-based routing for both applications

## Routing

    curl http://web.localdev.me:8080/       # web deployment
    curl http://web.localdev.me:8080/api    # api deployment
    curl http://localhost:30080             # web deployment through NodePort

Each pod serves its own name through the Downward API, so repeated requests
show traffic being distributed across replicas.

## Concepts practiced

Declarative manifests and continuous reconciliation, pods and scheduling,
Deployments and ReplicaSets, labels and selectors, topology spread constraints,
resource requests and limits, Services (ClusterIP and NodePort), cluster DNS,
Ingress with path-based routing, rolling updates and rollback.
