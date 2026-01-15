.PHONY: help

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Cluster names
CLUSTER_1 := kind-cluster-1
CLUSTER_2 := kind-cluster-2

create-clusters: ## Create two kind clusters
	kind create cluster --name $(CLUSTER_1)
	kind create cluster --name $(CLUSTER_2)

install-argocd: ## Install ArgoCD on both clusters
	kubectl config use-context kind-$(CLUSTER_1)
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

	kubectl config use-context kind-$(CLUSTER_2)
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

port-forward-argocd: ## Port-forward services to localhost:3301 and localhost:3302
	kubectl config use-context kind-$(CLUSTER_1)
	kubectl -n argocd port-forward service/argocd-server 3301:80 &

	kubectl config use-context kind-$(CLUSTER_2)
	kubectl -n argocd port-forward service/argocd-server 3302:80 &

delete-argocd: ## Delete ArgoCD on both clusters
	kubectl config use-context kind-$(CLUSTER_1)
	kubectl delete namespace argocd

	kubectl config use-context kind-$(CLUSTER_2)
	kubectl delete namespace argocd

get-argocd-password: ## Get ArgoCD admin password for both clusters
	@echo "ArgoCD admin password for $(CLUSTER_1):"
	kubectl config use-context kind-$(CLUSTER_1)
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

	@echo "ArgoCD admin password for $(CLUSTER_2):"
	kubectl config use-context kind-$(CLUSTER_2)
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

run-gitea: ## Start Gitea container connected to kind network
	docker run -d --name=gitea --network=kind -p 3000:3000 -p 2222:22 \
		-e USER_UID=1000 -e USER_GID=1000 \
		-v $$(pwd)/gitea:/data \
		-e GITEA__server__DOMAIN=localhost \
		-e GITEA__server__SSH_DOMAIN=localhost \
		-e GITEA__server__HTTP_PORT=3000 \
		-e GITEA__admin__USER_NAME=admin \
		-e GITEA__admin__PASSWORD=admin123 \
		-e GITEA__admin__EMAIL=admin@example.com \
		gitea/gitea:latest

clean: ## Clean up: Delete both clusters
	kind delete cluster --name $(CLUSTER_1)
	kind delete cluster --name $(CLUSTER_2)
