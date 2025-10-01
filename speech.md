# Deploy Kubernetes con Cluster API - Discorso

## Slide 1: Introduzione
Benvenuti tutti! Oggi parleremo di come gestire e deployare Kubernetes in modo automatizzato utilizzando Cluster API, passando dal caos all'automazione.
Cluster API è un sub-progetto ufficiale di Kubernetes che ci permette di gestire il ciclo di vita completo dei cluster Kubernetes in modo dichiarativo.
Nella slide vediamo uno sfondo con un'immagine di un ambiente cloud computing che rappresenta il contesto della gestione cluster.

## Slide 2: Il Problema della Gestione Manuale
Cominciamo col comprendere il problema che affrontiamo oggi. La gestione manuale dei cluster Kubernetes presenta molte sfide operative:
- Abbiamo script personalizzati per il provisioning che diventano difficili da mantenere
- Procedure manuali per gli upgrade che sono soggette a errori
- Configurazioni statiche che sono difficili da versionare
- Approcci imperativi invece che dichiarativi

Queste sfide portano a problemi concreti come operazioni soggette a errori, drift di configurazione che rende ogni cluster un "fiocco di neve" unico, scalabilità limitata con carico operativo lineare e complessità crescente nella gestione multi-cluster.
Secondo le survey della CNCF, la complessità operativa rimane una delle principali sfide nell'adozione enterprise di Kubernetes.
In questa slide vediamo una griglia con due colonne che mostra le sfide operative attuali e i problemi concreti, e un avviso evidenziato in rosso con le statistiche della CNCF.

## Slide 3: Confronto Approccio Tradizionale vs CAPI
Vediamo una differenza concreta tra l'approccio tradizionale e Cluster API.
Nell'approccio tradizionale, per aggiungere un worker node, dobbiamo connetterci via SSH, configurare i repository, installare i pacchetti necessari come kubelet, kubeadm e kubectl, abilitare i servizi e gestire il join al cluster. Questo processo è soggetto a errori, richiede molto tempo e non è riproducibile.

```bash
#!/bin/bash
# Script per aggiungere worker node
ssh worker-node-03

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-get install -y kubelet kubeadm kubectl

systemctl enable kubelet
swapoff -a
# ... configurazione runtime container
# ... configurazione networking

# ... join del cluster
```

Questo approccio è error-prone, time-consuming e non riproducibile come evidenziato in rosso.

Con Cluster API invece, definiamo lo stato desiderato del cluster in un file YAML. Definiamo riferimenti al control plane e all'infrastruttura, e poi applichiamo questa configurazione con un semplice comando `kubectl apply -f cluster.yaml`. Questo approccio è dichiarativo, idempotente e versionabile.

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: production-cluster
spec:
  controlPlaneRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1beta1
    kind: KubeadmControlPlane
    name: production-control-plane
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: ProxmoxCluster
    name: production-proxmox
```

```bash
kubectl apply -f cluster.yaml
```

Come evidenziato in verde, questo approccio è dichiarativo, idempotente e versionabile.
La slide mostra una griglia con due colonne che confrontano questi due approcci.

## Slide 4: Cos'è Cluster API
Cluster API è un sub-progetto ufficiale di Kubernetes per la gestione dichiarativa dell'intero ciclo di vita di cluster Kubernetes.
Ha tre caratteristiche principali:
- API Dichiarative: definiamo lo stato desiderato e CAPI si occupa del come raggiungerlo
- Eventual Consistency: controller che riconciliano continuamente lo stato
- Provider Pattern: astrazione dell'infrastruttura sottostante

Questa slide è centrata con un'icona Kubernetes e un riquadro verde per evidenziare la definizione. Vediamo anche una griglia con tre riquadri evidenziati che mostrano queste caratteristiche fondamentali.

## Slide 5: Architettura CAPI - Management vs Workload
L'architettura di Cluster API distingue tra Management Cluster e Workload Cluster.
Il Management Cluster funge da hub di controllo centrale dove risiedono i controller CAPI core, vengono archiviate le CRD e avviene l'orchestrazione del ciclo di vita. Può essere un cluster locale (kind), un cluster dedicato o un setup multi-tenant.

Nel riquadro evidenziato in blu vediamo un'icona cloud-services con "Hub di controllo centrale" e sotto alcune caratteristiche:
- Hosting dei controller CAPI core
- Archiviazione delle CRD
- Orchestrazione ciclo di vita
- Gestione credenziali

Il Workload Cluster è il cluster dove vengono effettivamente deployate le applicazioni business. Il suo lifecycle è completamente gestito, offre isolamento operativo e self-healing infrastructure. Un importante punto da notare è che un singolo Management Cluster può gestire centinaia di Workload Cluster.

Nel riquadro evidenziato in verde vediamo un'icona deploy con "Cluster per le applicazioni" e sotto alcune caratteristiche:
- Deployment delle applicazioni business
- Lifecycle completamente gestito
- Isolamento operativo
- Scaling automatico

Vediamo anche un riquadro giallo evidenziato con un'icona di connessione e la frase "Un Management Cluster può gestire centinaia di Workload Cluster".

## Slide 6: Componenti Core di CAPI
I componenti principali di Cluster API sono:

Core Controller:
```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: production-cluster
spec:
  controlPlaneRef:
    kind: TalosControlPlane
    name: production-control-plane
  infrastructureRef:
    kind: ProxmoxCluster 
    name: production-proxmox
