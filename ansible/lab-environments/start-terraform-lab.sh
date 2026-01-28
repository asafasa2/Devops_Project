#!/bin/bash

# Terraform Practice Lab Startup Script
# This script sets up a complete Terraform learning environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Lab configuration
LAB_NAME="terraform-practice-lab"
COMPOSE_FILE="terraform-practice-lab.yml"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Starting Terraform Practice Lab Environment${NC}"
echo "=================================================="

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker is running${NC}"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker Compose is not available. Please install Docker Compose.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker Compose is available${NC}"
}

# Function to build and start lab environment
start_lab() {
    echo -e "${YELLOW}🔨 Building lab environment...${NC}"
    
    cd "$LAB_DIR"
    
    # Build custom images
    docker-compose -f "$COMPOSE_FILE" build
    
    echo -e "${YELLOW}🚀 Starting lab services...${NC}"
    
    # Start all services
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
    sleep 30
    
    # Check service health
    check_services
}

# Function to check if services are healthy
check_services() {
    echo -e "${YELLOW}🔍 Checking service health...${NC}"
    
    # Check Terraform workspace
    if docker exec terraform-workspace terraform version >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Terraform workspace is ready${NC}"
    else
        echo -e "${RED}❌ Terraform workspace is not ready${NC}"
    fi
    
    # Check Docker daemon
    if docker exec terraform-workspace docker --host tcp://docker-daemon:2376 version >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker daemon is accessible${NC}"
    else
        echo -e "${RED}❌ Docker daemon is not accessible${NC}"
    fi
    
    # Check MinIO
    if curl -s http://localhost:9000/minio/health/live >/dev/null 2>&1; then
        echo -e "${GREEN}✅ MinIO S3 backend is ready${NC}"
    else
        echo -e "${YELLOW}⚠️  MinIO may still be starting up${NC}"
    fi
}

# Function to display lab information
show_lab_info() {
    echo ""
    echo -e "${BLUE}🎯 Terraform Practice Lab is Ready!${NC}"
    echo "=================================="
    echo ""
    echo -e "${GREEN}📚 Available Services:${NC}"
    echo "  • Terraform Workspace: docker exec -it terraform-workspace bash"
    echo "  • MinIO Console: http://localhost:9001 (terraform/terraform123)"
    echo "  • Lab UI: http://localhost:3000"
    echo ""
    echo -e "${GREEN}🛠️  Quick Start Commands:${NC}"
    echo "  • Enter workspace: docker exec -it terraform-workspace bash"
    echo "  • Run lab exercises: cd /workspace && ls"
    echo "  • Check Terraform: terraform version"
    echo "  • Test Docker provider: docker --host tcp://docker-daemon:2376 ps"
    echo ""
    echo -e "${GREEN}📖 Lab Exercises Available:${NC}"
    echo "  • Basic Terraform Setup (/workspace/01-basic-setup)"
    echo "  • Variables and Outputs (/workspace/02-variables-outputs)"
    echo "  • State Management (/workspace/03-state-management)"
    echo "  • Modules Development (/workspace/04-modules)"
    echo "  • Advanced Scenarios (/workspace/05-advanced)"
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "  • All exercises include step-by-step instructions"
    echo "  • Use 'terraform fmt' to format your code"
    echo "  • Use 'terraform validate' to check syntax"
    echo "  • State files are stored in MinIO for remote backend practice"
    echo ""
    echo -e "${BLUE}🛑 To stop the lab: docker-compose -f $COMPOSE_FILE down${NC}"
}

# Function to stop lab environment
stop_lab() {
    echo -e "${YELLOW}🛑 Stopping Terraform Practice Lab...${NC}"
    cd "$LAB_DIR"
    docker-compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}✅ Lab environment stopped${NC}"
}

# Function to clean up lab environment
cleanup_lab() {
    echo -e "${YELLOW}🧹 Cleaning up Terraform Practice Lab...${NC}"
    cd "$LAB_DIR"
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    docker system prune -f
    echo -e "${GREEN}✅ Lab environment cleaned up${NC}"
}

# Function to show help
show_help() {
    echo "Terraform Practice Lab Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start the lab environment (default)"
    echo "  stop      Stop the lab environment"
    echo "  restart   Restart the lab environment"
    echo "  cleanup   Stop and remove all lab data"
    echo "  status    Show lab environment status"
    echo "  logs      Show lab service logs"
    echo "  help      Show this help message"
}

# Function to show lab status
show_status() {
    echo -e "${BLUE}📊 Terraform Lab Status${NC}"
    echo "======================"
    cd "$LAB_DIR"
    docker-compose -f "$COMPOSE_FILE" ps
}

# Function to show logs
show_logs() {
    cd "$LAB_DIR"
    docker-compose -f "$COMPOSE_FILE" logs -f
}

# Main script logic
case "${1:-start}" in
    start)
        check_docker
        check_docker_compose
        start_lab
        show_lab_info
        ;;
    stop)
        stop_lab
        ;;
    restart)
        stop_lab
        sleep 5
        check_docker
        check_docker_compose
        start_lab
        show_lab_info
        ;;
    cleanup)
        cleanup_lab
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac