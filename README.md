# Deploy Kubernetes con Cluster API

Questa presentazione introduce Cluster API, un progetto Kubernetes che rivoluziona la gestione dei cluster attraverso un approccio dichiarativo e automatizzato. Molti team tecnici affrontano difficoltà significative quando devono creare, gestire e mantenere cluster Kubernetes in produzione: processi manuali complessi, configurazioni soggette a errori, aggiornamenti difficoltosi e scalabilità limitata sono solo alcuni dei problemi comuni.

Cluster API offre una soluzione elegante a questi problemi, permettendo di definire l'intero ciclo di vita di un cluster Kubernetes attraverso semplici manifesti YAML. Invece di eseguire manualmente script complessi per il provisioning, con Cluster API puoi dichiarare "questo è lo stato desiderato del mio cluster" e il sistema si occuperà automaticamente di raggiungere e mantenere quello stato.

La presentazione esplora i principi fondamentali su cui si basa Cluster API, in particolare il reconciliation loop di Kubernetes, che permette di gestire risorse complesse come macchine virtuali attraverso le API. Vengono inoltre analizzate le componenti logiche del sistema e i diversi provider (bootstrap, infrastructure e control plane) che consentono di operare su diversi ambienti cloud e on-premise.

Infine, la presentazione include una dimostrazione pratica che mostra come sia possibile creare interi cluster Kubernetes con pochi semplici comandi, evidenziando come queste tecnologie possano semplificare notevolmente la vita degli ingegneri DevOps e dei team di piattaforma.

## Come avviare la presentazione

Per avviare la presentazione in modalità sviluppo:

- `pnpm install` o `make install` - Installa le dipendenze
- `pnpm dev` o `make dev` - Avvia il server di sviluppo
- visita <http://localhost:3030>

Modifica il file [slides.md](./slides.md) per vedere le modifiche.

## Comandi disponibili

Questo progetto include un Makefile con comandi convenienti per lo sviluppo:

- `make install` - Installa le dipendenze
- `make dev` - Avvia il server di sviluppo
- `make build` - Compila il sito statico
- `make serve` - Esegue localmente il sito compilato
- `make clean-install` - Installazione pulita delle dipendenze
- `make lint` - Controlla lo stile del codice
- `make test` - Esegue i test disponibili
- `make deploy` - Effettua il deploy in produzione
- `make clean` - Rimuove i file di compilazione
- `make help` - Mostra i comandi disponibili

L'utilizzo di questi comandi fornisce un'interfaccia coerente indipendentemente dal gestore di pacchetti utilizzato.

## Documentazione Slidev

Per ulteriori informazioni su Slidev visita la [documentazione ufficiale](https://sli.dev/).
