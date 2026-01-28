#!/bin/bash

# Fix Jenkins Port Conflict Script
# This script resolves the port conflict between Jenkins and cAdvisor

set -e

echo "🔧 Fixing Jenkins port conflict..."

# Check if Docker Compose is running
if docker compose ps | grep -q "Up"; then
    echo "📦 Stopping conflicting services..."
    
    # Stop Jenkins and cAdvisor specifically
    docker compose stop jenkins cadvisor || true
    
    echo "⏳ Waiting for services to stop..."
    sleep 5
    
    # Remove containers to ensure clean restart
    docker compose rm -f jenkins cadvisor || true
    
    echo "🚀 Starting services with fixed ports..."
    
    # Start cAdvisor first (now on port 8083)
    docker compose up -d cadvisor
    
    # Wait a moment
    sleep 3
    
    # Start Jenkins (on port 8080)
    docker compose up -d jenkins
    
    echo "⏳ Waiting for Jenkins to initialize..."
    sleep 30
    
    # Check if Jenkins is accessible
    echo "🔍 Checking Jenkins accessibility..."
    if curl -f http://localhost:8080/login >/dev/null 2>&1; then
        echo "✅ Jenkins is now accessible at http://localhost:8080"
        echo "   Username: admin"
        echo "   Password: admin123"
    else
        echo "⚠️  Jenkins is starting up, please wait a few more minutes"
        echo "   You can check the logs with: docker compose logs jenkins"
    fi
    
    # Check cAdvisor
    echo "🔍 Checking cAdvisor accessibility..."
    if curl -f http://localhost:8083 >/dev/null 2>&1; then
        echo "✅ cAdvisor is now accessible at http://localhost:8083"
    else
        echo "⚠️  cAdvisor is starting up, please wait a moment"
    fi
    
else
    echo "📦 Starting all services..."
    docker compose up -d
    
    echo "⏳ Waiting for services to initialize..."
    sleep 60
    
    echo "✅ All services started. Jenkins should be accessible at http://localhost:8080"
fi

echo ""
echo "🎯 Service URLs:"
echo "   Jenkins:  http://localhost:8080 (admin/admin123)"
echo "   cAdvisor: http://localhost:8083"
echo "   Frontend: http://localhost:3000"
echo "   Grafana:  http://localhost:3001 (admin/admin123)"
echo ""
echo "📋 To check service status: docker compose ps"
echo "📋 To view Jenkins logs: docker compose logs jenkins"