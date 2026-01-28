# 🚀 DevOps Practice Environment

A comprehensive DevOps learning platform with hands-on labs, real-world scenarios, and advanced simulators for CKA, Jenkins, Docker, Ansible, and Terraform.

## 🌐 **Quick Access - Service Dashboard**

### **📚 Learning Platform**
| Service | URL | Description | Status |
|---------|-----|-------------|--------|
| **Main Dashboard** | [http://localhost:3000](http://localhost:3000) | Learning platform homepage | ✅ |
| **CKA Simulator** | [http://localhost:3000/cka-simulator-enhanced.html](http://localhost:3000/cka-simulator-enhanced.html) | Advanced Kubernetes exam simulator | ✅ |
| **Docker Learning** | [http://localhost:3000/learning-docker.html](http://localhost:3000/learning-docker.html) | Interactive Docker tutorials | ✅ |
| **Ansible Learning** | [http://localhost:3000/learning-ansible.html](http://localhost:3000/learning-ansible.html) | Ansible automation labs | ✅ |
| **Jenkins Learning** | [http://localhost:3000/learning-jenkins.html](http://localhost:3000/learning-jenkins.html) | CI/CD pipeline tutorials | ✅ |
| **Terraform Learning** | [http://localhost:3000/learning-terraform.html](http://localhost:3000/learning-terraform.html) | Infrastructure as Code labs | ✅ |

### **🔧 DevOps Tools**
| Service | URL | Username | Password | Description |
|---------|-----|----------|----------|-------------|
| **Jenkins** | [http://localhost:8080](http://localhost:8080) | `admin` | `admin123` | CI/CD Pipeline Management |
| **Grafana** | [http://localhost:3001](http://localhost:3001) | `admin` | `admin123` | Monitoring & Dashboards |
| **Kibana** | [http://localhost:5601](http://localhost:5601) | - | - | Log Analysis & Visualization |
| **Prometheus** | [http://localhost:9090](http://localhost:9090) | - | - | Metrics Collection |
| **cAdvisor** | [http://localhost:8083](http://localhost:8083) | - | - | Container Metrics & Monitoring |

### **🛠️ Backend Services**
| Service | URL | Health Check | Description |
|---------|-----|--------------|-------------|
| **API Gateway** | [http://localhost:4000](http://localhost:4000) | [Health](http://localhost:4000/health) | Main API Gateway |
| **Learning Service** | [http://localhost:4001](http://localhost:4001) | [Health](http://localhost:4001/health) | Learning Content API |
| **User Service** | [http://localhost:4002](http://localhost:4002) | [Health](http://localhost:4002/health) | User Management API |
| **Assessment Service** | [http://localhost:4004](http://localhost:4004) | [Health](http://localhost:4004/health) | Quiz & Assessment API |

## 🚀 **Quick Start Guide**

### **1. Start All Services**
```bash
# Clone the repository
git clone <your-repo-url>
cd devops-practice-environment

# Start core services
docker compose up -d postgres redis

# Start application services
docker compose up -d learning-service user-service assessment-service api-gateway

# Start monitoring stack
docker compose up -d grafana prometheus kibana jenkins

# Start web server for static files
cd public && python3 -m http.server 3000
```

### **2. Access the Platform**
1. **Main Learning Platform**: [http://localhost:3000](http://localhost:3000)
2. **Choose your learning path** (Docker, Kubernetes, Ansible, etc.)
3. **Practice with real tools** using the integrated labs

### **3. Advanced CKA Practice**
1. Go to [CKA Simulator](http://localhost:3000/cka-simulator-enhanced.html)
2. Select a practice scenario
3. Practice in a real Ubuntu environment with kubeadm
4. Get instant feedback and scoring

## 📊 **Monitoring & Analytics**

### **Grafana Dashboards**
- **Learning Analytics**: [http://localhost:3001/d/learning](http://localhost:3001/d/learning)
- **System Overview**: [http://localhost:3001/d/system](http://localhost:3001/d/system)
- **User Progress**: [http://localhost:3001/d/users](http://localhost:3001/d/users)

### **Prometheus Metrics**
- **Service Health**: [http://localhost:9090/targets](http://localhost:9090/targets)
- **Custom Metrics**: [http://localhost:9090/graph](http://localhost:9090/graph)

### **Log Analysis**
- **Application Logs**: [http://localhost:5601](http://localhost:5601)
- **System Logs**: Available in Kibana dashboards

## 🎯 **Learning Modules**

### **🐳 Docker Mastery**
- **Basics**: Containers, Images, Volumes
- **Advanced**: Multi-stage builds, Security scanning
- **Orchestration**: Docker Swarm, Compose
- **Hands-on Labs**: Build and deploy real applications

### **☸️ Kubernetes (CKA Prep)**
- **Cluster Management**: kubeadm, kubectl, etcd
- **Workloads**: Pods, Deployments, Services
- **Storage**: PV, PVC, StorageClasses
- **Networking**: CNI, Ingress, NetworkPolicies
- **Real Exam Simulator**: Ubuntu VMs with kubeadm

### **🔧 Ansible Automation**
- **Playbooks**: YAML syntax, Tasks, Handlers
- **Inventory**: Static and dynamic inventories
- **Roles**: Reusable automation components
- **Vault**: Secrets management
- **Real Infrastructure**: Provision and configure servers

### **🏗️ Terraform IaC**
- **Providers**: AWS, Azure, GCP simulation
- **Resources**: Infrastructure components
- **State Management**: Remote state, locking
- **Modules**: Reusable infrastructure code

### **🔄 Jenkins CI/CD**
- **Pipeline as Code**: Jenkinsfile, Groovy
- **Multi-branch**: GitFlow integration
- **Deployment**: Blue-green, Rolling updates
- **Integration**: Docker, Kubernetes, Cloud

## 🛠️ **Development & Customization**

### **Architecture Overview**
```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React/HTML)                    │
├─────────────────────────────────────────────────────────────┤
│                    API Gateway (Node.js)                    │
├─────────────────────────────────────────────────────────────┤
│  Learning Service │ User Service │ Assessment │ Lab Service │
│     (Node.js)     │   (Python)   │  (Python)  │   (Java)    │
├─────────────────────────────────────────────────────────────┤
│              PostgreSQL Database + Redis Cache              │
├─────────────────────────────────────────────────────────────┤
│         Monitoring: Grafana + Prometheus + ELK Stack        │
└─────────────────────────────────────────────────────────────┘
```

### **Adding New Learning Content**
1. **Create content files** in `database/learning-content/`
2. **Add interactive labs** in `public/learning-[topic].html`
3. **Update navigation** in `public/js/navigation-system.js`
4. **Test with real scenarios**

### **Custom Lab Environments**
1. **Docker-based labs**: Add to `services/lab-service/`
2. **VM-based environments**: Use the CKA simulator pattern
3. **Cloud simulations**: Mock AWS/Azure/GCP resources

## 🔒 **Security & Best Practices**

### **Default Credentials**
| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| Jenkins | `admin` | `admin123` | Change in production |
| Grafana | `admin` | `admin123` | Change in production |
| Database | `devops_user` | `dev_password_2024` | Environment variable |

### **Production Deployment**
```bash
# Use production configuration
cp .env.prod .env

# Update passwords
vim .env

# Deploy with production settings
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 📈 **Performance & Scaling**

### **Resource Requirements**
- **Minimum**: 8GB RAM, 4 CPU cores, 50GB storage
- **Recommended**: 16GB RAM, 8 CPU cores, 100GB SSD
- **CKA Simulator**: Additional 4GB RAM per concurrent session

### **Scaling Options**
- **Horizontal**: Multiple API Gateway instances
- **Database**: PostgreSQL clustering
- **Caching**: Redis Cluster
- **Load Balancing**: Nginx upstream configuration

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Services Not Starting**
```bash
# Check service status
docker compose ps

# View logs
docker compose logs [service-name]

# Restart specific service
docker compose restart [service-name]
```

#### **Port Conflicts**
```bash
# Check port usage
lsof -i :8080

# Stop conflicting services
docker stop [container-name]
```

#### **Database Connection Issues**
```bash
# Test database connection
docker exec dev-postgres pg_isready -U devops_user -d devops_practice

# Reset database
docker compose down postgres
docker volume rm dev-postgres-data
docker compose up -d postgres
```

#### **CKA Simulator Issues**
```bash
# Build Ubuntu image
cd services/cka-simulator
./build-ubuntu-image.sh

# Check container resources
docker stats

# Clean up old sessions
docker container prune
```

### **Health Checks**
- **All Services**: [http://localhost:4000/health](http://localhost:4000/health)
- **Database**: `docker exec dev-postgres pg_isready`
- **Redis**: `docker exec dev-redis redis-cli ping`

## 🤝 **Contributing**

### **Development Workflow**
```bash
# Create feature branch
git checkout -b feature/new-learning-module

# Make changes and test
docker compose up -d
# Test your changes

# Commit and push
git add .
git commit -m "Add new learning module"
git push origin feature/new-learning-module
```

### **Adding New Features**
1. **Learning Modules**: Add to `public/learning-[topic].html`
2. **Backend APIs**: Extend existing services or create new ones
3. **Monitoring**: Add Grafana dashboards in `monitoring/grafana/dashboards/`
4. **Tests**: Add integration tests in `tests/`

## 📞 **Support & Documentation**

### **Getting Help**
- **Documentation**: Check the `docs/` directory
- **Issues**: Create GitHub issues for bugs
- **Discussions**: Use GitHub Discussions for questions

### **Useful Commands**
```bash
# Full system restart
docker compose down && docker compose up -d

# View all logs
docker compose logs -f

# Clean up everything
docker compose down -v
docker system prune -a

# Backup data
./scripts/backup.sh

# Run tests
./tests/integration/run-all-tests.sh
```

---

## 🎉 **Ready to Start Learning?**

1. **🌐 Visit the main platform**: [http://localhost:3000](http://localhost:3000)
2. **🎯 Try the CKA simulator**: [http://localhost:3000/cka-simulator-enhanced.html](http://localhost:3000/cka-simulator-enhanced.html)
3. **📊 Monitor your progress**: [http://localhost:3001](http://localhost:3001)
4. **🔧 Build CI/CD pipelines**: [http://localhost:8080](http://localhost:8080)

**Happy Learning! 🚀**