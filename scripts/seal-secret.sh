#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sealed Secret Helper
# ==============================================================================
# Creates a sealed secret from a key-value pair.
#
# Usage:
#   ./seal-secret.sh <secret-name> <namespace> <key> <value>
#
# Examples:
#   ./seal-secret.sh pihole-admin dns password 'my-pihole-password'
#   ./seal-secret.sh grafana-admin-credentials monitoring admin-password 'my-grafana-pass'
#   ./seal-secret.sh vaultwarden-admin security admin-token 'my-admin-token'
#
# Prerequisites:
#   - kubeseal CLI installed
#   - Sealed Secrets controller running in cluster
#   - kubectl configured
# ==============================================================================

SECRET_NAME="${1:?Usage: seal-secret.sh <secret-name> <namespace> <key> <value>}"
NAMESPACE="${2:?Usage: seal-secret.sh <secret-name> <namespace> <key> <value>}"
KEY="${3:?Usage: seal-secret.sh <secret-name> <namespace> <key> <value>}"
VALUE="${4:?Usage: seal-secret.sh <secret-name> <namespace> <key> <value>}"

# Check for kubeseal
if ! command -v kubeseal &>/dev/null; then
    echo "ERROR: kubeseal is not installed."
    echo ""
    echo "Install it with:"
    echo "  # Linux amd64"
    echo "  wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.3/kubeseal-0.27.3-linux-amd64.tar.gz"
    echo "  tar -xvzf kubeseal-0.27.3-linux-amd64.tar.gz"
    echo "  sudo install -m 755 kubeseal /usr/local/bin/kubeseal"
    exit 1
fi

echo "Creating sealed secret:"
echo "  Name:      $SECRET_NAME"
echo "  Namespace: $NAMESPACE"
echo "  Key:       $KEY"
echo "  Value:     ********"
echo ""

# Create the secret and seal it
kubectl create secret generic "$SECRET_NAME" \
    --namespace "$NAMESPACE" \
    --from-literal="$KEY=$VALUE" \
    --dry-run=client -o yaml | \
    kubeseal \
        --controller-namespace infrastructure \
        --controller-name sealed-secrets \
        --format yaml > "${SECRET_NAME}.sealed.yaml"

echo "Sealed secret written to: ${SECRET_NAME}.sealed.yaml"
echo ""
echo "Apply it with:"
echo "  kubectl apply -f ${SECRET_NAME}.sealed.yaml"
echo ""
echo "Or commit the .sealed.yaml file to git (it's safe -- encrypted with the cluster's key)."
