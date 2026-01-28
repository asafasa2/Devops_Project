#!/bin/bash
# Complete monitoring setup script for DevOps Practice Environment

set -e

echo "🚀 Setting up DevOps Practice Environment Monitoring Stack..."

# Check if Docker and Docker Compose are available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating monitoring directories..."
mkdir -p monitoring/prometheus/data
mkdir -p monitoring/grafana/data
mkdir -p monitoring/elasticsearch/data
mkdir -p monitoring/kibana/data
mkdir -p monitoring/logstash/data

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R 1000:1000 monitoring/grafana/data
sudo chown -R 1000:1000 monitoring/elasticsearch/data
sudo chown -R 1000:1000 monitoring/kibana/data
sudo chown -R 1000:1000 monitoring/logstash/data

# Start monitoring services
echo "🐳 Starting monitoring services..."
docker-compose up -d prometheus alertmanager node-exporter cadvisor postgres-exporter redis-exporter grafana elasticsearch logstash kibana filebeat

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."

# Wait for Prometheus
echo "Waiting for Prometheus..."
until curl -s http://localhost:9090/-/ready | grep -q "Prometheus is Ready"; do
  sleep 5
done
echo "✅ Prometheus is ready"

# Wait for Grafana
echo "Waiting for Grafana..."
until curl -s http://localhost:3001/api/health | grep -q "ok"; do
  sleep 5
done
echo "✅ Grafana is ready"

# Wait for Elasticsearch
echo "Waiting for Elasticsearch..."
until curl -s http://localhost:9200/_cluster/health | grep -q "yellow\|green"; do
  sleep 10
done
echo "✅ Elasticsearch is ready"

# Wait for Kibana
echo "Waiting for Kibana..."
until curl -s http://localhost:5601/api/status | grep -q "available"; do
  sleep 10
done
echo "✅ Kibana is ready"

# Setup Kibana index patterns
echo "🔧 Setting up Kibana..."
./monitoring/scripts/setup-kibana.sh

echo "🎉 Monitoring stack setup complete!"
echo ""
echo "📊 Access your monitoring tools:"
echo "  • Prometheus: http://localhost:9090"
echo "  • Grafana: http://localhost:3001 (admin/admin123)"
echo "  • Alertmanager: http://localhost:9093"
echo "  • Elasticsearch: http://localhost:9200"
echo "  • Kibana: http://localhost:5601"
echo ""
echo "📈 Pre-configured dashboards:"
echo "  • System Overview: Available in Grafana"
echo "  • Learning Platform Metrics: Available in Grafana"
echo "  • Log Analysis: Available in Kibana"
echo ""
echo "🔔 Alerting:"
echo "  • Prometheus alerts are configured for system and application metrics"
echo "  • Alertmanager will send notifications via webhook"
echo ""
echo "📝 Logs:"
echo "  • All container logs are automatically collected by Filebeat"
echo "  • Logs are processed by Logstash and stored in Elasticsearch"
echo "  • View and search logs in Kibana"