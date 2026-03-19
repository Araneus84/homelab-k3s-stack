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
