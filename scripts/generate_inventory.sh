#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INVENTORY="$ROOT_DIR/ansible/inventory/hosts.ini"

PROJECT_ID="${CLOUD1_PROJECT_ID:-cloud-1-506415}"
ZONE="${CLOUD1_ZONE:-us-central1-c}"
SSH_USER="${CLOUD1_SSH_USER:-aurodrig}"
SSH_KEY="${CLOUD1_SSH_KEY:-$HOME/.ssh/google_compute_engine}"

IP1=$(gcloud compute instances describe cloud-1-vm \
    --project "$PROJECT_ID" \
    --zone "$ZONE" \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

IP2=$(gcloud compute instances describe cloud-1-vm-2 \
    --project "$PROJECT_ID" \
    --zone "$ZONE" \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

{
    echo "[cloud]"

    if [ -n "$IP1" ]; then
        echo "cloud1 ansible_host=$IP1 ansible_user=$SSH_USER ansible_ssh_private_key_file=$SSH_KEY"
    fi

    if [ -n "$IP2" ]; then
        echo "cloud2 ansible_host=$IP2 ansible_user=$SSH_USER ansible_ssh_private_key_file=$SSH_KEY"
    fi
} > "$INVENTORY"

echo "Inventory actualizado:"
cat "$INVENTORY"
