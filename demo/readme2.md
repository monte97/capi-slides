# Demo: Cluster API (CAPI) con Infrastructure Provider Docker (CAPD) 🐳

[**Cluster API (CAPI)**](https://cluster-api.sigs.k8s.io/) è un progetto di Kubernetes che permette di **gestire l'intero ciclo di vita dei cluster Kubernetes** (creazione, aggiornamento, scaling ed eliminazione) utilizzando le **API native di Kubernetes**.

## Concetti Chiave

1.  **Management Cluster (Cluster di Gestione):** Un cluster (in questa demo creato con **Kind**) che ospita i **controller** di CAPI.
2.  **Workload Cluster (Cluster di Lavoro):** Il cluster Kubernetes effettivo che viene creato e gestito da CAPI.
3.  **Provider di Infrastruttura (es. Docker/CAPD):** Componenti che CAPI utilizza per interagire con l'infrastruttura sottostante (container Docker, in questo caso) e creare i nodi macchina.

In breve, CAPI estende il potere di **Kubernetes** per gestire l'infrastruttura stessa, trasformando la gestione dei cluster in un processo **dichiarativo e automatizzato**.

Questa demo illustra il deployment di un cluster Kubernetes (*workload cluster*) utilizzando **Cluster API (CAPI)** e l'**Infrastructure Provider Docker (CAPD)**.

⚠️ **ATTENZIONE:** Questo setup non è inteso per l'uso in ambienti di produzione.

-----

## Requisiti 🛠️

È necessario installare gli strumenti fondamentali per la gestione di Kubernetes e CAPI.

### 1\. **clusterctl** (Strumento CLI di Cluster API)

```bash
# Scarica la versione specificata
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.11.1/clusterctl-linux-amd64 -o clusterctl
# Rendi eseguibile e sposta nel PATH
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
```

### 2\. **kind** (Kubernetes in Docker)

Useremo `kind` per creare il **cluster di gestione** di CAPI.

```bash
# Scarica la versione specificata (adatta all'architettura)
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
# Rendi eseguibile e sposta nel PATH
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### 3\. **kubectl** (Kubernetes CLI)

```bash
# Scarica la versione stabile
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.sio/release/stable.txt)/bin/linux/amd64/kubectl"
# Rendi eseguibile e sposta nel PATH
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 4\. **Configurazione Custom Docker** (Host)

Per prevenire problemi di "Too many open files" o limiti di watch durante l'uso intensivo di Docker e CAPI, aumentiamo i limiti di **`inotify`** sull'HOST.

1.  Crea o modifica un file di configurazione in `/etc/sysctl.d/` (es. `/etc/sysctl.d/99-docker-limits.conf`):

    ```bash
    fs.inotify.max_user_watches = 524288
    fs.inotify.max_user_instances = 512
    ```

2.  Applica la modifica immediatamente:

    ```bash
    sudo sysctl -p /etc/sysctl.d/99-docker-limits.conf
    ```

-----

## Setup Iniziale 🚀

### 1\. Creazione del Cluster di Gestione (Management Cluster)

Il primo passo è creare il **Cluster di Gestione** che ospiterà i *controller* di Cluster API (CAPI). Useremo `kind` per avviarlo, utilizzando un file di configurazione (`kind-cluster-with-extramounts.yaml`) che permette l'accesso al socket Docker dell'host (necessario a CAPD) e definisce un nome specifico.

```bash
kind create cluster --config kind-cluster-with-extramounts.yaml
```

**Output atteso:**

```console
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.32.2) 🖼
...
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
```

> **Nota:** Il context `kind-kind` è ora il nostro **Cluster di Gestione**.

### 2\. Inizializzazione di CAPI

Ora inizializziamo CAPI nel Cluster di Gestione. Questo installa i *Core* e gli *Infrastructure Providers* necessari, in questo caso **Docker (CAPD)**.

```bash
# Abilita la funzionalità sperimentale Cluster Topology
export CLUSTER_TOPOLOGY=true

# Inizializza il cluster di gestione con l'infrastructure provider Docker
clusterctl init --infrastructure docker
```

