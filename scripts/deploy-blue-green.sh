#!/bin/bash
# Blue-Green Deployment Script for DevOps Practice Environment

set -e

ENVIRONMENT=${1:-dev}
NEW_VERSION=${2}
DEPLOYMENT_TYPE=${3:-blue-green}

if [ -z "$NEW_VERSION" ]; then
    echo "Error: Version not specified"
    echo "Usage: $0 <environment> <version> [deployment-type]"
    exit 1
fi

echo "🔄 Starting Blue-Green Deployment"
echo "Environment: $ENVIRONMENT"
echo "New Version: $NEW_VERSION"
echo "Deployment Type: $DEPLOYMENT_TYPE"
echo "============================================"

# Configuration
COMPOSE_PROJECT_NAME="devops-practice-${ENVIRONMENT}"
BLUE_SUFFIX="blue"
GREEN_SUFFIX="green"
HEALTH_CHECK_TIMEOUT=120
HEALTH_CHECK_INTERVAL=10

# Determine current and new environments
get_current_environment() {
    if docker-compose -p "${COMPOSE_PROJECT_NAME}-${BLUE_SUFFIX}" ps -q > /dev/null 2>&1; then
        if [ "$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${BLUE_SUFFIX}" ps -q | wc -l)" -gt 0 ]; then
            echo "blue"
            return
        fi
    fi
    
    if docker-compose -p "${COMPOSE_PROJECT_NAME}-${GREEN_SUFFIX}" ps -q > /dev/null 2>&1; then
        if [ "$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${GREEN_SUFFIX}" ps -q | wc -l)" -gt 0 ]; then
            echo "green"
            return
        fi
    fi
    
    echo "blue"  # Default to blue if nothing is running
}

CURRENT_ENV=$(get_current_environment)
if [ "$CURRENT_ENV" = "blue" ]; then
    NEW_ENV="green"
else
    NEW_ENV="blue"
fi

echo "📊 Current environment: $CURRENT_ENV"
echo "🆕 New environment: $NEW_ENV"

# Function to check service health
check_health() {
    local env_suffix=$1
    local max_attempts=$((HEALTH_CHECK_TIMEOUT / HEALTH_CHECK_INTERVAL))
    local attempt=1
    
    echo "🏥 Checking health of $env_suffix environment..."
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts..."
        
        # Check if containers are running
        if ! docker-compose -p "${COMPOSE_PROJECT_NAME}-${env_suffix}" ps -q > /dev/null 2>&1; then
            echo "❌ No containers found for $env_suffix environment"
            return 1
        fi
        
        # Get the port mappings for the new environment
        local frontend_port=$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${env_suffix}" port frontend 3000 2>/dev/null | cut -d: -f2 || echo "")
        local api_port=$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${env_suffix}" port api-gateway 4000 2>/dev/null | cut -d: -f2 || echo "")
        
        if [ -n "$frontend_port" ] && [ -n "$api_port" ]; then
            # Check frontend health
            if curl -f -s "http://localhost:${frontend_port}/health" > /dev/null 2>&1; then
                # Check API health
                if curl -f -s "http://localhost:${api_port}/health" > /dev/null 2>&1; then
                    echo "✅ Health check passed for $env_suffix environment"
                    return 0
                fi
            fi
        fi
        
        echo "⏳ Services not ready yet, waiting ${HEALTH_CHECK_INTERVAL}s..."
        sleep $HEALTH_CHECK_INTERVAL
        attempt=$((attempt + 1))
    done
    
    echo "❌ Health check failed for $env_suffix environment after ${HEALTH_CHECK_TIMEOUT}s"
    return 1
}

# Function to deploy to new environment
deploy_new_environment() {
    echo "🚀 Deploying to $NEW_ENV environment..."
    
    # Create environment-specific compose file
    cat > "docker-compose.${NEW_ENV}.yml" << EOF
version: '3.8'

services:
  frontend:
    image: devops-practice/frontend:${NEW_VERSION}
    container_name: ${COMPOSE_PROJECT_NAME}-${NEW_ENV}-frontend
    environment:
      - NODE_ENV=${ENVIRONMENT}
      - REACT_APP_API_URL=http://localhost:4000
    ports:
      - "0:3000"  # Dynamic port assignment
    networks:
      - ${NEW_ENV}-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  api-gateway:
    image: devops-practice/api-gateway:${NEW_VERSION}
    container_name: ${COMPOSE_PROJECT_NAME}-${NEW_ENV}-api
    environment:
      - NODE_ENV=${ENVIRONMENT}
      - DB_HOST=postgres
      - REDIS_HOST=redis
    ports:
      - "0:4000"  # Dynamic port assignment
    networks:
      - ${NEW_ENV}-network
      - shared-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  learning-service:
    image: devops-practice/learning-service:${NEW_VERSION}
    container_name: ${COMPOSE_PROJECT_NAME}-${NEW_ENV}-learning
    environment:
      - NODE_ENV=${ENVIRONMENT}
      - DB_HOST=postgres
    networks:
      - ${NEW_ENV}-network
      - shared-network
    restart: unless-stopped

  user-service:
    image: devops-practice/user-service:${NEW_VERSION}
    container_name: ${COMPOSE_PROJECT_NAME}-${NEW_ENV}-user
    environment:
      - FLASK_ENV=${ENVIRONMENT}
      - DB_HOST=postgres
      - REDIS_HOST=redis
    networks:
      - ${NEW_ENV}-network
      - shared-network
    restart: unless-stopped

  lab-service:
    image: devops-practice/lab-service:${NEW_VERSION}
    container_name: ${COMPOSE_PROJECT_NAME}-${NEW_ENV}-lab
    environment:
      - SPRING_PROFILES_ACTIVE=${ENVIRONMENT}
      - DB_HOST=postgres
    networks:
      - ${NEW_ENV}-network
      - shared-network
    restart: unless-stopped

  assessment-service:
    image: devops-practice/assessment-service:${NEW_VERSION}
    container_name: ${COMPOSE_PROJECT_NAME}-${NEW_ENV}-assessment
    environment:
      - ENVIRONMENT=${ENVIRONMENT}
      - DB_HOST=postgres
    networks:
      - ${NEW_ENV}-network
      - shared-network
    restart: unless-stopped

networks:
  ${NEW_ENV}-network:
    driver: bridge
  shared-network:
    external: true
    name: devops-practice-shared

EOF

    # Deploy new environment
    docker-compose -f "docker-compose.${NEW_ENV}.yml" -p "${COMPOSE_PROJECT_NAME}-${NEW_ENV}" up -d
    
    # Wait for deployment to complete
    echo "⏳ Waiting for deployment to complete..."
    sleep 30
}