```
Questo gestisce l'orchestrazione di alto livello del ciclo di vita.

Machine Controller:
```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Machine
metadata:
  name: worker-node-01
spec:
  version: "v1.29.0"
  bootstrap:
    configRef:
      kind: TalosConfig
      name: worker-bootstrap-config
```
Questo gestisce le singole istanze di calcolo.

Vediamo anche tre riquadri evidenziati:
- Bootstrap Provider: Configurazione iniziale nodi
- Control Plane Provider: Gestione componenti master
- Infrastructure Provider: Astrazione infrastruttura

## Slide 7: Reconciliation Loop
La magia dietro Cluster API è il Reconciliation Loop. Nella slide vediamo un diagramma Mermaid che mostra il ciclo tra stato desiderato, controller, stato attuale e feedback loop.

L'algoritmo di reconciliation funziona in tre fasi:

```go
func (r *Reconciler) Reconcile(ctx context.Context, 
    req ctrl.Request) (ctrl.Result, error) {
    // 1. Observe - Fetch current state
    obj := &v1beta1.Object{}
    if err := r.Get(ctx, req.NamespacedName, obj); 
        err != nil {
        return ctrl.Result{}, 
               client.IgnoreNotFound(err)
    }
    
    // 2. Analyze - Compare desired vs actual
    if obj.DeletionTimestamp != nil {
        return r.reconcileDelete(ctx, obj)
    }
    
    // 3. Act - Take corrective action
    return r.reconcileNormal(ctx, obj)
}
```

I principi fondamentali sono:
- Idempotenza: operazioni sicure ripetibili
- Eventual Consistency: convergenza verso stato desiderato
- Error Handling: retry automatici con backoff
- Observability: eventi e metriche per debugging

## Slide 8: Talos Linux
Ora introduciamo Talos Linux, il sistema operativo per Kubernetes.
Talos Linux è un OS immutabile API-First progettato esclusivamente per Kubernetes. Le caratteristiche principali sono:
- Nessun SSH, solo gestione via API
- Filesystem root read-only per maggiore sicurezza
- Minima superficie di attacco con solo componenti essenziali
- Upgrade atomici senza downtime

Questa slide è centrata con un'icona server bare metal e una griglia di quattro riquadri evidenziati che mostrano queste caratteristiche fondamentali.

## Slide 9: Problemi OS Tradizionali vs Talos
Confrontiamo un sistema tradizionale come Ubuntu con Talos.
Con un sistema tradizionale, spesso dobbiamo connetterci via SSH ad ogni nodo per aggiornamenti pacchetti, il che porta a versioni diverse nei nodi, configurazioni divergenti e comportamenti inconsistenti. Inoltre, un sistema tradizionale ha centinaia di pacchetti installati, molti dei quali non necessari per Kubernetes, e tanti servizi in esecuzione.

```bash
# Scenario tipico
ssh worker-node-01
sudo apt update && sudo apt upgrade -y

# Un mese dopo...
ssh worker-node-02  
sudo apt update && sudo apt upgrade -y

# Risultato: versioni diverse, 
# configurazioni divergenti,
# comportamenti inconsistenti
```

Come evidenziato in rosso, i problemi sono:
- ~1847 pacchetti installati (necessari <20)
- ~50+ servizi in esecuzione
- SSH access per manutenzione
- Configuration drift inevitabile

Con Talos, invece, gestiamo tutto via API. Possiamo vedere lo stato dei membri del cluster, ottenere i log di kubelet e fare upgrade atomici senza downtime. La configurazione è immutabile e identica su tutti i nodi, eliminando il configuration drift.

```bash
# Gestione via API
talosctl -n 192.168.1.100 get members
talosctl -n 192.168.1.100 logs kubelet