**Output atteso (estratto):**

```console
...
Installing provider="cluster-api" version="v1.10.6" targetNamespace="capi-system"
Installing provider="bootstrap-kubeadm" version="v1.10.6" targetNamespace="capi-kubeadm-bootstrap-system"
Installing provider="control-plane-kubeadm" version="v1.10.6" targetNamespace="capi-kubeadm-control-plane-system"
Installing provider="infrastructure-docker" version="v1.10.6" targetNamespace="capd-system"

Your management cluster has been initialized successfully!
...
```

-----

## Deployment del Workload Cluster 💻

### 1\. Generazione della Configurazione

Usiamo `clusterctl` per generare i manifest Kubernetes necessari per il **Workload Cluster**. Specifichiamo:

  * Nome: `capi-quickstart`
  * Flavour: `development` (ottimizzato per demo/test)
  * Versione K8s: `v1.34.0`
  * Control Plane: **1** macchina
  * Worker: **1** macchina

<!-- end list -->

```bash
clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.34.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > capi-quickstart.yaml
```

### 2\. Avvio del Workload Cluster

Applichiamo la configurazione al **Cluster di Gestione** (il contesto `kind-kind`). Questo farà partire i *controller* di CAPI che inizieranno a creare i nodi come container Docker.

```bash
kubectl apply -f capi-quickstart.yaml
```

### 3\. Installazione del CNI (Calico)

Perché il cluster diventi funzionale e i pod possano comunicare, è necessario installare un **Container Network Interface (CNI)**. Dobbiamo applicarlo **direttamente sul Workload Cluster**.

1.  **Recupera il kubeconfig** per il Workload Cluster:

    ```bash
    clusterctl get kubeconfig capi-quickstart > capi-quickstart.kubeconfig
    ```

2.  **Applica Calico** usando il nuovo kubeconfig:

    ```bash
    kubectl --kubeconfig=./capi-quickstart.kubeconfig \
      apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
    ```

-----

## Verifiche e Interazione con il Workload Cluster 🔍

### 1\. Stato del Deployment

Controlliamo l'avanzamento della creazione del Workload Cluster dal **Cluster di Gestione**:

```bash
clusterctl describe cluster capi-quickstart
```

> **Nota:** Questo comando fornisce una panoramica dettagliata di tutte le risorse CAPI (Cluster, KubeadmControlPlane, MachineDeployment, ecc.) e del loro stato (es. **Cluster is Ready**).

### 2\. Le Macchine sono Risorse Kubernetes (Soddisfiamo il TODO\! ✅)

Dal **Cluster di Gestione**, le *macchine* che compongono il Workload Cluster sono semplicemente risorse Kubernetes gestite dai controller CAPI.

  * Visualizza tutte le **risorse CAPI** correlate al cluster:

    ```bash
    kubectl get cluster,machines,machinedeployments,kubeadmcontrolplanes
    ```

  * Visualizza le **Macchine** in dettaglio (noterai una macchina per il control plane e una per il worker):

    ```bash
    kubectl get machines
    ```

### 3\. Interagire con il Workload Cluster

Abbiamo già recuperato il file `capi-quickstart.kubeconfig`. Usiamolo per interagire con i nodi appena creati (che sono container Docker):

```bash
kubectl get nodes --kubeconfig capi-quickstart.kubeconfig
```

**Output atteso:**
Dopo pochi minuti e l'installazione del CNI, dovresti vedere entrambi i nodi in stato `Ready`.

```console
NAME                                    STATUS   ROLES           AGE     VERSION
capi-quickstart-control-plane-xyz       Ready    control-plane   5m      v1.34.0
capi-quickstart-md-0-abcdefg            Ready    <none>          4m      v1.34.0
```

-----

# Demo 2: Aggiornamento del Workload Cluster (Scaling Out) 📈

Cluster API eccelle nella gestione del ciclo di vita. Scaliamo il cluster da **1 a 3 macchine worker**.

