# Introduzione e demo

- spiegare perché tirare su e gestire un cluster k8s per la produzione è complesso e porta via tempo
- spiegare perché oltre a tirarlo su è un casino da gestire (aggiornamenti etc…)
- fare vedere che con un comando partono le varie VM
    - (qui mi serve accesso remoto al mio cluster…)

# Ma quali primitive di k8s utilizza?

- somewhat “deep” dive: il reconciliation loop di k8s
    - qui facciamo vedere che il loop in modo astratto consente di definire come interagire con delle API per gestire delle risorse, in questo caso delle risorse sono delle macchini virtuali

# Figo! Ma quali sono le componenti logiche di questo sistema?

- definire i concetti dei provider principali
    - bootstrap provider
    - infrastructure provider
    - control planer provider
- e dei provider di supporto
    - IPAM ⇒ forniture di indirizzi IP

# Si ok, ma come si accordano per farlo funzionare?

- Descrizione di come comunicano tra di loro i vari pezzi