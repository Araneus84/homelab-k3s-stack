<div align="center">

# Homelab Kubernetes Project

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh/)
[![Velero](https://img.shields.io/badge/Velero-FF6D00?style=for-the-badge&logo=velero&logoColor=white)](https://velero.io/)
[![Status](https://img.shields.io/badge/status-WIP-yellow?style=for-the-badge)](.)

</div>

---

### Architecture (High-Level)

```mermaid
flowchart LR
    subgraph cluster["Kubernetes Cluster (k3s)"]
        subgraph infra["Infrastructure Layer"]
            velero["Velero<br/>Backup & Restore"]
            adguard-dns["AdGuard Home DNS<br/>DNS filtering"]
            argocd["Argo CD<br/>GitOps deployment"]
            cert-manager["cert-manager<br/>TLS Automation"]
            nginx-ingress["nginx-ingress<br/>Ingress controller"]
            monitoring["Monitoring<br/>Prometheus + Grafana + Loki (planned)"]
        end

        subgraph media["Media Stack"]
            overseerr["Overseerr"]
            prowlarr["Prowlarr"]
            radarr["Radarr"]
            sonarr["Sonarr"]
            qbit["qBittorrent"]
            plex["Plex"]
        end

        subgraph security["Security Layer"]
            vaultwarden["Vaultwarden<br/>Password Manager"]
            sealedsecrets["Sealed Secrets<br/>Encrypted secret manifests"]
        end

        subgraph tools["Personal Tools"]
            homeassistant["Home Assistant<br/>Smart Home Control"]
        end
    end

    overseerr -->|User Requests| radarr
    overseerr -->|User Requests| sonarr
    prowlarr -->|indexers| radarr
    prowlarr -->|indexers| sonarr
    radarr -->|download jobs| qbit
    sonarr -->|download jobs| qbit
    radarr -->|media library| plex
    sonarr -->|media library| plex
    velero -.->|scheduled backups| media

    classDef infra fill:#e8f1ff,stroke:#2f6feb,stroke-width:1px,color:#102a43;
    classDef media fill:#ecfff4,stroke:#1f883d,stroke-width:1px,color:#0f3d2e;
    classDef security fill:#fff1f1,stroke:#cf222e,stroke-width:1px,color:#5a1b1b;
    classDef tools fill:#fff8e6,stroke:#9a6700,stroke-width:1px,color:#4d3b00;
    classDef core fill:#f5f0ff,stroke:#8250df,stroke-width:1px,color:#2b1a59;

    class velero,adguard-dns,argocd,cert-manager,nginx-ingress,monitoring infra;
    class overseerr,prowlarr,radarr,sonarr,plex media;
    class vaultwarden,sealedsecrets security;
    class homeassistant tools;
    class qbit core;
```

---

This repository contains a Kubernetes-based homelab managed with GitOps principles. It focuses on reliable operations, clear service boundaries, and reproducible application deployment using Helm and Argo CD.

### Project Scope

- **Platform**: k3s cluster with ingress, certificate management, and DNS filtering.
- **Media Stack**: Plex, Sonarr, Radarr, qBittorrent, Overseerr, and Prowlarr.
- **Security**: Sealed Secrets and self-hosted services such as Vaultwarden.
- **Operations**: Backup and recovery workflows using Velero.

### Recent Improvements

- **In-cluster service communication**: Sonarr and Radarr connect to qBittorrent via Kubernetes Service DNS (`qbittorrent-web.media.svc:8080`) rather than ingress hosts.
- **Shared storage consistency**: qBittorrent, Sonarr, and Radarr use the same NFS-backed mount path (`/mnt/nas`) to avoid path mapping/import issues.
- **Structured GitOps layout**: Applications are defined through Argo CD app manifests in `argocd-apps/apps/` and Helm charts under `apps/`.
- **Clear traffic separation**: Ingress hosts (`*.home`) are used for user access; internal Services are used for pod-to-pod communication.

### Technologies & Tools

- **Kubernetes** (homelab cluster)
- **Helm** (chart and values-based configuration)
- **Velero** (backup and disaster recovery)
- **Self-Hosted Media Apps** (Plex, Radarr, Sonarr, qBittorrent, Overseerr, Prowlarr, etc.)
- **Linux (WSL2)** as the primary development environment

### What This Project Demonstrates

- **Infrastructure as Code**: Clustering, apps, and backups are defined declaratively and can be reproduced.
- **Operational Thinking**: Includes backup, restore, and data-protection concerns (Velero, persistent storage).
- **Realistic Homelab Use Case**: Media stack and supporting services configured similarly to a production-like environment, but in a personal lab context.
