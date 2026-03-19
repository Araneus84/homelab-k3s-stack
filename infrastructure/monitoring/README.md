# Monitoring chart (Prometheus + Grafana)

## Custom Grafana dashboard not appearing

1. **Git / Argo CD** — Argo only sees what is pushed. Confirm your cluster repo revision includes `dashboards/` and `templates/grafana-dashboard-homelab-stack.yaml`.

2. **ConfigMap** — After sync, check the release namespace (usually `monitoring`):
   ```bash
   kubectl get configmap -n monitoring -l grafana_dashboard=1
   ```

3. **Sidecar logs** — Reload/API errors show here:
   ```bash
   kubectl logs -n monitoring deploy/<release>-grafana -c grafana-sc-dashboard
   ```

4. **Wait or restart** — Provisioning rescans about every 30s; or restart Grafana once:
   ```bash
   kubectl rollout restart -n monitoring deploy/<release>-grafana
   ```

5. **Prometheus datasource UID** — This stack expects the default Prometheus datasource **UID** `prometheus` (kube-prometheus-stack default). If you changed it, update the dashboard JSON `uid` fields accordingly.

---

## Argo CD / `monitoring` app not behaving (SRE triage)

**Do this before changing charts or pushing “fixes” repeatedly.**

### 1) Classify the failure

| What you see | Usually means |
|--------------|----------------|
| App **OutOfSync** forever, no errors | Diff noise (SSA, webhooks, operator `.status`) — see `ignoreDifferences` on the Application |
| App **SyncError** / **Failed** | Real apply conflict: open sync fail message + `kubectl describe application monitoring -n argocd` |
| **Synced** but workloads **Unhealthy** | Kubernetes problem (PVC pending, bad secret, crashloop) — not Git |

### 2) Commands (copy-paste)

```bash
# Argo’s view
kubectl get application monitoring -n argocd -o yaml

# Why last sync failed (message + resource list)
kubectl describe application monitoring -n argocd | sed -n '/Operation State/,/Events/p'

# Live namespace
kubectl get pods,svc,pvc -n monitoring
kubectl get events -n monitoring --sort-by='.lastTimestamp' | tail -25
```

### 3) Prove Git matches the cluster (local, same repo revision)

```bash
helm dependency build infrastructure/monitoring
helm template monitoring infrastructure/monitoring -f infrastructure/monitoring/values.yaml -n monitoring > /tmp/monitoring-rendered.yaml
# Compare with what Argo shows as Desired Manifest, or diff against live objects if needed
```

### 4) Grafana secret

If Grafana never becomes Ready, check the sealed secret was applied in **`monitoring`**:

```bash
kubectl get secret grafana-admin-credentials -n monitoring
```

---

**Release names:** The Application is named `monitoring`, so Helm resources are typically `monitoring-*`. If you ever change the Application name, update `ignoreDifferences` `name:` fields to match `helm template <release> ... | grep '^  name:'`.