### 1\. Generazione della Nuova Configurazione

Generiamo una nuova configurazione (`capi-multiworker.yaml`) modificando solo il conteggio dei worker a `3`.

```bash
clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.34.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=3 \
  > capi-multiworker.yaml
```

### 2\. Applicazione della Modifica

Applichiamo il nuovo file al **Cluster di Gestione**. CAPI rileverà la modifica al `MachineDeployment` e avvierà il processo di *scaling out* (creazione di 2 nuovi container Docker).

```bash
kubectl apply -f capi-multiworker.yaml
```

### 3\. Verifica dello Scaling

Verifica dal Workload Cluster l'arrivo dei nuovi nodi.

```bash
kubectl get nodes --kubeconfig capi-quickstart.kubeconfig
```

Dovresti vedere **tre** worker nodes (più il control plane) dopo pochi minuti che CAPI li ha creati e kubeadm li ha configurati.



Certo\! Aggiungo la parte relativa allo **scaling del Control Plane** subito dopo la Demo 2 sullo scaling dei Worker.

-----

# Demo 3: Aggiornamento del Control Plane (Scaling Up) ⚖️

L'architettura di CAPI gestisce il **Control Plane** come una risorsa singola (`KubeadmControlPlane`), consentendo di scalare i nodi del Control Plane (CP) per aumentare resilienza e disponibilità.

Scaliamo il cluster da **1 a 3 nodi Control Plane** per renderlo **Highly Available (HA)**.

## 1\. Generazione della Nuova Configurazione

Generiamo una nuova configurazione, specificando `3` nodi per il control plane e mantenendo `3` nodi worker.

```bash
clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.34.0 \
  --control-plane-machine-count=3 \
  --worker-machine-count=3 \
  > capi-ha.yaml
```

> **Nota:** Stiamo sovrascrivendo la configurazione precedente del cluster `capi-quickstart` con un nuovo file (che chiamo `capi-ha.yaml` per chiarezza, ma si applica allo stesso cluster).

## 2\. Applicazione della Modifica

Applichiamo il nuovo file al **Cluster di Gestione**. CAPI attiverà i controller per creare due nuovi nodi CP e configurarli con **etcd** e **kube-apiserver** per formare un cluster HA.

```bash
kubectl apply -f capi-ha.yaml
```

## 3\. Verifica dello Scaling del Control Plane

Controlliamo dal **Workload Cluster** l'arrivo dei nuovi nodi.

```bash
kubectl get nodes --kubeconfig capi-quickstart.kubeconfig
```

**Output atteso:**
Dopo alcuni minuti, il cluster di gestione avrà creato due nuovi container Docker e il controller `KubeadmControlPlane` li avrà uniti al cluster etcd. Vedrai ora **tre** nodi con il ruolo `control-plane`.

```console
NAME                                    STATUS   ROLES           AGE     VERSION
capi-quickstart-control-plane-xyz       Ready    control-plane   30m     v1.34.0  # Nodo originale
capi-quickstart-control-plane-uvw       Ready    control-plane   2m      v1.34.0  # Nuovo nodo 1
capi-quickstart-control-plane-rst       Ready    control-plane   1m      v1.34.0  # Nuovo nodo 2
capi-quickstart-md-0-abcdefg            Ready    <none>          25m     v1.34.0
capi-quickstart-md-0-hijklmn            Ready    <none>          15m     v1.34.0
capi-quickstart-md-0-opqrst             Ready    <none>          15m     v1.34.0
```

Il cluster è ora **Highly Available**\! 🎉

-----

### Pulizia (Opzionale) 🧹

Per terminare la demo e rimuovere tutto, esegui questi comandi:

1.  **Rimuovi il Workload Cluster** (dal Cluster di Gestione):

    ```bash
    kubectl delete cluster capi-quickstart
    ```

    Questo comando pulirà tutte le risorse CAPI e i container Docker associati ai nodi del Workload Cluster.

2.  **Rimuovi il Cluster di Gestione** (il cluster kind):

    ```bash
    kind delete cluster
    ```
