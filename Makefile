
.PHONY: delete.lab
delete.lab: ## Delete the Kubewarden lab environment
	k3d cluster delete kubewarden-lab

.PHONY: create.lab
create.lab: ## Create a Kubewarden lab environment
	k3d cluster create kubewarden-lab

.PHONY: reset.kubewarden 
reset.lab: delete.lab create.lab # Delete and recreate a Kubewarden lab environment
	
.PHONY: config.standalone 
config.standalone: ## Configure a Kubewarden environment
	helmfile apply -f clusters.d/kubewarden.yaml

.PHONY: config.rancher
config.rancher: ## Configure a Rancher environment
	helmfile apply -f clusters.d/rancher.yaml

.PHONY: proxy.grafana
proxy.grafana: ## proxy will create local port-forward to grafana
	echo 'login: admin'
	echo 'password: prom-operator'
	echo 'import 15314'
	kubectl port-forward -n prometheus --address 0.0.0.0 svc/prometheus-grafana 8080:80

.PHONY: proxy.prometheus
proxy.prometheus: ## proxy will create local port-forward to prometheus
	kubectl port-forward -n prometheus --address 0.0.0.0 svc/prometheus-operated 9090

check.metrics:
	kubectl delete pod curlpod --ignore-not-found && kubectl run curlpod -t -i --rm --wait --namespace kubewarden --image curlimages/curl:8.00.1 --restart=Never -- --silent policy-server-default.kubewarden.svc.cluster.local:8080/metrics


.PHONY: help
help: ## Show this Makefile's help
    @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