# Upgrade atomico
talosctl -n 192.168.1.100 upgrade \
  --image ghcr.io/siderolabs/installer:v1.7.1

# Configurazione immutabile
talosctl -n node-a,node-b get kubeletconfig
# Output identico su tutti i nodi
```

Come evidenziato in verde, i vantaggi sono:
- Solo componenti essenziali per K8s
- Nessun accesso shell o SSH
- Filesystem root read-only
- Zero configuration drift

## Slide 10: Architettura Talos
L'architettura di Talos è progettata per immutabilità:

```
/
├── boot/          # Boot partition (read-only)
├── system/        # System partition (read-only, squashfs)
├── var/           # Persistent data (writable)
│   ├── lib/kubernetes/
│   ├── lib/containerd/
│   └── log/
└── tmp/           # Temporary files (tmpfs)
```

Come evidenziato in blu, l'immutabilità è garantita perché il sistema base non può essere modificato runtime.

I componenti essenziali sono:
- Kernel Linux ottimizzato
- systemd per service management
- containerd + runc
- CNI plugins per networking
- kubelet per K8s integration

Come evidenziato in rosso, sono esclusi shell, package manager, SSH e utility non essenziali.

## Slide 11: Integrazione Talos + CAPI
L'integrazione tra Talos e CAPI avviene attraverso CRD specifiche.

TalosConfig CRD:
```yaml
apiVersion: bootstrap.cluster.x-k8s.io/v1alpha3
kind: TalosConfig
metadata:
  name: worker-node-bootstrap
spec:
  generateType: "join"
  talosVersion: "v1.7.0"
  configPatches:
    - op: "add"
      path: "/machine/install"
      value:
        disk: "/dev/sda"
        image: "ghcr.io/siderolabs/installer:v1.7.0"
        wipe: false
    - op: "add"  
      path: "/machine/network/interfaces"
      value:
        - interface: "eth0"
          dhcp: true
```

TalosControlPlane CRD:
```yaml
apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: cluster-control-plane
spec:
  replicas: 3
  version: "v1.29.0"
  infrastructureTemplate:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: ProxmoxMachineTemplate
    name: control-plane-template
  controlPlaneConfig:
    controlplane:
      configPatches:
        - op: "add"
          path: "/cluster/etcd"
          value:
            ca:
              crt: LS0tLS1CRUdJTi0tLS0t...
              key: LS0tLS1CRUdJTi0tLS0t...
```

I vantaggi rispetto al cloud-init sono la type safety, l'immutabilità, la consistenza e la sicurezza, come evidenziato in giallo.

## Slide 12: Implementazione Pratica - Setup con Proxmox
Passiamo ora all'implementazione pratica con Proxmox.
Vedremo come fare deploy del primo cluster dal teoria alla pratica.
Questa slide è centrata con un'icona server e il titolo "Implementazione Pratica".

## Slide 13: Architettura Target
La nostra architettura target prevede:
- Un Management Cluster locale con Kind
- Un provider Proxmox per la gestione dell'infrastruttura
- Un Workload Cluster basato su Talos Linux

Vediamo un diagramma Mermaid che mostra la relazione tra i componenti:
- Management Cluster (Kind Local) che comunica con Proxmox VE
- Proxmox VE che fornisce l'infrastruttura per il Workload Cluster
- Workload Cluster che utilizza Talos Linux

Vediamo anche tre riquadri evidenziati che mostrano i diversi livelli: Management, Infrastructure e Workload.

## Slide 14: Setup Proxmox - Configurazione API
Per configurare Proxmox dobbiamo creare un utente dedicato per Cluster API, assegnare i permessi necessari e generare un API token.

Creazione utente e token:
```bash
# Creazione utente CAPI
pveum user add capi@pve \
  --comment "Cluster API Automation User"

# Assignment ruolo Administrator
pveum aclmod / -user capi@pve -role Administrator

# Generazione API token
pveum user token add capi@pve capi-token --privsep 0
```

Come evidenziato in verde, l'output atteso mostra il full-tokenid e il value del token.

Per l'infrastruttura, creiamo un template VM con Talos Linux:
```bash
# Download ISO con estensioni Proxmox
wget https://factory.talos.dev/image/\
ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/\
v1.10.5/nocloud-amd64.iso

# Creazione template VM
qm create 8700 \
  --name "talos-template" \
  --memory 2048 --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsi0 local-lvm:20,format=qcow2 \
  --ide2 local:iso/nocloud-amd64.iso,media=cdrom \
  --boot order=ide2 \
  --agent enabled=1,fstrim_cloned_disks=1

