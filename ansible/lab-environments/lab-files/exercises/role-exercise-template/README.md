# Ansible Role Exercise

## Objective
Create a reusable Ansible role for MySQL database server configuration.

## Requirements
Your role should accomplish the following:

1. **Install MySQL Server**
   - Install mysql-server package
   - Install python3-pymysql for Ansible MySQL modules

2. **Configure MySQL**
   - Set root password
   - Create application database
   - Create application user with appropriate privileges
   - Configure MySQL to listen on all interfaces

3. **Security Configuration**
   - Remove anonymous users
   - Remove test database
   - Disable remote root login

4. **Service Management**
   - Start and enable MySQL service
   - Create handler to restart MySQL when configuration changes

## Role Structure
Create the role with the following structure:

```
roles/mysql/
├── tasks/main.yml          # Main tasks
├── handlers/main.yml       # Service handlers
├── templates/
│   └── my.cnf.j2          # MySQL configuration template
├── vars/main.yml          # Role variables
├── defaults/main.yml      # Default variables
└── meta/main.yml          # Role metadata
```

## Variables to Define
- `mysql_root_password`: Root password for MySQL
- `mysql_database`: Application database name
- `mysql_user`: Application database user
- `mysql_password`: Application user password
- `mysql_bind_address`: IP address to bind MySQL service

## Testing
Create a playbook that:
1. Applies the role to database servers
2. Verifies MySQL is running
3. Tests database connectivity

## Validation Commands
```bash
# Test role syntax
ansible-playbook --syntax-check site.yml

# Run in check mode
ansible-playbook -i inventory site.yml --check

# Execute the playbook
ansible-playbook -i inventory site.yml

# Verify MySQL is running
ansible databases -i inventory -m service -a "name=mysql state=started"
```