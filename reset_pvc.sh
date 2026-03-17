#!/usr/bin/env bash
set -euo pipefail

# Namespaces where your app PVCs live
NAMESPACES=("dns" "home-automation" "media" "security" "monitoring")

echo "This will delete pods and PVCs in namespaces:"
printf '  - %s\n' "${NAMESPACES[@]}"
read -rp "Type 'yes' to continue: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

for NS in "${NAMESPACES[@]}"; do
  echo
  echo "=== Namespace: $NS ==="

  PVCs=$(kubectl get pvc -n "$NS" --no-headers 2>/dev/null | awk '{print $1}') || true
  if [[ -z "$PVCs" ]]; then
    echo "No PVCs in $NS, skipping."
    continue
  fi

  echo "PVCs in $NS:"
  echo "$PVCs" | sed 's/^/  - /'

  # 1) Delete pods that use any of these PVCs (non-blocking)
  echo "Deleting pods that use these PVCs (non-blocking)..."
  for PVC in $PVCs; do
    PODS=$(kubectl get pods -n "$NS" \
      -o jsonpath='{range .items[?(@.spec.volumes[*].persistentVolumeClaim.claimName=="'"$PVC"'")]}{.metadata.name}{"\n"}{end}') || true
    [[ -z "$PODS" ]] && continue

    echo "  PVC $PVC is used by pods:"
    echo "$PODS" | sed 's/^/    - /'
    kubectl delete pod $PODS -n "$NS" --wait=false || true
  done

  # 2) Delete PVCs themselves (non-blocking)
  echo "Deleting PVCs in $NS (non-blocking)..."
  kubectl delete pvc --all -n "$NS" --wait=false || true

  # 3) Immediately clear finalizers on any remaining PVCs
  echo "Clearing PVC finalizers in $NS..."
  for PVC in $(kubectl get pvc -n "$NS" --no-headers 2>/dev/null | awk '{print $1}'); do
    echo "  Patching $PVC"
    kubectl patch pvc "$PVC" -n "$NS" \
      -p '{"metadata":{"finalizers":null}}' --type=merge || true
  done
done

echo
echo "Done. PVCs and pods are being removed; ArgoCD will recreate them on next sync."
