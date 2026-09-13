#!/bin/bash

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"
INVENTORY="$ROOT_DIR/ansible/inventory/hosts.ini"

IP1=$(terraform -chdir="$TF_DIR" output -raw public_ip)
IP2=$(terraform -chdir="$TF_DIR" output -raw public_ip_2)

cat > "$INVENTORY" <<EOF
[cloud]
cloud1 ansible_host=$IP1 ansible_user=aurodrig ansible_ssh_private_key_file=~/.ssh/google_compute_engine
cloud2 ansible_host=$IP2 ansible_user=aurodrig ansible_ssh_private_key_file=~/.ssh/google_compute_engine
EOF

echo "Inventory actualizado:"
cat "$INVENTORY"