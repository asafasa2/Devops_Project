#!/bin/bash

# Ansible Practice Lab Startup Script
# This script sets up and starts the Ansible learning environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    print_status "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Docker is running"
}

# Check if Docker Compose is available
check_docker_compose() {
    print_status "Checking Docker Compose..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Build Docker images
build_images() {
    print_status "Building Docker images for Ansible lab..."
    
    # Use docker compose if available, otherwise docker-compose
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    $COMPOSE_CMD -f ansible-practice-lab.yml build
    print_success "Docker images built successfully"
}

# Start the lab environment
start_lab() {
    print_status "Starting Ansible practice lab environment..."
    
    # Use docker compose if available, otherwise docker-compose
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    $COMPOSE_CMD -f ansible-practice-lab.yml up -d
    print_success "Lab environment started"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for SSH services to be available
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec ansible-control ansible all -m ping &> /dev/null; then
            print_success "All managed nodes are ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Some services may not be fully ready. You can check manually."
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for services..."
        sleep 5
        ((attempt++))
    done
}

# Setup SSH keys
setup_ssh_keys() {
    print_status "Setting up SSH keys for passwordless access..."
    
    # Copy SSH public key to managed nodes
    for node in web-server-1 web-server-2 db-server-1 centos-server; do
        if docker ps --format "table {{.Names}}" | grep -q "^${node}$"; then
            docker exec ansible-control ssh-copy-id -o StrictHostKeyChecking=no root@${node} 2>/dev/null || true
            docker exec ansible-control ssh-copy-id -o StrictHostKeyChecking=no ansible@${node} 2>/dev/null || true
        fi
    done
    
    print_success "SSH keys configured"
}

# Display connection information
show_connection_info() {
    print_success "Ansible Practice Lab is ready!"
    echo
    echo "=== Connection Information ==="
    echo "Control Node: docker exec -it ansible-control bash"
    echo "Web Server 1: http://localhost:8081"
    echo "Web Server 2: http://localhost:8082"
    echo "Database Server: localhost:3306"
    echo
    echo "=== Quick Start Commands ==="
    echo "1. Connect to control node:"
    echo "   docker exec -it ansible-control bash"
    echo
    echo "2. Test connectivity:"
    echo "   ansible all -m ping"
    echo
    echo "3. List all hosts:"
    echo "   ansible all --list-hosts"
    echo
    echo "4. Run a simple playbook:"
    echo "   ansible-playbook /lab-files/exercises/basic-playbook-solution.yml"
    echo
    echo "=== Lab Files Location ==="
    echo "Exercises: /lab-files/exercises/"
    echo "Templates: /lab-files/templates/"
    echo "Assessments: /lab-files/assessments/"
    echo
    echo "=== Stopping the Lab ==="
    echo "To stop the lab environment:"
    if docker compose version &> /dev/null; then
        echo "docker compose -f ansible-practice-lab.yml down"
    else
        echo "docker-compose -f ansible-practice-lab.yml down"
    fi
}

# Cleanup function
cleanup_lab() {
    print_status "Stopping Ansible practice lab..."
    
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    $COMPOSE_CMD -f ansible-practice-lab.yml down
    print_success "Lab environment stopped"
}

# Main execution
main() {
    echo "=== Ansible Practice Lab Setup ==="
    echo
    
    # Handle command line arguments
    case "${1:-start}" in
        "start")
            check_docker
            check_docker_compose
            build_images
            start_lab
            sleep 10  # Give services time to start
            setup_ssh_keys
            wait_for_services
            show_connection_info
            ;;
        "stop")
            cleanup_lab
            ;;
        "restart")
            cleanup_lab
            sleep 5
            main start
            ;;
        "status")
            if docker compose version &> /dev/null; then
                docker compose -f ansible-practice-lab.yml ps
            else
                docker-compose -f ansible-practice-lab.yml ps
            fi
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status}"
            echo "  start   - Start the Ansible practice lab"
            echo "  stop    - Stop the Ansible practice lab"
            echo "  restart - Restart the Ansible practice lab"
            echo "  status  - Show lab container status"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"