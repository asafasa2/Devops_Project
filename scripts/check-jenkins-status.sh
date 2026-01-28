#!/bin/bash

echo "🔍 Checking Jenkins status..."

# Check if container is running
if docker compose ps jenkins | grep -q "Up"; then
    echo "✅ Jenkins container is running"
    
    # Check HTTP response
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login)
    
    case $response in
        200)
            echo "✅ Jenkins is fully accessible at http://localhost:8080"
            echo "   Username: admin"
            echo "   Password: admin123"
            ;;
        503)
            echo "⏳ Jenkins is starting up (HTTP 503)"
            echo "   This is normal during initialization"
            echo "   Please wait a few more minutes"
            ;;
        000)
            echo "❌ Jenkins is not responding"
            echo "   Check if the service is running: docker compose ps jenkins"
            ;;
        *)
            echo "⚠️  Jenkins returned HTTP $response"
            ;;
    esac
    
    # Show recent logs
    echo ""
    echo "📋 Recent Jenkins logs:"
    docker compose logs jenkins --tail 3
    
else
    echo "❌ Jenkins container is not running"
    echo "   Start it with: docker compose up -d jenkins"
fi

echo ""
echo "🔗 Other services:"
echo "   cAdvisor: http://localhost:8083"
echo "   Frontend: http://localhost:3000"
echo "   Grafana:  http://localhost:3001"