Lo scopo della demo è eseguire un deploy di k8s utilizzando capi e l'infrastructure provider Docker (CAPD) in modo da non avere dipendenze esterne. 

Questo setup è dimostrativo e non è inteso come uso in produzione!


---

## Requisti

- Clusterctl
```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.11.1/clusterctl-linux-amd64 -o clusterctl
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
```
- Kind
```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

- kubectl   
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

- Custom config docker

Crea o modifica un file di configurazione in `/etc/sysctl.d/` (es. `/etc/sysctl.d/99-docker-limits.conf`) sull'HOST:

```bash
fs.inotify.max_user_watches = 524288

fs.inotify.max_user_instances = 512
```
Applica la modifica immediatamente sull'HOST:

```bash
sudo sysctl -p /etc/sysctl.d/99-docker-limits.conf
```

## Avvio

Per prima cosa avviare il cluster di gestione

```bash
kind create cluster --config kind-cluster-with-extramounts.yaml
```
```console
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.32.2) 🖼
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
```

Serve questo file per consentire di usare il socket docker del sistema host, oltre a definire un nome per il cluster in modo da facilitare la riproduzione degli esperimenti

A questo punto dobbiamo avviare il cluster di gestione che si occuperà di creare gli altri cluster di workload

``` Bash
# Enable the experimental Cluster topology feature.
export CLUSTER_TOPOLOGY=true

# Initialize the management cluster
clusterctl init --infrastructure docker
```
```console
Fetching providers
Installing cert-manager version="v1.17.2"
Waiting for cert-manager to be available...
Installing provider="cluster-api" version="v1.10.6" targetNamespace="capi-system"
Installing provider="bootstrap-kubeadm" version="v1.10.6" targetNamespace="capi-kubeadm-bootstrap-system"
Installing provider="control-plane-kubeadm" version="v1.10.6" targetNamespace="capi-kubeadm-control-plane-system"
Installing provider="infrastructure-docker" version="v1.10.6" targetNamespace="capd-system"

Your management cluster has been initialized successfully!

You can now create your first workload cluster by running the following:

  clusterctl generate cluster [name] --kubernetes-version [version] | kubectl apply -f -
```

Ora possiamo usare `clusterctl` anche per generare una configurazione di partenza

```bash
clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.34.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > capi-quickstart.yaml
```

per poi avviarla usando `kubectl` contro il cluster di gestione, come se stessimo deployando una applicazione normalissima

```bash
kubectl apply -f capi-quickstart.yaml
```

Per finalizzare, devo installare CNI _sul workload cluster_ in modo da consentire la comunicazione tra i nodi e terminare la creazione del cluster



```bash
clusterctl get kubeconfig capi-quickstart > capi-quickstart.kubeconfig

kubectl --kubeconfig=./capi-quickstart.kubeconfig \
  apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

## Verifiche

A questo punto se tutto è andato come si deve, vedremo un nuovo cluster creato/in corso di creazione

Ma come lo uso un workload cluster? Semplice, devo estrarre la sua configurazione del cluster di gestione (una volta che è disponibile)

```bash
clusterctl describe cluster capi-quickstart
```

E ovviamente possiamo vedere come le macchine sono semplici risorse k8s

- TODO: Aggiungere comandi per vedere come funzionano

## Interagire con il workload cluster

```bash
clusterctl get kubeconfig capi-quickstart > capi-quickstart.kubeconfig
```


```bash
kubectl get nodes --kubeconfig capi-quickstart.kubeconfig
```

---

Demo 2 - Update

E se adesso voglio 3 macchine worker??

```bash
clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.34.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=3 \
  > capi-multiworker.yaml
```

```bash
kubectl apply -f capi-multiworker.yaml
```


```bash
clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.34.0 \
  --control-plane-machine-count=3 \
  --worker-machine-count=3 \
  > capi-final.yaml
kubectl apply -f capi-final.yaml
```


