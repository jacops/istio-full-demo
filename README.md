# Istio demonstration

The purpose of this repository is to show benefits of service mesh when running container workloads.

1. Authentication and encryption
2. Authorisation
3. Accounting
4. Record keeping

# Setup
> The exercises can be run on any Kubernetes cluster, though they have been only tested on `minikube`.

All examples have been wrapped with a `Makefile`.

Tasks:
* `make minikube` - start/create a `minikube` cluster
* `make download-istio` - download `Istio` to current directory

# Exercises

All exercises will be based on simple `bookinfo` application, formed with 4 microservices.

## 1. No mesh
Pods can access each other without any restrictions. 

* `make app` - deploy `bookinfo` application
* `make node-port` - expose application on node port
* `make test-non-authenticated-access` - deploy pod in separate namespace and test connection

## 2. Mtls enabled
Istio is deployed. Pods outside the mesh can't access pods inside the mesh.

* `make istio` - deploy `Istio`
* `make app-istio` - deploy ingress gateway and destination rules (+ restart pods to inject sidecars)
* `make test-non-authenticated-access` - deploy pod in separate namespace and test connection 
* `make test-authenticated-access` - get on sidecar and curl using certificates
* `make test-identity` - check identity of sidecar certificate
* `make test-validity` - check validity of sidecar certificate

## 3. Rbac on

* `make istio-rbac` - enable RBAC in default namespace
* `make istio-rbac-service-level` - allow access to services

## 4. Observability

* `make kiali` - open `kiali` dashboard
* `make jeager` - open `jeager` dashboard
* `make grafana` - open `grafana` dashboard
* `make app-istio-break-details-service` - make `details` service unavailable

## 5. Control egress

* `make sleep-pod` - deploy test pod in the mesh for curl requests 
* `make test-outbound-google` -  curl https://www.google.com
* `make test-outbound-wikipedia` - curl https://en.wikipedia.org/wiki/Main_Page 
* `make istio-block-outbound` - Block all outbound traffic by default
* `make istio-allow-google` - Allow only access to https://www.google.com