#!/bin/bash

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"
INVENTORY="$ROOT_DIR/ansible/inventory/hosts.ini"

SSH_USER="${CLOUD1_SSH_USER:-aurodrig}"
SSH_KEY="${CLOUD1_SSH_KEY:-$HOME/.ssh/google_compute_engine}"

IP1=$(terraform -chdir="$TF_DIR" output -raw public_ip)
IP2=$(terraform -chdir="$TF_DIR" output -raw public_ip_2)

cat > "$INVENTORY" <<EOF
[cloud]
cloud1 ansible_host=$IP1 ansible_user=$SSH_USER ansible_ssh_private_key_file=$SSH_KEY
cloud2 ansible_host=$IP2 ansible_user=$SSH_USER ansible_ssh_private_key_file=$SSH_KEY
EOF

echo "Inventory actualizado:"
cat "$INVENTORY"