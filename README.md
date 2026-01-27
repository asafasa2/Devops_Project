# DevOps Practice Environment

A comprehensive DevOps learning platform that simulates on-premise infrastructure using containerization and infrastructure as code. This environment provides hands-on practice with Docker, Ansible, Terraform, Jenkins, and monitoring tools.

## Architecture Overview

This project implements a multi-tier web application with microservices architecture, including:

- **Frontend**: React.js learning management system
- **Backend**: Multiple microservices (API Gateway, User Management, Learning Management, Assessment, Lab Environment)
- **Database**: PostgreSQL with Redis caching
- **Infrastructure**: Terraform for provisioning, Ansible for configuration
- **CI/CD**: Jenkins pipeline automation
- **Monitoring**: Prometheus, Grafana, ELK stack
- **Load Balancing**: Nginx

## Environment Setup

### Prerequisites

- Docker and Docker Compose
- Terraform >= 1.0
- Ansible >= 2.9
- Git

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd devops-practice-environment
   ```

2. **Choose your environment**
   ```bash
   # Development
   cp .env.dev .env
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   
   # Staging
   cp .env.staging .env
   docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
   
   # Production
   cp .env.prod .env
   # Update passwords in .env file
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

3. **Initialize infrastructure with Terraform**
   ```bash
   cd terraform
   terraform init
   terraform plan -var-file="environments/dev.tfvars"
   terraform apply -var-file="environments/dev.tfvars"
   ```

4. **Configure services with Ansible**
   ```bash
   cd ansible
   ansible-playbook -i inventories/dev/hosts.yml playbooks/site.yml
   ```

## Directory Structure

```
├── terraform/                 # Infrastructure as Code
│   ├── modules/              # Terraform modules
│   └── environments/         # Environment-specific configs
├── ansible/                  # Configuration Management
│   ├── inventories/          # Environment inventories
│   ├── playbooks/           # Ansible playbooks
│   └── roles/               # Ansible roles
├── services/                 # Application services
├── monitoring/              # Monitoring configurations
├── nginx/                   # Load balancer configs
└── docker-compose*.yml      # Container orchestration
```

## Services and Ports

| Service | Development | Staging | Production |
|---------|-------------|---------|------------|
| Web Frontend | 3000 | 80 | 80 |
| API Gateway | 4000 | - | - |
| Grafana | 3001 | 3001 | 3001 |
| Jenkins | 8080 | 8080 | 8080 |
| Kibana | 5601 | 5601 | 5601 |
| PostgreSQL | 5432 | - | - |
| Redis | 6379 | - | - |

## Learning Modules

The platform includes interactive learning modules for:

- **Docker**: Containerization, orchestration, best practices
- **Ansible**: Configuration management, playbooks, roles
- **Terraform**: Infrastructure as Code, state management
- **Jenkins**: CI/CD pipelines, automation
- **Monitoring**: Prometheus, Grafana, logging

## Development Workflow

### Git Branching Strategy

- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: Feature development branches
- `release/*`: Release preparation branches
- `hotfix/*`: Critical fixes for production

### Environment Promotion

1. **Development**: Local development and testing
2. **Staging**: Pre-production testing with production-like setup
3. **Production**: Live environment with full monitoring and security

## Monitoring and Observability

- **Metrics**: Prometheus collects metrics from all services
- **Visualization**: Grafana dashboards for system and application monitoring
- **Logging**: ELK stack for centralized log management
- **Alerting**: Configured alerts for critical system events

## Security Considerations

- All passwords should be changed from defaults
- SSL/TLS encryption for external communications
- Network segmentation between service tiers
- Regular security updates and patches

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports are available before starting services
2. **Memory issues**: Adjust resource limits in docker-compose files
3. **Network connectivity**: Check Docker network configuration
4. **Permission issues**: Ensure proper file permissions for volumes

### Health Checks

```bash
# Check service health
docker-compose ps

# View service logs
docker-compose logs [service-name]

# Run Ansible health checks
ansible-playbook -i inventories/dev/hosts.yml playbooks/maintenance.yml
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.