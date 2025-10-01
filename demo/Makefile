# ==============================================================================
# Configuration Variables
# ==============================================================================
CLUSTER_NAME ?= capi-quickstart
K8S_VERSION ?= v1.34.0
CAPI_VERSION ?= v1.11.1
KIND_VERSION ?= v0.27.0
CALICO_VERSION ?= v3.26.1
CNI_MANIFEST ?= https://raw.githubusercontent.com/projectcalico/calico/$(CALICO_VERSION)/manifests/calico.yaml

# Cluster Workload Sizing
CP_COUNT_DEV ?= 1
WORKER_COUNT_DEV ?= 1
CP_COUNT_HA ?= 3
WORKER_COUNT_HA ?= 3

# File Paths
KUBECONFIG_FILE := $(CLUSTER_NAME).kubeconfig
DEV_MANIFEST := $(CLUSTER_NAME)-dev.yaml
HA_MANIFEST := $(CLUSTER_NAME)-ha.yaml
KIND_CONFIG_FILE := kind-cluster-with-extramounts.yaml

# Context for the Management Cluster
KIND_CONTEXT := kind-kind
KUBECONFIG_PATH := $$HOME/.kube/config

# ==============================================================================
# MAIN TARGETS
# ==============================================================================

.PHONY: all setup init deploy scale_worker scale_ha cleanup check_nodes describe_cluster capi_resources

all: setup init deploy check_nodes

# ------------------------------------------------------------------------------
# 1. PREREQUISITES SETUP
# ------------------------------------------------------------------------------

setup: prereqs sysctl kind_cluster_up capi_init
	@echo "✅ Setup complete: Management Cluster (kind) initialized."

prereqs: clusterctl kind kubectl
	@echo "✅ clusterctl, kind, and kubectl are installed."

clusterctl:
	@echo "➡️ Installing clusterctl..."
	curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v$(CAPI_VERSION)/clusterctl-linux-amd64 -o clusterctl
	sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
	rm clusterctl

