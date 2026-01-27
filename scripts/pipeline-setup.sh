#!/bin/bash
# Pipeline setup script for CI/CD infrastructure

set -e

ENVIRONMENT=${1:-dev}

echo "🔧 Setting up CI/CD pipeline infrastructure for $ENVIRONMENT"
echo "============================================================"

# Create Jenkins directories
echo "📁 Creating Jenkins directories..."
mkdir -p jenkins/{casc_configs,plugins,jobs,secrets}

# Create pipeline configuration
echo "⚙️ Setting up pipeline configuration..."

# Jenkins plugins list
cat > jenkins/plugins/plugins.txt << EOF
# Core plugins
workflow-aggregator:latest
pipeline-stage-view:latest
blueocean:latest
docker-workflow:latest
docker-plugin:latest

# SCM plugins
git:latest
github:latest
github-branch-source:latest

# Build tools
nodejs:latest
terraform:latest
ansible:latest

# Testing and quality
junit:latest
jacoco:latest
sonarqube-scanner:latest

# Notifications
slack:latest
email-ext:latest

# Security
role-strategy:latest
matrix-auth:latest

# Configuration as Code
configuration-as-code:latest
job-dsl:latest

# Monitoring
prometheus:latest
build-metrics:latest
EOF

# Create Jenkins secrets template
cat > jenkins/secrets/secrets.env.template << EOF
# Jenkins Secrets Template
# Copy this file to secrets.env and fill in the values

JENKINS_ADMIN_PASSWORD=change_me
JENKINS_DEV_PASSWORD=change_me
DOCKER_REGISTRY_PASSWORD=change_me
SLACK_TOKEN=change_me
SSH_PRIVATE_KEY=change_me
GITHUB_TOKEN=change_me
SONAR_TOKEN=change_me
EOF

# Create pipeline utilities
echo "🛠️ Creating pipeline utilities..."

# Health check script
cat > scripts/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for deployed services

ENVIRONMENT=${1:-dev}
TIMEOUT=${2:-30}

echo "🏥 Running health checks for $ENVIRONMENT environment..."

services=(
    "http://localhost:3000/health:Web Frontend"
    "http://localhost:4000/health:API Gateway"
    "http://localhost:3001/api/health:Grafana"
    "http://localhost:8080/login:Jenkins"
)

failed_checks=0

for service in "${services[@]}"; do
    IFS=':' read -r url name <<< "$service"
    
    echo -n "Checking $name... "
    
    if curl -f -s --max-time $TIMEOUT "$url" > /dev/null; then
        echo "✅ Healthy"
    else
        echo "❌ Unhealthy"
        ((failed_checks++))
    fi
done

if [ $failed_checks -eq 0 ]; then
    echo "🎉 All services are healthy!"
    exit 0
else
    echo "⚠️ $failed_checks service(s) failed health checks"
    exit 1
fi
EOF

chmod +x scripts/health-check.sh

# Create deployment verification script
cat > scripts/verify-deployment.sh << 'EOF'
#!/bin/bash
# Deployment verification script

ENVIRONMENT=${1:-dev}

echo "🔍 Verifying deployment for $ENVIRONMENT environment..."

# Check if all containers are running
echo "📦 Checking container status..."
docker-compose -f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml ps

# Run health checks
echo "🏥 Running health checks..."
./scripts/health-check.sh $ENVIRONMENT

# Check logs for errors
echo "📋 Checking for errors in logs..."
error_count=$(docker-compose -f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml logs --since=5m 2>&1 | grep -i error | wc -l)

if [ $error_count -gt 0 ]; then
    echo "⚠️ Found $error_count error(s) in recent logs"
    docker-compose -f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml logs --since=5m | grep -i error
else
    echo "✅ No errors found in recent logs"
fi

echo "✅ Deployment verification completed"
EOF

chmod +x scripts/verify-deployment.sh

# Create rollback script
cat > scripts/rollback.sh << 'EOF'
#!/bin/bash
# Rollback script for failed deployments

ENVIRONMENT=${1:-dev}
PREVIOUS_VERSION=${2}

if [ -z "$PREVIOUS_VERSION" ]; then
    echo "Error: Previous version not specified"
    echo "Usage: $0 <environment> <previous_version>"
    exit 1
fi

echo "🔄 Rolling back $ENVIRONMENT to version $PREVIOUS_VERSION..."

# Update environment file with previous version
sed -i "s/BUILD_VERSION=.*/BUILD_VERSION=$PREVIOUS_VERSION/g" .env.$ENVIRONMENT

# Redeploy with previous version
docker-compose -f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml up -d

# Wait for services to stabilize
sleep 30

# Verify rollback
./scripts/verify-deployment.sh $ENVIRONMENT

echo "✅ Rollback completed successfully"
EOF

chmod +x scripts/rollback.sh

# Create monitoring setup script
cat > scripts/setup-monitoring.sh << 'EOF'
#!/bin/bash
# Setup monitoring and alerting

ENVIRONMENT=${1:-dev}

echo "📊 Setting up monitoring for $ENVIRONMENT environment..."

# Create Grafana dashboards directory
mkdir -p monitoring/grafana/dashboards

# Create Prometheus alerts
mkdir -p monitoring/prometheus/alerts

# Basic alert rules
cat > monitoring/prometheus/alerts/basic.yml << 'ALERT_EOF'
groups:
  - name: basic-alerts
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} has been down for more than 1 minute"
      
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 80% for more than 5 minutes"
      
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes"
ALERT_EOF

echo "✅ Monitoring setup completed"
EOF

chmod +x scripts/setup-monitoring.sh

# Run monitoring setup
./scripts/setup-monitoring.sh $ENVIRONMENT

echo "✅ CI/CD pipeline infrastructure setup completed!"
echo ""
echo "Next steps:"
echo "1. Copy jenkins/secrets/secrets.env.template to jenkins/secrets/secrets.env and fill in values"
echo "2. Start Jenkins: docker-compose -f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml up jenkins"
echo "3. Access Jenkins at http://localhost:8080"
echo "4. Configure GitHub webhooks to trigger builds"
echo "5. Set up Slack notifications (optional)"