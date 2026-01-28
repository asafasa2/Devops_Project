# Ansible Assessment Scenario 2: Role Development and Reusability

## Scenario Description
Your organization needs standardized, reusable Ansible roles for common infrastructure components. You must create a comprehensive role ecosystem that can be used across different projects and environments.

## Requirements

### Role Development Tasks

#### 1. Common Role (25 points)
Create a `common` role that:
- Updates system packages
- Configures basic security settings (firewall, SSH)
- Sets up system users and groups
- Configures timezone and NTP
- Installs essential packages (vim, curl, wget, etc.)

#### 2. Web Server Role (30 points)
Create a `webserver` role that:
- Depends on the common role
- Installs and configures nginx
- Manages SSL certificates
- Configures virtual hosts
- Implements health checks
- Handles log rotation

#### 3. Database Role (25 points)
Create a `database` role that:
- Depends on the common role
- Installs MySQL/PostgreSQL
- Configures database security
- Creates databases and users
- Sets up backup procedures
- Manages database configuration

#### 4. Monitoring Role (20 points)
Create a `monitoring` role that:
- Installs monitoring agents
- Configures log forwarding
- Sets up health check endpoints
- Implements alerting rules

### Role Requirements

#### Structure and Organization
- Follow Ansible Galaxy role structure
- Include comprehensive README.md for each role
- Use proper variable naming conventions
- Implement role dependencies correctly

#### Variables and Defaults
- Define sensible defaults in `defaults/main.yml`
- Use role-specific variables in `vars/main.yml`
- Support environment-specific overrides
- Document all variables clearly

#### Templates and Files
- Create Jinja2 templates for configuration files
- Include static files where appropriate
- Use conditional logic in templates
- Implement proper file permissions

#### Handlers and Tasks
- Create idempotent tasks
- Implement proper error handling
- Use handlers for service management
- Include task tags for selective execution

## Evaluation Criteria

### Role Structure (25%)
- Proper directory organization
- Complete role metadata
- Clear documentation
- Dependency management

### Functionality (30%)
- Roles work independently and together
- All services configure correctly
- Proper service management
- Error handling and validation

### Reusability (25%)
- Configurable through variables
- Works across different environments
- Minimal hardcoded values
- Flexible and extensible

### Best Practices (20%)
- Idempotent operations
- Security considerations
- Performance optimization
- Code quality and readability

## Deliverables

### Role Structure
```
roles/
├── common/
│   ├── tasks/main.yml
│   ├── handlers/main.yml
│   ├── templates/
│   ├── files/
│   ├── vars/main.yml
│   ├── defaults/main.yml
│   ├── meta/main.yml
│   └── README.md
├── webserver/
│   └── [same structure]
├── database/
│   └── [same structure]
└── monitoring/
    └── [same structure]
```

### Playbooks
1. `site.yml` - Main orchestration playbook
2. `group_vars/` - Group-specific variables
3. `host_vars/` - Host-specific variables
4. `inventory/` - Environment inventories

### Documentation
1. `README.md` - Overall project documentation
2. Role-specific README files
3. Variable documentation
4. Usage examples

## Time Limit
120 minutes

## Testing Requirements

### Role Testing
```bash
# Test role syntax
ansible-playbook --syntax-check site.yml

# Test with different variable combinations
ansible-playbook -i inventory/dev site.yml --check
ansible-playbook -i inventory/prod site.yml --check

# Execute deployment
ansible-playbook -i inventory/dev site.yml

# Verify role functionality
ansible-playbook -i inventory/dev test-roles.yml
```

### Integration Testing
- All roles work together without conflicts
- Services start and function correctly
- Configuration files are properly generated
- Dependencies are resolved correctly

## Advanced Requirements (Bonus)

### Role Versioning
- Implement semantic versioning
- Create release tags
- Maintain changelog

### Testing Framework
- Use Molecule for role testing
- Implement CI/CD for roles
- Create test scenarios

### Galaxy Integration
- Prepare roles for Ansible Galaxy
- Include proper metadata
- Create installation instructions

## Validation Scenarios

### Scenario A: Development Environment
- Deploy all roles to development servers
- Verify basic functionality
- Test configuration changes

### Scenario B: Production Environment
- Deploy with production variables
- Verify security configurations
- Test high availability setup

### Scenario C: Mixed Environment
- Deploy different role combinations
- Test role dependencies
- Verify variable precedence