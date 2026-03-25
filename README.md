<div align="center">

# Homelab Kubernetes Project

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh/)
[![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![Status](https://img.shields.io/badge/status-WIP-yellow?style=for-the-badge)](.)

</div>

---

### Architecture (High-Level)

```mermaid
flowchart LR
    git["Git repo<br/>`main`"] --> argo["Argo CD<br/>App-of-Apps"]

    subgraph k8s["k3s Kubernetes Cluster"]
        subgraph dns["DNS Layer"]
            pihole["Pi-hole"]
            adguard["AdGuard Home"]
        end

        subgraph security["Security Layer"]
            certmgr["cert-manager<br/>TLS / ACME"]
            sealed["Sealed Secrets"]
            vaultwarden["Vaultwarden"]
        end

        subgraph edge["Ingress & Networking"]
            nginx["nginx-ingress<br/>Ingress controller"]
        end

        subgraph monitoring["Observability"]
            prom["kube-prometheus-stack<br/>Prometheus + Grafana + Alertmanager"]
            loki["Loki + Promtail<br/>Logs"]
        end

        subgraph storage["Storage"]
            nfs["NFS provisioner"]
        end

        subgraph media["Apps (Helm charts)"]
            homepage["Homepage<br/>Dashboard"]
            homeassistant["Home Assistant"]

            overseerr["Overseerr"]
            prowlarr["Prowlarr"]
            radarr["Radarr"]
            sonarr["Sonarr"]
            qbit["qBittorrent"]
            plex["Plex"]
            autobrr["Autobrr"]
            flaresolverr["FlareSolverr"]
        end
    end

    %% GitOps wiring
    argo --> certmgr
    argo --> sealed
    argo --> nginx
    argo --> prom
    argo --> loki
    argo --> nfs
    argo --> pihole
    argo --> adguard
    argo --> homepage
    argo --> homeassistant
    argo --> overseerr
    argo --> prowlarr
    argo --> radarr
    argo --> sonarr
    argo --> qbit
    argo --> plex
    argo --> autobrr
    argo --> flaresolverr

    %% TLS + access paths
    certmgr --> nginx
    nginx --> homepage

    %% Shared storage consumers
    nfs --> qbit
    nfs --> plex

    %% Media automation chain
    overseerr -->|requests| radarr
    overseerr -->|requests| sonarr
    prowlarr -->|indexers| radarr
    prowlarr -->|indexers| sonarr
    radarr -->|downloads| qbit
    sonarr -->|downloads| qbit
    radarr -->|library| plex
    sonarr -->|library| plex
```

---

This repository contains a Kubernetes-based homelab managed with GitOps (Argo CD). Services are defined as Helm charts and Application CRs so the cluster stays reproducible from `main`.

### Project Scope

- **Platform**: k3s, nginx ingress, cert-manager (ACME-ready), Sealed Secrets, NFS-backed storage.
- **Observability**: Prometheus, Grafana, Alertmanager, node metrics, **Loki**, and **Promtail** (logs in Grafana).
- **DNS**: **Pi-hole** (network DNS / ad-blocking) and **AdGuard Home** (optional alternate UI/filtering stack).
- **Media**: Plex, Sonarr, Radarr, qBittorrent, Overseerr, Prowlarr, **Autobrr**, **FlareSolverr**.
- **Security**: Vaultwarden (passwords).
- **Dashboard**: **Homepage** application portal with optional cluster ingress discovery.
- **Automation**: **Argo CD Image Updater** for selected apps (semver image updates).

### GitOps layout

- Root Application: `argocd-apps/app-of-apps.yaml` (recurses over `argocd-apps/`).
- Per-app manifests: `argocd-apps/apps/` and `argocd-apps/infrastructure/`.
- Helm sources: `apps/` (workloads), `infrastructure/` (cluster components).

### Optional / not in app-of-apps

- **Velero**: Chart and values live under `infrastructure/velero/` for manual or future wiring; there is no `argocd-apps` Application for it yet.

### Recent stack notes

- **Logs**: Loki + Promtail deploy in the `monitoring` namespace; Grafana includes a Loki datasource.
- **Ingress discovery**: Homepage can annotate ingresses for its UI (`gethomepage.dev/*` annotations on selected Ingresses).
- **Internal media traffic**: Sonarr/Radarr talk to qBittorrent via cluster DNS where configured; large libraries use shared NFS paths (see `docs/architecture.md`).
- **Image updates**: Argo CD Image Updater targets apps that declare `argocd-image-updater.argoproj.io/*` annotations (e.g. Homepage, FlareSolverr).

### Technologies & Tools

- **Kubernetes** (k3s)
- **Helm** and **Argo CD**
- **Prometheus / Grafana / Loki** (observability)
- **Linux (WSL2)** for development against the repo

### What This Project Demonstrates

- **Infrastructure as Code**: Cluster add-ons and apps are declared in Git and applied by Argo CD.
- **Operational patterns**: Backups (Velero optional), persistent storage, ingress, and secrets (Sealed Secrets).
- **Homelab realism**: Media automation, DNS, and dashboards similar to a small production footprint.

### Documentation

- [docs/setup.md](docs/setup.md) — Ansible, bootstrap, sealed secrets, DNS.
- [docs/architecture.md](docs/architecture.md) — Topology, namespaces, ingress table, sync waves, security.