# Conversione a template
qm template 8700
```

Come evidenziato in giallo, è fondamentale usare l'ISO "no-cloud" con supporto cloud-init e QEMU Guest Agent.

## Slide 15: Management Cluster Setup
Creiamo un cluster Kind come Management Cluster:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi-management
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "node-role.kubernetes.io/management=true"
  extraPortMappings:
  # Expose CAPI webhook ports
  - containerPort: 9443
    hostPort: 9443
    protocol: TCP
```

```bash
kind create cluster --config kind-config.yaml
```

Successivamente installiamo clusterctl:
```bash
# Installazione clusterctl
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.3/clusterctl-linux-amd64 -o clusterctl
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl

# Environment variables
export PROXMOX_URL="https://192.168.0.10:8006/api2/json"
export PROXMOX_TOKEN="capi@pve!capi-token"
export PROXMOX_SECRET="12345678-1234-1234-1234-123456789abc"

# Inizializzazione provider
clusterctl init \
  --infrastructure proxmox \
  --control-plane talos \
  --bootstrap talos

# Verifica installazione
kubectl get providers -A
```

## Slide 16: Python Generator - Automazione Template
Creiamo un sistema di generazione automatica di template usando Python e Jinja2.
Vediamo un diagramma Mermaid che mostra il flusso da Config YAML Parameters attraverso Jinja2 Template Logic a Cluster YAML Manifests.

I vantaggi sono:
- Configurazioni parametriche e riutilizzabili
- Template con logica condizionale
- Validazione pre-deployment
- Configurazioni versionabili

Configurazione default (homelab.yaml):
```yaml
# homelab.yaml
cluster_name: "homelab-cluster"
kubernetes_version: "v1.32.0"
replicas: 1
allowed_nodes: ["K8S0", "K8S1", "K8S2"]
control_plane_endpoint:
  host: "192.168.0.30"  # VIP address
  port: 6443
talos:
  version: "v1.10.5"
  template_id: 8700
proxmox:
  vm_specs:
    memory: "4096MiB"
    cores: 2
    disk_size: "20G"
```

```bash
# Generazione cluster
python cluster_generator.py \
  --config homelab.yaml \
  --output homelab-cluster.yaml
```

## Slide 17: Deploy del Primo Cluster
Applichiamo la configurazione generata con kubectl apply:
```bash
# Apply configurazione
kubectl apply -f homelab-cluster.yaml

# Monitor deployment
watch 'kubectl get clusters,machines -A -o wide'

# Check events
kubectl get events --sort-by='.lastTimestamp' -A

# Wait for cluster ready
kubectl wait --for=condition=ControlPlaneReady \
  cluster/homelab-cluster --timeout=20m
```

Il processo prevede diverse fasi:
1. Infrastructure Provisioning - VM creation in Proxmox
2. Bootstrap Process - Talos configuration injection
3. Control Plane Ready - API server startup
4. Worker Nodes - Scaling out cluster

Il tempo atteso per un cluster a 3 nodi è di 10-15 minuti.

## Slide 18: Accesso e Validazione
Per accedere al cluster, estraiamo la kubeconfig dal secret creato da CAPI:
```bash
# Estrazione kubeconfig
kubectl get secret homelab-cluster-kubeconfig \
  -o jsonpath='{.data.value}' | base64 -d > kubeconfig-homelab

# Test accesso cluster
kubectl --kubeconfig kubeconfig-homelab get nodes -o wide

# Expected output:
NAME                        STATUS   ROLES           AGE   VERSION
homelab-cluster-cp-abc123   Ready    control-plane   10m   v1.32.0
homelab-cluster-worker-xyz  Ready    <none>          8m    v1.32.0
homelab-cluster-worker-def  Ready    <none>          8m    v1.32.0
```

Validiamo lo stato dei componenti:
```bash
# Component status
kubectl --kubeconfig kubeconfig-homelab get componentstatuses

# Core system validation
kubectl --kubeconfig kubeconfig-homelab get pods -A

# DNS functionality test
kubectl --kubeconfig kubeconfig-homelab run dns-test \
  --image=busybox --restart=Never \
  -- nslookup kubernetes.default.svc.cluster.local

# Network connectivity
kubectl --kubeconfig kubeconfig-home
```

Questa pipeline ci permette di avere cluster Kubernetes completamente gestiti in modo dichiarativo, da provisioning a scalabilità, mantenendo consistenza e sicurezza attraverso Talos Linux e l'automazione di Cluster API.