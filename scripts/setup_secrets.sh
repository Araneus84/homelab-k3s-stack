#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Interactive Secrets Setup
# ==============================================================================
# Guided wizard to generate SealedSecrets for the homelab stack.
# Uses the existing seal-secret.sh helper.
# ==============================================================================

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR=$(dirname "$0")
SEAL_HELPER="${SCRIPT_DIR}/seal-secret.sh"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}       Homelab Interactive Secrets Setup Wizard                 ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "This script will ask for your sensitive passwords/tokens and"
echo -e "generate encrypted SealedSecrets safe for Git."
echo ""

check_prereqs() {
    if ! command -v kubeseal &>/dev/null; then
        echo -e "${YELLOW}Warning: kubeseal not found.${NC}"
        echo "Please install kubeseal or the script will fail."
        exit 1
    fi
}

seal_it() {
    local secret_name=$1
    local namespace=$2
    local key=$3
    local prompt=$4

    echo ""
    echo -e "${YELLOW}Configuring: ${secret_name} (${namespace})${NC}"
    read -sp "$prompt: " secret_value
    echo ""
    
    if [[ -z "$secret_value" ]]; then
        echo "Skipping..."
        return
    fi

    # Run the helper script
    $SEAL_HELPER "$secret_name" "$namespace" "$key" "$secret_value"
    echo -e "${GREEN}✓ Created ${secret_name}.sealed.yaml${NC}"
}

# 1. Pi-hole Password
seal_it "pihole-admin" "dns" "password" "Enter Pi-hole Web Admin Password"

# 2. Grafana Admin Password
seal_it "grafana-admin-credentials" "monitoring" "admin-password" "Enter Grafana Admin Password"

# 3. Vaultwarden Admin Token
seal_it "vaultwarden-admin" "security" "admin-token" "Enter Vaultwarden Admin Token (generates full access)"

# 4. Plex Claim Token (Optional)
echo ""
echo -e "${BLUE}--- Optional Services ---${NC}"
echo "Get a claim token from https://www.plex.tv/claim/ (valid for 4 minutes)"
seal_it "plex-claim" "media" "claimToken" "Enter Plex Claim Token"

# 5. Generic VPN Credentials (Example for Prowlarr/QBittorrent if needed)
# seal_it "vpn-auth" "media" "password" "Enter VPN Password"

echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}Secrets generation complete!${NC}"
echo "The following files have been created:"
ls -1 *.sealed.yaml 2>/dev/null || echo "No files created."
echo ""
echo "To apply them:"
echo "  kubectl apply -f *.sealed.yaml"
echo ""
echo "To save them:"
echo "  git add *.sealed.yaml"
echo "  git commit -m 'chore: update sealed secrets'"
echo -e "${BLUE}================================================================${NC}"
