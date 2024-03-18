K3S_VERSION="v1.27.11-k3s1"

.PHONY: lab_create
lab_create: ## Create a Kubewarden lab environment
	@k3d cluster create --image rancher/k3s:$(K3S_VERSION) kubewarden-lab

.PHONY: lab_delete
lab_delete: ## Delete the Kubewarden lab environment
	@k3d cluster delete kubewarden-lab
	
.PHONY: lab_start
lab_start: ## Start the Kubewarden lab environment, if already created
	@k3d cluster start kubewarden-lab
	
.PHONY: lab_stop
lab_stop: ## Stop the Kubewarden lab environment. Restart with lab_start
	@k3d cluster stop kubewarden-lab

.PHONY: reset_kubewarden
lab_reset: lab_delete lab_create ## Delete and recreate a Kubewarden lab environment
	
.PHONY: config_standalone
config_standalone: ## Configure a Kubewarden environment
	@helmfile apply -f clusters.d/kubewarden.yaml

.PHONY: config_rancher
config_rancher: ## Configure a Rancher environment
	@helmfile apply -f clusters.d/rancher.yaml

.PHONY: grafana_proxy
grafana_proxy: ## proxy will create local port-forward to grafana
	@echo 'login: admin'
	@echo 'password: prom-operator'
	@echo 'import 15314'
	@kubectl port-forward -n prometheus --address 0.0.0.0 svc/prometheus-grafana 8080:80

.PHONY: prometheus_proxy
prometheus_proxy: ## proxy will create local port-forward to prometheus
	@kubectl port-forward -n prometheus --address 0.0.0.0 svc/prometheus-operated 9090

.PHONY: check_metrics
check_metrics:
	@kubectl delete pod curlpod --ignore-not-found && kubectl run curlpod -t -i --rm --wait --namespace kubewarden --image curlimages/curl:8.00.1 --restart=Never -- --silent policy-server-default.kubewarden.svc.cluster.local:8080/metrics

.PHONY: help
help: ## Show this Makefile's help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
