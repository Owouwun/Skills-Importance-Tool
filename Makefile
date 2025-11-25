CLUSTER_NAME := skill-importance
FRONTEND_PORT := 3000
BACKEND_PORT := 8080
CONTROLLERS_NAMESPACE := default

.PHONY: all check_deps setup deploy wait_for_pods forward cleanup install_traefik

all: check_deps setup deploy wait_for_pods forward

check_deps:
	@echo "🔍 Check dependencies..."
	@command -v kind >/dev/null 2>&1 || { echo >&2 "❌ Error: 'kind' is not installed. Install kind to continue."; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo >&2 "❌ Error: 'kubectl' is not installed. Install kubectl to continue."; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo >&2 "❌ Error: 'helm' is not installed. Install helm to continue."; exit 1; }
	@echo "✅ All dependencies are installed."

setup:
	@echo "✨ Updating Helm repositories..."
	helm repo add traefik https://traefik.github.io/charts 2>/dev/null || true
	helm repo update

deploy:
	@echo "☸️ Step 1: Creating cluster $(CLUSTER_NAME)..."
	kind create cluster --name $(CLUSTER_NAME) --config ./config.yaml

	@echo "🕹️ Step 2: Applying controllers..."
	kubectl apply -f ./controllers/

	@echo "🦫 Step 3: Installing Traefik..."
	helm install traefik traefik/traefik --namespace traefik --set "service.type=NodePort" --create-namespace

	@echo "🐅 Step 4: Applying CNI plugin Calico..."
	kubectl apply -f https://docs.tigera.io/calico/latest/manifests/calico.yaml

wait_for_pods:
	@echo "⏳ Waiting for pods to be ready..."
	kubectl rollout status --watch --timeout=300s ds/calico-node -n kube-system
	kubectl rollout status --watch --timeout=300s statefulset/mongo-statefulset
	kubectl wait --for=condition=Available deployment --namespace=$(CONTROLLERS_NAMESPACE) --all --timeout=300s
	@echo "✅ All pods are ready!"

make_forward_script_executable:
	chmod +x ./scripts/port-forward.sh

forward: make_forward_script_executable
	@./scripts/port-forward.sh $(FRONTEND_PORT) $(BACKEND_PORT)
	@echo "🎉 Deployment complete!"
	@echo "--------------------------------------------------------"
	@echo "💡 Open http://localhost:${FRONTEND_PORT} in your browser."
	@echo "--------------------------------------------------------"

cleanup:
	@echo "Deleting cluster $(CLUSTER_NAME)."
	kind delete cluster --name $(CLUSTER_NAME)
	@pkill -f 'kubectl port-forward' 2>/dev/null || true
	@echo "Cleanup is finished."