CLUSTER_NAME=istio-demo
ISTIO_VERSION=1.3.0

setup:
	cp -n .env.dist .env
	cp -n docker-compose.local.yml.dist docker-compose.local.yml

download-istio:
	curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$(ISTIO_VERSION) sh -

app:
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/platform/kube/bookinfo.yaml

istio:
	kubectl apply -f istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio-init/files
	sleep 10
	kubectl apply -f istio-$(ISTIO_VERSION)/install/kubernetes/istio-demo-auth.yaml

delete-istio:
	kubectl delete -f istio-$(ISTIO_VERSION)/install/kubernetes/istio-demo-auth.yaml

delete-app:
	kubectl delete ns bookinfo

app-istio:
	kubectl label namespace default istio-injection=enabled --overwrite
	kubectl delete pods --all &
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/networking/bookinfo-gateway.yaml
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/networking/destination-rule-all-mtls.yaml
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/networking/virtual-service-details-v2.yaml
	@echo "http://$(shell minikube -p $(CLUSTER_NAME) ip):$(shell kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')/productpage"

node-port:
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/platform/kube/productpage-nodeport.yaml
	@echo "$(shell minikube -p $(CLUSTER_NAME) service productpage --url)/productpage"

test-non-authenticated-access:
	kubectl create ns test --dry-run -o yaml | kubectl apply -f -
	kubectl run -n test test-access --image byrnedo/alpine-curl -it --rm --restart="Never" -- http://reviews.default:9080/reviews/0 -v

test-access:
	kubectl exec $(shell kubectl get pod -l app=productpage -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://reviews.default:9080/reviews/0 -o /dev/null -s -w '%{http_code}\n' --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k

test-access-no-certs:
	kubectl exec $(shell kubectl get pod -l app=productpage -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://reviews.default:9080/reviews/0 -o /dev/null -s -w '%{http_code}\n' -k

test-identity:
	kubectl exec $(shell kubectl get pod -l app=productpage -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1

test-validity:
	kubectl exec $(shell kubectl get pod -l app=productpage -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout | grep Validity -A 2

istio-rbac:
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml

istio-rbac-service-level:
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/platform/kube/rbac/productpage-policy.yaml
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/bookinfo/platform/kube/rbac/ratings-policy.yaml

sleep-pod:
	kubectl apply -f istio-$(ISTIO_VERSION)/samples/sleep/sleep.yaml

test-outbound-google:
	kubectl exec -it $(shell kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -I https://www.google.com | grep  "HTTP/"

test-outbound-wikipedia:
	kubectl exec -it $(shell kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -I https://en.wikipedia.org/wiki/Main_Page | grep  "HTTP/"

istio-block-outbound:
	kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -

istio-allow-google:
	kubectl apply -f manifests/google-service-entry.yaml

minikube:
	minikube -p $(CLUSTER_NAME) start --memory=16384 --cpus=4

minikube-ip:
	@minikube -p $(CLUSTER_NAME) ip