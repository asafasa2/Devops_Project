#!/bin/bash
# Terraform deployment script for infrastructure provisioning

set -e

ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(init|plan|apply|destroy|output)$ ]]; then
    echo "Error: Invalid action. Use: init, plan, apply, destroy, or output"
    exit 1
fi

echo "🏗️  Terraform Infrastructure - $ENVIRONMENT"
echo "Action: $ACTION"
echo "----------------------------------------"

cd terraform

# Environment-specific variables file
VAR_FILE="environments/$ENVIRONMENT.tfvars"
if [[ ! -f "$VAR_FILE" ]]; then
    echo "Error: Variables file $VAR_FILE not found"
    exit 1
fi

case $ACTION in
    init)
        echo "🔧 Initializing Terraform..."
        terraform init
        echo "✓ Terraform initialized successfully"
        ;;
    plan)
        echo "📋 Planning infrastructure changes..."
        terraform plan -var-file="$VAR_FILE"
        ;;
    apply)
        echo "🚀 Applying infrastructure changes..."
        terraform apply -var-file="$VAR_FILE" -auto-approve
        echo "✓ Infrastructure deployed successfully"
        
        echo ""
        echo "📊 Infrastructure outputs:"
        terraform output
        ;;
    destroy)
        echo "🗑️  Destroying infrastructure..."
        read -p "Are you sure you want to destroy the $ENVIRONMENT infrastructure? (yes/no): " confirm
        if [[ $confirm == "yes" ]]; then
            terraform destroy -var-file="$VAR_FILE" -auto-approve
            echo "✓ Infrastructure destroyed successfully"
        else
            echo "❌ Destruction cancelled"
        fi
        ;;
    output)
        echo "📊 Infrastructure outputs:"
        terraform output
        ;;
esac

cd ..
echo "✅ Terraform operation completed successfully"