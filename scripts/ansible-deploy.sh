#!/bin/bash
# Ansible deployment script for configuration management

set -e

ENVIRONMENT=${1:-dev}
PLAYBOOK=${2:-site.yml}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

echo "⚙️  Ansible Configuration Management - $ENVIRONMENT"
echo "Playbook: $PLAYBOOK"
echo "----------------------------------------"

cd ansible

# Check if inventory exists
INVENTORY="inventories/$ENVIRONMENT/hosts.yml"
if [[ ! -f "$INVENTORY" ]]; then
    echo "Error: Inventory file $INVENTORY not found"
    exit 1
fi

# Check if playbook exists
PLAYBOOK_PATH="playbooks/$PLAYBOOK"
if [[ ! -f "$PLAYBOOK_PATH" ]]; then
    echo "Error: Playbook $PLAYBOOK_PATH not found"
    exit 1
fi

echo "🔧 Running Ansible playbook..."
echo "Inventory: $INVENTORY"
echo "Playbook: $PLAYBOOK_PATH"

# Run the playbook
ansible-playbook -i "$INVENTORY" "$PLAYBOOK_PATH" -v

echo "✅ Ansible configuration completed successfully"

cd ..

# Show available playbooks
echo ""
echo "📚 Available playbooks:"
echo "  site.yml        - Complete site configuration"
echo "  deploy.yml      - Application deployment"
echo "  maintenance.yml - System maintenance tasks"
echo ""
echo "Usage: $0 <environment> <playbook>"
echo "Example: $0 dev deploy.yml"