kind:
	@echo "➡️ Installing kind..."
	[ $$(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v$(KIND_VERSION)/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/kind

kubectl:
	@echo "➡️ Installing kubectl..."
	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

sysctl:
	@echo "➡️ Configuring Docker limits (fs.inotify)..."
	@echo "fs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/99-docker-limits.conf > /dev/null
	@echo "fs.inotify.max_user_instances = 512" | sudo tee -a /etc/sysctl.d/99-docker-limits.conf > /dev/null
	sudo sysctl -p /etc/sysctl.d/99-docker-limits.conf
	@echo "✅ Docker limits updated."

# ------------------------------------------------------------------------------
# 2. MANAGEMENT CLUSTER (Fix applied here)
# ------------------------------------------------------------------------------

kind_cluster_up:
	@echo "➡️ Creating 'kind' management cluster..."
	kind create cluster --config $(KIND_CONFIG_FILE)
	# Explicitly set the context for subsequent kubectl/clusterctl calls
	kubectl config use-context $(KIND_CONTEXT)

capi_init:
	@echo "➡️ Initializing CAPI (Docker Infrastructure)..."
	# Use explicit kubeconfig and context to ensure cluster connection
	export CLUSTER_TOPOLOGY=true; \
	clusterctl init --infrastructure docker --kubeconfig=$(KUBECONFIG_PATH)
	@echo "✅ CAPI initialized."

init: kind_cluster_up capi_init

# ------------------------------------------------------------------------------
# 3. DEPLOYMENT AND CNI (Fix applied here)
# ------------------------------------------------------------------------------

deploy: generate_dev_manifest apply_manifest wait_for_cluster get_kubeconfig install_cni
	@echo "✅ Workload Cluster $(CLUSTER_NAME) deployed and CNI installed. Wait for node provisioning."

wait_for_cluster:
	@echo "⏳ Waiting for 30 seconds for the workload cluster provisioning to start..."
	sleep 30
	@echo "✅ Wait finished. Attempting to retrieve kubeconfig."

generate_dev_manifest:
	@echo "➡️ Generating Workload Cluster manifest (1CP, 1 Worker)..."
	# Use explicit kubeconfig and context for generating manifest
	clusterctl generate cluster $(CLUSTER_NAME) --flavor development \
	  --kubernetes-version $(K8S_VERSION) \
	  --control-plane-machine-count=$(CP_COUNT_DEV) \
	  --worker-machine-count=$(WORKER_COUNT_DEV) \
	  --kubeconfig=$(KUBECONFIG_PATH) \
	  > $(DEV_MANIFEST)

apply_manifest:
	@echo "➡️ Applying manifest to the Management Cluster..."
	kubectl apply -f $(DEV_MANIFEST)

get_kubeconfig:
	@echo "➡️ Retrieving kubeconfig for $(CLUSTER_NAME)..."
	# Use explicit kubeconfig and context for retrieving kubeconfig
	clusterctl get kubeconfig $(CLUSTER_NAME) --kubeconfig=$(KUBECONFIG_PATH) > $(KUBECONFIG_FILE)

install_cni:
	@echo "➡️ Installing CNI (Calico) on the Workload Cluster..."
	kubectl --kubeconfig=$(KUBECONFIG_FILE) apply -f $(CNI_MANIFEST)
	@echo "✅ CNI installed."

# ------------------------------------------------------------------------------
# 4. SCALING AND UPDATE (DEMOS 2 & 3 - Fix applied here)
# ------------------------------------------------------------------------------

scale_worker: generate_worker_scale apply_worker_scale check_nodes
	@echo "✅ Workload scaling to $(WORKER_COUNT_HA) workers complete. Verify nodes."

generate_worker_scale:
	@echo "➡️ Generating manifest for 3 Workers (1CP, 3 Workers)..."
	clusterctl generate cluster $(CLUSTER_NAME) --flavor development \
	  --kubernetes-version $(K8S_VERSION) \
	  --control-plane-machine-count=$(CP_COUNT_DEV) \
	  --worker-machine-count=$(WORKER_COUNT_HA) \
	  --kubeconfig=$(KUBECONFIG_PATH) \
	  > $(HA_MANIFEST)

apply_worker_scale:
	@echo "➡️ Applying manifest for Worker Scaling..."
	kubectl apply -f $(HA_MANIFEST)
	@echo "⏳ Wait a few minutes for the new worker nodes to be provisioned."

scale_ha: generate_ha_manifest apply_ha_manifest check_nodes
	@echo "✅ Workload scaling to HA (3CP, 3 Workers) complete. Verify nodes."

generate_ha_manifest:
	@echo "➡️ Generating manifest for HA Cluster (3CP, 3 Workers)..."
	clusterctl generate cluster $(CLUSTER_NAME) --flavor development \
	  --kubernetes-version $(K8S_VERSION) \
	  --control-plane-machine-count=$(CP_COUNT_HA) \
	  --worker-machine-count=$(WORKER_COUNT_HA) \
	  --kubeconfig=$(KUBECONFIG_PATH) \
	  > $(HA_MANIFEST)

apply_ha_manifest:
	@echo "➡️ Applying manifest for HA Scaling (Control Plane and Workers)..."
	kubectl apply -f $(HA_MANIFEST)
	@echo "⏳ Wait a few minutes for the new CP and Worker nodes to be provisioned."

# ------------------------------------------------------------------------------
# 5. VERIFICATION AND CLEANUP
# ------------------------------------------------------------------------------

check_nodes: get_kubeconfig
	@echo "➡️ Node status in $(CLUSTER_NAME) (might require waiting):"
	kubectl get nodes --kubeconfig=$(KUBECONFIG_FILE) -o wide

describe_cluster:
	@echo "➡️ CAPI details for $(CLUSTER_NAME):"
	# Use explicit kubeconfig and context for describe
	clusterctl describe cluster $(CLUSTER_NAME) --kubeconfig=$(KUBECONFIG_PATH)

capi_resources:
	@echo "➡️ CAPI resources in the Management Cluster:"
	kubectl get cluster,machines,machinedeployments,kubeadmcontrolplanes

cleanup: cleanup_workload cleanup_management
	@echo "🗑️ Cleanup complete."

cleanup_workload:
	@echo "➡️ Deleting Workload Cluster $(CLUSTER_NAME)..."
	# Use explicit kubeconfig and context for deletion
	-kubectl delete cluster $(CLUSTER_NAME) --kubeconfig=$(KUBECONFIG_PATH)
	-rm -f $(KUBECONFIG_FILE) $(DEV_MANIFEST) $(HA_MANIFEST)

cleanup_management:
	@echo "➡️ Deleting 'kind' Management Cluster..."
	kind delete cluster