# Function to switch traffic
switch_traffic() {
    echo "🔄 Switching traffic to $NEW_ENV environment..."
    
    # Get port mappings for new environment
    local new_frontend_port=$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${NEW_ENV}" port frontend 3000 | cut -d: -f2)
    local new_api_port=$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${NEW_ENV}" port api-gateway 4000 | cut -d: -f2)
    
    # Update load balancer configuration
    cat > nginx/nginx-${ENVIRONMENT}.conf << EOF
upstream frontend_backend {
    server localhost:${new_frontend_port};
}

upstream api_backend {
    server localhost:${new_api_port};
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://frontend_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api/ {
        proxy_pass http://api_backend/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # Reload nginx configuration
    docker-compose -f docker-compose.yml exec nginx nginx -s reload || {
        echo "⚠️ Failed to reload nginx, restarting container..."
        docker-compose -f docker-compose.yml restart nginx
    }
    
    echo "✅ Traffic switched to $NEW_ENV environment"
}

# Function to cleanup old environment
cleanup_old_environment() {
    echo "🧹 Cleaning up $CURRENT_ENV environment..."
    
    # Stop and remove old environment
    docker-compose -p "${COMPOSE_PROJECT_NAME}-${CURRENT_ENV}" down --remove-orphans
    
    # Remove old compose file
    rm -f "docker-compose.${CURRENT_ENV}.yml"
    
    echo "✅ Cleanup completed"
}

# Function to rollback
rollback() {
    echo "🔄 Rolling back to $CURRENT_ENV environment..."
    
    # Switch traffic back
    local current_frontend_port=$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${CURRENT_ENV}" port frontend 3000 | cut -d: -f2)
    local current_api_port=$(docker-compose -p "${COMPOSE_PROJECT_NAME}-${CURRENT_ENV}" port api-gateway 4000 | cut -d: -f2)
    
    # Update nginx config back to current environment
    cat > nginx/nginx-${ENVIRONMENT}.conf << EOF
upstream frontend_backend {
    server localhost:${current_frontend_port};
}

upstream api_backend {
    server localhost:${current_api_port};
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://frontend_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api/ {
        proxy_pass http://api_backend/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    docker-compose -f docker-compose.yml exec nginx nginx -s reload
    
    # Cleanup failed deployment
    docker-compose -p "${COMPOSE_PROJECT_NAME}-${NEW_ENV}" down --remove-orphans
    rm -f "docker-compose.${NEW_ENV}.yml"
    
    echo "✅ Rollback completed"
}

# Main deployment process
main() {
    # Create shared network if it doesn't exist
    docker network create devops-practice-shared 2>/dev/null || true
    
    # Deploy to new environment
    deploy_new_environment
    
    # Health check new environment
    if check_health "$NEW_ENV"; then
        echo "✅ New environment is healthy"
        
        # Switch traffic
        switch_traffic
        
        # Final health check after traffic switch
        sleep 10
        if curl -f -s "http://localhost/health" > /dev/null 2>&1; then
            echo "✅ Traffic switch successful"
            
            # Cleanup old environment
            if [ "$CURRENT_ENV" != "$NEW_ENV" ]; then
                cleanup_old_environment
            fi
            
            echo "🎉 Blue-Green deployment completed successfully!"
            echo "Active environment: $NEW_ENV"
            echo "Version: $NEW_VERSION"
        else
            echo "❌ Health check failed after traffic switch"
            rollback
            exit 1
        fi
    else
        echo "❌ New environment health check failed"
        rollback
        exit 1
    fi
}

# Trap to handle cleanup on script exit
trap 'echo "🛑 Deployment interrupted"; rollback; exit 1' INT TERM

# Run main deployment
main

echo "✅ Deployment completed successfully!"