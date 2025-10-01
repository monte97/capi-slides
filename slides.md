---
theme: default
background: https://source.unsplash.com/eyJzZXJ2aWNlIjoid3d3Lmx1bWVuLmlvIiwiZmFtaWx5Ijoia2Vic2xlciIsInF1YWxpdHkiOjk1LCJ3aWR0aCI6MTkyMCwiaGVpZ2h0IjoxMDgwLCJzY2hlbWUiOiJodHRwcyJ9
class: text-center
highlighter: shiki
lineNumbers: false
info: |
  ## Deploy Kubernetes con Cluster API
  Gestione Semplificata dei Cluster
drawings:
  persist: false
transition: slide-left
title: Deploy Kubernetes con Cluster API
mdc: true
---

<div class="flex flex-col items-center justify-center h-screen w-full text-center px-4">
  <div class="mb-6">
    <h1 class="text-6xl font-extrabold mb-4 leading-tight">
      Deploying <span class="text-blue-400">Kubernetes</span>
    </h1>
    <h2 class="text-4xl font-light opacity-90">
      con Cluster API
    </h2>
  </div>
  
  <div class="my-16">
    <p class="text-5xl font-bold tracking-tight">
      Dal Chaos all'Automazione
    </p>
  </div>
  
  <div class="text-xl opacity-80 mb-16">
    Una guida pratica al lifecycle management dei cluster
  </div>

  <div class="mt-auto pb-16">
    <span @click="$slidev.nav.next" class="px-10 py-5 rounded-full bg-black bg-opacity-40 cursor-pointer hover:bg-opacity-60 transition-all transform hover:scale-105 text-2xl font-semibold">
      Inizia la presentazione <carbon:arrow-right class="inline ml-2"/>
    </span>
  </div>
</div>

---

# Perché gestire cluster K8s è complesso?

---

# Problemi: provisioning e gestione

---

# Demo: un comando, tante VM

---

# Quali primitive K8s utilizza CAPI?

---

# Deep dive: reconciliation loop

---

# Componenti logiche di CAPI

---

# I tre provider principali

---

# Provider di supporto

---

# Come comunicano tra loro?

---

# Conclusione e prossimi passi