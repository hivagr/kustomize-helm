.PHONY: help

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Cluster names
CLUSTER_1 := dev-cluster-1
CLUSTER_2 := staging-cluster-1
CLUSTER_3 := prod-cluster-1

create-clusters: ## Create three kind clusters
	kind create cluster --name $(CLUSTER_1)
	kind create cluster --name $(CLUSTER_2)
	kind create cluster --name $(CLUSTER_3)

install-argocd: ## Install ArgoCD on staging & prod clusters
	kubectl config use-context kind-$(CLUSTER_2)

	@echo "👉 Adding Helm repos..."
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update

	@echo "📦 Installing ArgoCD..."
	helm install argocd argo/argo-cd \
		--namespace argocd --create-namespace -f kind/argocd/values.yaml
	@echo "✅ ArgoCD installed."

	kubectl config use-context kind-$(CLUSTER_3)

	@echo "👉 Adding Helm repos..."
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update

	@echo "📦 Installing ArgoCD..."
	helm install argocd argo/argo-cd \
		--namespace argocd --create-namespace -f kind/argocd/values.yaml
	@echo "✅ ArgoCD installed."

port-forward-argocd: ## Port-forward services to localhost:3301 and localhost:3302
	kubectl config use-context kind-$(CLUSTER_2)
	kubectl -n argocd port-forward service/argocd-server 3301:443 &

	kubectl config use-context kind-$(CLUSTER_3)
	kubectl -n argocd port-forward service/argocd-server 3302:443 &

delete-argocd: ## Delete ArgoCD on both clusters
	kubectl config use-context kind-$(CLUSTER_2)
	helm -n argocd uninstall argocd

	kubectl config use-context kind-$(CLUSTER_3)
	helm -n argocd uninstall argocd

clean: ## Clean up: Delete all three clusters
	kind delete cluster --name $(CLUSTER_1)
	kind delete cluster --name $(CLUSTER_2)
	kind delete cluster --name $(CLUSTER_3)
