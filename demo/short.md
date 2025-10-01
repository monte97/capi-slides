Certamente\! Modifichiamo il README *shot* per includere l'opzione di usare `make init` se i prerequisiti (come `clusterctl`, `kind`, `kubectl` e le modifiche `sysctl`) sono già soddisfatti.

Ecco la versione concisa e orientata all'uso del `Makefile`:

-----

# CAPI Demo (CAPD) Quickstart 🚀

Minimal guide to deploy and scale a Kubernetes cluster using Cluster API (CAPI) and the Docker Infrastructure Provider (CAPD).

## Requirements

1.  **Docker** (running).
2.  **`kind-cluster-with-extramounts.yaml`** file in the root directory.
3.  **`Makefile`** file in the root directory.

-----

## Execution Options

### Option A: Full Setup (If tools are missing)

This step installs all required tools, configures `sysctl` limits, and initializes the CAPI management cluster.

```bash
make setup
```

### Option B: Quick Init (If tools are already installed)

If you have all prerequisites (`clusterctl`, `kind`, `kubectl`, `sysctl` limits) ready, use this to quickly create and initialize the management cluster.

```bash
make init
```

-----

## Workload Cluster Lifecycle

### 1\. Deploy Workload Cluster (1 CP, 1 Worker)

Deploys the initial Workload Cluster and installs Calico CNI.

```bash
make deploy
```

### 2\. Verify Cluster Status

Check the provisioning status of the nodes in the Workload Cluster.

```bash
make check_nodes
```

*(Wait until all nodes are `Ready`)*

-----

### 3\. Scaling Demos

Scale the cluster using the following targets:

| Goal | Command |
| :--- | :--- |
| **Scale Workers** (1 CP, 3 Workers) | `make scale_worker` |
| **Scale to HA** (3 CP, 3 Workers) | `make scale_ha` |

-----

### 4\. Cleanup

Deletes the Workload Cluster and the Management Cluster (`kind`).

```bash
make cleanup
```