#!/bin/bash
# Deployment script for DevOps Practice Environment

set -e

ENVIRONMENT=${1:-dev}
ACTION=${2:-up}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(up|down|restart|logs|ps)$ ]]; then
    echo "Error: Invalid action. Use: up, down, restart, logs, or ps"
    exit 1
fi

echo "🚀 DevOps Practice Environment - $ENVIRONMENT"
echo "Action: $ACTION"
echo "----------------------------------------"

# Set environment file
ENV_FILE=".env.$ENVIRONMENT"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file $ENV_FILE not found"
    exit 1
fi

# Copy environment file
cp "$ENV_FILE" .env
echo "✓ Using environment configuration: $ENV_FILE"

# Compose file selection
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml"

case $ACTION in
    up)
        echo "🔧 Starting services..."
        docker-compose $COMPOSE_FILES up -d
        echo "✓ Services started successfully"
        
        echo "📊 Service status:"
        docker-compose $COMPOSE_FILES ps
        
        echo ""
        echo "🌐 Access URLs:"
        case $ENVIRONMENT in
            dev)
                echo "  Web Frontend: http://localhost:3000"
                echo "  API Gateway:  http://localhost:4000"
                echo "  Grafana:      http://localhost:3001 (admin/admin)"
                echo "  Prometheus:   http://localhost:9090"
                ;;
            staging|prod)
                echo "  Web Frontend: http://localhost:80"
                echo "  Grafana:      http://localhost:3001"
                echo "  Jenkins:      http://localhost:8080"
                echo "  Kibana:       http://localhost:5601"
                ;;
        esac
        ;;
    down)
        echo "🛑 Stopping services..."
        docker-compose $COMPOSE_FILES down
        echo "✓ Services stopped successfully"
        ;;
    restart)
        echo "🔄 Restarting services..."
        docker-compose $COMPOSE_FILES restart
        echo "✓ Services restarted successfully"
        ;;
    logs)
        echo "📋 Showing logs..."
        docker-compose $COMPOSE_FILES logs -f
        ;;
    ps)
        echo "📊 Service status:"
        docker-compose $COMPOSE_FILES ps
        ;;
esac

echo "✅ Operation completed successfully"