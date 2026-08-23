# k8s-lab — Kubernetes fundamentals on a local multi-node cluster

Learning project: a three-node Kubernetes cluster running locally with kind,
used to practice core workload and networking objects.

## Cluster

Created with kind: one control-plane node and two workers, so that pod
scheduling across nodes can actually be observed.

    kind create cluster --config kind-config.yaml

## Manifests

- kind-config.yaml — three-node cluster definition
- deployment.yaml — nginx Deployment, 3 replicas, pod name injected through the Downward API
- service.yaml — ClusterIP Service load balancing across the pods by label selector

## Usage

    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml
    kubectl get pods -o wide
    kubectl get endpointslices

Test load balancing from inside the cluster:

    kubectl run tester --image=nicolaka/netshoot -it --rm -- /bin/bash
    for i in $(seq 1 9); do curl -s web-svc; done

Each pod serves its own name, so the responses show the traffic being
distributed across replicas.

## Concepts practiced

Declarative manifests and continuous reconciliation, pods and scheduling,
Deployments and ReplicaSets, labels and selectors, Services and cluster DNS,
load balancing, rolling updates and rollback.
