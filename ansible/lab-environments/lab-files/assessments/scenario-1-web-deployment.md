# Ansible Assessment Scenario 1: Web Application Deployment

## Scenario Description
You are a DevOps engineer tasked with automating the deployment of a web application across multiple environments. The application consists of a frontend web server (nginx) and a backend API service.

## Requirements

### Infrastructure
- 2 web servers (web-server-1, web-server-2)
- 1 database server (db-server-1)
- Load balancing between web servers

### Tasks to Complete

#### 1. Inventory Management (20 points)
Create an inventory file that:
- Groups web servers under `[webservers]`
- Groups database server under `[databases]`
- Creates a `[production:children]` group containing both groups
- Includes host variables for each server (ansible_host, custom variables)

#### 2. Web Server Configuration (30 points)
Create a playbook that:
- Installs nginx on web servers
- Configures nginx with custom settings
- Deploys a custom index.html page showing server information
- Ensures nginx is started and enabled
- Uses variables for configuration flexibility

#### 3. Database Server Setup (25 points)
Create tasks that:
- Install MySQL server on database server
- Configure MySQL with secure settings
- Create application database and user
- Ensure MySQL service is running

#### 4. Advanced Features (25 points)
Implement:
- Handlers for service restarts
- Conditionals for different OS distributions
- Loops for installing multiple packages
- Templates for configuration files
- Error handling and validation

## Evaluation Criteria

### Functionality (40%)
- All services install and start correctly
- Configuration files are properly deployed
- Services are accessible and functional

### Code Quality (30%)
- Playbooks are well-structured and readable
- Proper use of variables and templates
- Appropriate task naming and documentation

### Best Practices (20%)
- Idempotent operations
- Proper use of handlers
- Security considerations
- Error handling

### Advanced Features (10%)
- Use of conditionals and loops
- Custom facts or variables
- Role organization (bonus)

## Deliverables
1. `inventory.ini` - Inventory file with all hosts and groups
2. `site.yml` - Main playbook orchestrating the deployment
3. `webserver.yml` - Web server configuration playbook
4. `database.yml` - Database server configuration playbook
5. `templates/` - Directory with configuration templates
6. `README.md` - Documentation explaining your solution

## Time Limit
90 minutes

## Validation Commands
```bash
# Syntax check
ansible-playbook --syntax-check site.yml

# Dry run
ansible-playbook -i inventory.ini site.yml --check

# Execute deployment
ansible-playbook -i inventory.ini site.yml

# Verify services
ansible webservers -i inventory.ini -m service -a "name=nginx state=started"
ansible databases -i inventory.ini -m service -a "name=mysql state=started"

# Test web servers
curl http://web-server-1
curl http://web-server-2
```

## Bonus Challenges (Extra Credit)
1. Create reusable roles instead of playbooks
2. Implement SSL/TLS configuration
3. Add monitoring and logging configuration
4. Create a rollback playbook
5. Implement blue-green deployment strategy