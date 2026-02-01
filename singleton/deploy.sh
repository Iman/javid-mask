#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"
CREDENTIALS_FILE="$SCRIPT_DIR/credentials.txt"

echo "=========================================="
echo "Raspberry Pi WiFi Proxy Deployment"
echo "=========================================="
echo ""

if [ ! -f "$ANSIBLE_DIR/inventory.yml" ]; then
    echo "ERROR: Ansible inventory not found!"
    echo "Expected: $ANSIBLE_DIR/inventory.yml"
    exit 1
fi

if ! command -v ansible-playbook &> /dev/null; then
    echo "ERROR: Ansible is not installed!"
    echo ""
    echo "Install Ansible:"
    echo "  macOS: brew install ansible"
    echo "  Ubuntu: sudo apt install ansible"
    exit 1
fi

echo "Checking connectivity to Raspberry Pi..."
if ! ansible -i "$ANSIBLE_DIR/inventory.yml" raspberry_pi -m ping &> /dev/null; then
    echo ""
    echo "WARNING: Cannot connect to Raspberry Pi"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ Raspberry Pi is reachable"
fi

echo ""
echo "Configuration:"
echo "  Ansible Directory: $ANSIBLE_DIR"
echo "  Credentials File: $CREDENTIALS_FILE"
echo ""

read -p "Review configuration in ansible/group_vars/all.yml? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ${EDITOR:-nano} "$ANSIBLE_DIR/group_vars/all.yml"
fi

echo ""
echo "Starting deployment..."
echo ""

cd "$ANSIBLE_DIR"

if ansible-playbook -i inventory.yml playbook.yml; then
    echo ""
    echo "=========================================="
    echo "✓ Deployment Successful!"
    echo "=========================================="
    echo ""
    echo "Credentials saved to:"
    echo "  $CREDENTIALS_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Reboot the Raspberry Pi:"
    echo "     ssh admin@10.0.0.242 'sudo reboot'"
    echo ""
    echo "  2. Wait 1-2 minutes for reboot"
    echo ""
    echo "  3. Check credentials:"
    echo "     cat $CREDENTIALS_FILE"
    echo ""
    echo "  4. Connect to WiFi using SSID and password from credentials file"
    echo ""
    echo "  5. Access Pi-hole admin:"
    echo "     http://192.168.50.1/admin"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "✗ Deployment Failed!"
    echo "=========================================="
    echo ""
    echo "Check the error messages above."
    echo "Common issues:"
    echo "  - SSH connection problems"
    echo "  - Incorrect IP address in inventory.yml"
    echo "  - Missing sudo permissions"
    echo ""
    echo "Run with verbose output:"
    echo "  cd $ANSIBLE_DIR"
    echo "  ansible-playbook -i inventory.yml playbook.yml -vvv"
    exit 1
fi
