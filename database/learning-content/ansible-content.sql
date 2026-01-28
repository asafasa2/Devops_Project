-- Comprehensive Ansible Learning Content
-- This file contains detailed learning modules, quizzes, and lab exercises for Ansible automation

\c devops_practice;

-- Delete existing basic Ansible content to replace with comprehensive content
DELETE FROM learning.learning_content WHERE tool_category = 'ansible';

-- Module 1: Ansible Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Fundamentals: Introduction to Configuration Management', 'module', 'ansible', 'beginner', 
'{
  "sections": [
    {
      "title": "What is Configuration Management?",
      "content": "Configuration management is the practice of handling changes systematically so that a system maintains its integrity over time. It ensures that systems are configured correctly and consistently across environments.",
      "code_examples": [
        {
          "title": "Manual vs Automated Configuration",
          "description": "Compare manual server setup with automated configuration",
          "code": "# Manual approach (error-prone, time-consuming)\nssh server1\nsudo apt update\nsudo apt install nginx\nsudo systemctl enable nginx\n\n# Automated approach with Ansible\n- name: Install and start nginx\n  apt:\n    name: nginx\n    state: present\n  become: yes\n- name: Start nginx service\n  systemd:\n    name: nginx\n    state: started\n    enabled: yes\n  become: yes"
        }
      ]
    },
    {
      "title": "Introduction to Ansible",
      "content": "Ansible is an open-source automation tool that uses SSH to connect to servers and run commands. It uses a declarative language to describe system configuration and is agentless, meaning no software needs to be installed on managed nodes.",
      "key_concepts": [
        "Agentless architecture",
        "SSH-based communication", 
        "YAML-based playbooks",
        "Idempotent operations",
        "Push-based model"
      ]
    },
    {
      "title": "Ansible Architecture",
      "content": "Ansible consists of a control node (where Ansible is installed) and managed nodes (target servers). The control node connects to managed nodes via SSH and executes tasks defined in playbooks.",
      "diagram": "Control Node -> SSH -> Managed Nodes (Web Servers, Database Servers, Load Balancers)"
    },
    {
      "title": "Key Ansible Components",
      "content": "Understanding the core components of Ansible is essential for effective automation.",
      "components": [
        {
          "name": "Inventory",
          "description": "List of managed nodes (servers) that Ansible will configure"
        },
        {
          "name": "Playbooks", 
          "description": "YAML files containing automation instructions"
        },
        {
          "name": "Tasks",
          "description": "Individual units of work within playbooks"
        },
        {
          "name": "Modules",
          "description": "Reusable units of code that perform specific actions"
        },
        {
          "name": "Roles",
          "description": "Organized collections of tasks, variables, and files"
        }
      ]
    }
  ],
  "objectives": [
    "Understand configuration management principles",
    "Learn Ansible architecture and components", 
    "Recognize benefits of automation",
    "Identify use cases for Ansible"
  ],
  "interactive_elements": [
    {
      "type": "knowledge_check",
      "question": "What makes Ansible agentless?",
      "options": ["Uses SSH", "No software on managed nodes", "Both A and B", "Uses HTTP"],
      "correct": 2,
      "explanation": "Ansible is agentless because it uses SSH to connect to managed nodes without requiring any agent software to be installed on them."
    }
  ]
}', 
'{}', 45);

-- Module 2: Ansible Installation and Setup
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Installation and Environment Setup', 'module', 'ansible', 'beginner',
'{
  "sections": [
    {
      "title": "Installing Ansible",
      "content": "Ansible can be installed on most Unix-like systems. The control node requires Python and can be installed via package managers or pip.",
      "installation_methods": [
        {
          "method": "Ubuntu/Debian",
          "commands": [
            "sudo apt update",
            "sudo apt install ansible"
          ]
        },
        {
          "method": "CentOS/RHEL",
          "commands": [
            "sudo yum install epel-release",
            "sudo yum install ansible"
          ]
        },
        {
          "method": "pip",
          "commands": [
            "pip install ansible"
          ]
        }
      ]
    },
    {
      "title": "Configuring SSH Access",
      "content": "Ansible uses SSH for communication. Setting up passwordless SSH access improves security and automation.",
      "code_examples": [
        {
          "title": "Generate SSH Key Pair",
          "code": "# Generate SSH key pair\nssh-keygen -t rsa -b 4096 -C \"ansible@control-node\"\n\n# Copy public key to managed nodes\nssh-copy-id user@managed-node-ip"
        },
        {
          "title": "Test SSH Connection",
          "code": "# Test passwordless SSH\nssh user@managed-node-ip\n\n# Should connect without password prompt"
        }
      ]
    },
    {
      "title": "Ansible Configuration File",
      "content": "The ansible.cfg file controls Ansible behavior. It can be placed in multiple locations with different precedence levels.",
      "code_examples": [
        {
          "title": "Basic ansible.cfg",
          "code": "[defaults]\ninventory = ./inventory\nremote_user = ansible\nhost_key_checking = False\nretry_files_enabled = False\n\n[ssh_connection]\nssh_args = -o ControlMaster=auto -o ControlPersist=60s"
        }
      ]
    }
  ],
  "objectives": [
    "Install Ansible on control node",
    "Configure SSH access to managed nodes",
    "Create and configure ansible.cfg",
    "Verify Ansible installation"
  ],
  "hands_on_exercises": [
    {
      "title": "Installation Verification",
      "description": "Verify Ansible installation and check version",
      "commands": [
        "ansible --version",
        "ansible-playbook --version"
      ]
    }
  ]
}',
'{"Ansible Fundamentals: Introduction to Configuration Management"}', 30);

-- Module 3: Ansible Inventory Management
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Inventory Management', 'module', 'ansible', 'beginner',
'{
  "sections": [
    {
      "title": "Understanding Inventory",
      "content": "Inventory defines the hosts and groups of hosts upon which commands, modules, and tasks in a playbook operate. It can be static (INI or YAML files) or dynamic (scripts or plugins).",
      "inventory_formats": [
        "INI format",
        "YAML format", 
        "Dynamic inventory scripts",
        "Inventory plugins"
      ]
    },
    {
      "title": "Static Inventory - INI Format",
      "content": "The INI format is simple and widely used for static inventories.",
      "code_examples": [
        {
          "title": "Basic INI Inventory",
          "code": "[webservers]\nweb1.example.com\nweb2.example.com\n\n[databases]\ndb1.example.com\ndb2.example.com\n\n[production:children]\nwebservers\ndatabases"
        },
        {
          "title": "Inventory with Variables",
          "code": "[webservers]\nweb1.example.com ansible_host=192.168.1.10 ansible_user=ubuntu\nweb2.example.com ansible_host=192.168.1.11 ansible_user=ubuntu\n\n[webservers:vars]\nhttp_port=80\nmax_clients=200"
        }
      ]
    },
    {
      "title": "Static Inventory - YAML Format", 
      "content": "YAML format provides more structure and readability for complex inventories.",
      "code_examples": [
        {
          "title": "YAML Inventory Structure",
          "code": "all:\n  children:\n    webservers:\n      hosts:\n        web1.example.com:\n          ansible_host: 192.168.1.10\n        web2.example.com:\n          ansible_host: 192.168.1.11\n      vars:\n        http_port: 80\n    databases:\n      hosts:\n        db1.example.com:\n          ansible_host: 192.168.1.20"
        }
      ]
    },
    {
      "title": "Inventory Variables and Groups",
      "content": "Variables can be assigned to individual hosts or groups, providing flexibility in configuration management.",
      "variable_types": [
        "Host variables",
        "Group variables", 
        "Group of groups variables",
        "Built-in variables"
      ]
    },
    {
      "title": "Testing Inventory",
      "content": "Ansible provides commands to test and validate inventory configuration.",
      "code_examples": [
        {
          "title": "Inventory Testing Commands",
          "code": "# List all hosts\nansible all --list-hosts\n\n# List hosts in specific group\nansible webservers --list-hosts\n\n# Show inventory graph\nansible-inventory --graph\n\n# Test connectivity\nansible all -m ping"
        }
      ]
    }
  ],
  "objectives": [
    "Create static inventory files in INI and YAML formats",
    "Organize hosts into logical groups",
    "Use inventory variables effectively",
    "Test and validate inventory configuration"
  ],
  "interactive_elements": [
    {
      "type": "code_exercise",
      "title": "Create Web Server Inventory",
      "description": "Create an inventory file for 3 web servers and 2 database servers",
      "template": "[webservers]\n# Add your web servers here\n\n[databases]\n# Add your database servers here",
      "solution": "[webservers]\nweb1.example.com\nweb2.example.com\nweb3.example.com\n\n[databases]\ndb1.example.com\ndb2.example.com"
    }
  ]
}',
'{"Ansible Installation and Environment Setup"}', 40);

-- Module 4: Ansible Playbooks and Tasks
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Playbooks and Tasks', 'module', 'ansible', 'intermediate',
'{
  "sections": [
    {
      "title": "Introduction to Playbooks",
      "content": "Playbooks are YAML files that define a series of tasks to be executed on managed nodes. They are the heart of Ansible automation and describe the desired state of systems.",
      "playbook_structure": [
        "Play definition",
        "Host targeting",
        "Task lists",
        "Variables and facts",
        "Handlers and notifications"
      ]
    },
    {
      "title": "Basic Playbook Structure",
      "content": "A playbook consists of one or more plays, each targeting specific hosts and containing tasks to execute.",
      "code_examples": [
        {
          "title": "Simple Playbook Example",
          "code": "---\n- name: Configure web servers\n  hosts: webservers\n  become: yes\n  \n  tasks:\n    - name: Install nginx\n      apt:\n        name: nginx\n        state: present\n        \n    - name: Start nginx service\n      systemd:\n        name: nginx\n        state: started\n        enabled: yes"
        }
      ]
    },
    {
      "title": "Tasks and Modules",
      "content": "Tasks are the individual units of work in playbooks. Each task uses a module to perform specific actions on managed nodes.",
      "common_modules": [
        {
          "name": "apt/yum",
          "description": "Package management"
        },
        {
          "name": "systemd/service",
          "description": "Service management"
        },
        {
          "name": "copy/template",
          "description": "File operations"
        },
        {
          "name": "user/group",
          "description": "User management"
        },
        {
          "name": "command/shell",
          "description": "Command execution"
        }
      ]
    },
    {
      "title": "Variables in Playbooks",
      "content": "Variables make playbooks flexible and reusable. They can be defined in multiple places with different precedence levels.",
      "code_examples": [
        {
          "title": "Using Variables",
          "code": "---\n- name: Deploy application\n  hosts: webservers\n  vars:\n    app_name: myapp\n    app_version: 1.2.3\n    \n  tasks:\n    - name: Create app directory\n      file:\n        path: /opt/{{ app_name }}\n        state: directory\n        \n    - name: Download application\n      get_url:\n        url: https://releases.example.com/{{ app_name }}-{{ app_version }}.tar.gz\n        dest: /tmp/{{ app_name }}.tar.gz"
        }
      ]
    },
    {
      "title": "Conditionals and Loops",
      "content": "Ansible supports conditionals and loops to make playbooks more dynamic and handle different scenarios.",
      "code_examples": [
        {
          "title": "Conditionals Example",
          "code": "- name: Install package on Ubuntu\n  apt:\n    name: nginx\n    state: present\n  when: ansible_distribution == \"Ubuntu\"\n\n- name: Install package on CentOS\n  yum:\n    name: nginx\n    state: present\n  when: ansible_distribution == \"CentOS\""
        },
        {
          "title": "Loops Example", 
          "code": "- name: Install multiple packages\n  apt:\n    name: \"{{ item }}\"\n    state: present\n  loop:\n    - nginx\n    - mysql-server\n    - php-fpm"
        }
      ]
    },
    {
      "title": "Handlers and Notifications",
      "content": "Handlers are special tasks that run only when notified by other tasks. They are typically used for service restarts or configuration reloads.",
      "code_examples": [
        {
          "title": "Handlers Example",
          "code": "tasks:\n  - name: Update nginx config\n    template:\n      src: nginx.conf.j2\n      dest: /etc/nginx/nginx.conf\n    notify: restart nginx\n    \nhandlers:\n  - name: restart nginx\n    systemd:\n      name: nginx\n      state: restarted"
        }
      ]
    }
  ],
  "objectives": [
    "Write basic Ansible playbooks",
    "Use common Ansible modules effectively",
    "Implement variables, conditionals, and loops",
    "Create and use handlers for service management"
  ],
  "hands_on_exercises": [
    {
      "title": "Web Server Playbook",
      "description": "Create a playbook that installs and configures nginx on web servers",
      "requirements": [
        "Install nginx package",
        "Start and enable nginx service", 
        "Copy custom index.html",
        "Restart nginx if config changes"
      ]
    }
  ]
}',
'{"Ansible Inventory Management"}', 60);

-- Module 5: Ansible Roles
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Roles: Organizing and Reusing Code', 'module', 'ansible', 'intermediate',
'{
  "sections": [
    {
      "title": "Introduction to Roles",
      "content": "Roles are a way to organize playbooks and make them reusable. They provide a standardized directory structure for tasks, variables, files, templates, and handlers.",
      "benefits": [
        "Code reusability",
        "Better organization",
        "Easier maintenance",
        "Sharing with community",
        "Modular design"
      ]
    },
    {
      "title": "Role Directory Structure",
      "content": "Ansible roles follow a specific directory structure that organizes different components.",
      "directory_structure": {
        "tasks/": "Main list of tasks to be executed",
        "handlers/": "Handlers triggered by tasks",
        "templates/": "Jinja2 templates for configuration files",
        "files/": "Static files to be copied to managed nodes",
        "vars/": "Variables for the role",
        "defaults/": "Default variables with lowest precedence",
        "meta/": "Role metadata and dependencies"
      },
      "code_examples": [
        {
          "title": "Role Directory Structure",
          "code": "roles/\n└── webserver/\n    ├── tasks/\n    │   └── main.yml\n    ├── handlers/\n    │   └── main.yml\n    ├── templates/\n    │   └── nginx.conf.j2\n    ├── files/\n    │   └── index.html\n    ├── vars/\n    │   └── main.yml\n    ├── defaults/\n    │   └── main.yml\n    └── meta/\n        └── main.yml"
        }
      ]
    },
    {
      "title": "Creating a Role",
      "content": "Roles can be created manually or using ansible-galaxy command for scaffolding.",
      "code_examples": [
        {
          "title": "Create Role with ansible-galaxy",
          "code": "# Create role structure\nansible-galaxy init webserver\n\n# This creates the complete directory structure"
        },
        {
          "title": "Role tasks/main.yml",
          "code": "---\n# tasks file for webserver\n- name: Install nginx\n  apt:\n    name: nginx\n    state: present\n  become: yes\n\n- name: Copy nginx config\n  template:\n    src: nginx.conf.j2\n    dest: /etc/nginx/nginx.conf\n  become: yes\n  notify: restart nginx\n\n- name: Start nginx service\n  systemd:\n    name: nginx\n    state: started\n    enabled: yes\n  become: yes"
        },
        {
          "title": "Role handlers/main.yml",
          "code": "---\n# handlers file for webserver\n- name: restart nginx\n  systemd:\n    name: nginx\n    state: restarted\n  become: yes"
        }
      ]
    },
    {
      "title": "Using Roles in Playbooks",
      "content": "Roles can be applied to hosts using the roles keyword or tasks include_role module.",
      "code_examples": [
        {
          "title": "Using Roles",
          "code": "---\n- name: Configure web servers\n  hosts: webservers\n  roles:\n    - webserver\n    - monitoring\n    \n# Alternative syntax\n- name: Configure web servers\n  hosts: webservers\n  tasks:\n    - include_role:\n        name: webserver\n    - include_role:\n        name: monitoring"
        }
      ]
    },
    {
      "title": "Role Variables and Defaults",
      "content": "Roles can define variables with different precedence levels, making them flexible and customizable.",
      "code_examples": [
        {
          "title": "defaults/main.yml",
          "code": "---\n# Default variables (lowest precedence)\nnginx_port: 80\nnginx_user: www-data\nmax_clients: 100"
        },
        {
          "title": "vars/main.yml", 
          "code": "---\n# Role variables (higher precedence)\nnginx_config_path: /etc/nginx/nginx.conf\nnginx_log_path: /var/log/nginx"
        }
      ]
    },
    {
      "title": "Role Dependencies",
      "content": "Roles can depend on other roles, which are automatically executed before the dependent role.",
      "code_examples": [
        {
          "title": "meta/main.yml",
          "code": "---\ndependencies:\n  - role: common\n    vars:\n      some_parameter: 3\n  - role: firewall\n    firewall_rules:\n      - port: 80\n        protocol: tcp"
        }
      ]
    }
  ],
  "objectives": [
    "Understand role structure and organization",
    "Create reusable Ansible roles",
    "Use roles in playbooks effectively",
    "Manage role variables and dependencies"
  ],
  "hands_on_exercises": [
    {
      "title": "Database Role Creation",
      "description": "Create a role for MySQL database installation and configuration",
      "requirements": [
        "Install MySQL server",
        "Configure root password",
        "Create application database",
        "Set up backup script"
      ]
    }
  ]
}',
'{"Ansible Playbooks and Tasks"}', 50);

-- Quiz 1: Ansible Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Fundamentals Quiz', 'quiz', 'ansible', 'beginner',
'{
  "questions": [
    {
      "question": "What makes Ansible agentless?",
      "options": [
        "It uses HTTP for communication",
        "It uses SSH and requires no software on managed nodes", 
        "It only works with cloud providers",
        "It uses a web interface"
      ],
      "correct": 1,
      "explanation": "Ansible is agentless because it uses SSH to connect to managed nodes without requiring any agent software to be installed on them."
    },
    {
      "question": "What format are Ansible playbooks written in?",
      "options": ["JSON", "YAML", "XML", "Python"],
      "correct": 1,
      "explanation": "Ansible playbooks are written in YAML (Yet Another Markup Language), which is human-readable and easy to write."
    },
    {
      "question": "Which component defines the list of servers Ansible will manage?",
      "options": ["Playbook", "Inventory", "Module", "Role"],
      "correct": 1,
      "explanation": "The inventory defines the hosts and groups of hosts that Ansible will manage and configure."
    },
    {
      "question": "What is the primary benefit of idempotent operations in Ansible?",
      "options": [
        "Faster execution",
        "Better security",
        "Same result regardless of how many times run",
        "Smaller file sizes"
      ],
      "correct": 2,
      "explanation": "Idempotent operations ensure that running the same playbook multiple times produces the same result, making automation safe and predictable."
    },
    {
      "question": "Which file is used to configure Ansible behavior?",
      "options": ["config.yml", "ansible.cfg", "settings.ini", "ansible.conf"],
      "correct": 1,
      "explanation": "The ansible.cfg file is used to configure Ansible behavior, including inventory location, remote user, and SSH settings."
    }
  ],
  "passing_score": 80,
  "time_limit": 600
}',
'{"Ansible Fundamentals: Introduction to Configuration Management", "Ansible Installation and Environment Setup"}', 15);

-- Quiz 2: Inventory and Playbooks
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Inventory and Playbooks Quiz', 'quiz', 'ansible', 'intermediate',
'{
  "questions": [
    {
      "question": "In an INI inventory file, how do you create a group of groups?",
      "options": [
        "[group:children]",
        "[group:parent]", 
        "[group:subgroups]",
        "[group:nested]"
      ],
      "correct": 0,
      "explanation": "The :children suffix is used to create a group that contains other groups as members."
    },
    {
      "question": "What keyword is used to run tasks with elevated privileges?",
      "options": ["sudo", "become", "privilege", "root"],
      "correct": 1,
      "explanation": "The become keyword is used to run tasks with elevated privileges, replacing the older sudo keyword."
    },
    {
      "question": "Which section in a playbook contains tasks that run only when notified?",
      "options": ["tasks", "handlers", "notifications", "triggers"],
      "correct": 1,
      "explanation": "Handlers contain tasks that run only when notified by other tasks, typically used for service restarts."
    },
    {
      "question": "What is the correct way to loop over a list in Ansible?",
      "options": ["with_items", "loop", "iterate", "foreach"],
      "correct": 1,
      "explanation": "The loop keyword is the current standard way to iterate over lists in Ansible tasks."
    },
    {
      "question": "How do you test connectivity to all hosts in your inventory?",
      "options": [
        "ansible all -m test",
        "ansible all -m ping",
        "ansible all -m connect", 
        "ansible all -m check"
      ],
      "correct": 1,
      "explanation": "The ping module is used to test connectivity and basic functionality on managed nodes."
    },
    {
      "question": "What is the purpose of the when keyword in Ansible tasks?",
      "options": [
        "To schedule task execution",
        "To add conditional logic",
        "To set task timeout",
        "To define task dependencies"
      ],
      "correct": 1,
      "explanation": "The when keyword is used to add conditional logic to tasks, allowing them to run only when certain conditions are met."
    }
  ],
  "passing_score": 75,
  "time_limit": 900
}',
'{"Ansible Inventory Management", "Ansible Playbooks and Tasks"}', 20);

-- Quiz 3: Advanced Ansible Concepts
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Advanced Ansible Concepts Quiz', 'quiz', 'ansible', 'advanced',
'{
  "questions": [
    {
      "question": "Which directory in an Ansible role contains default variables with the lowest precedence?",
      "options": ["vars/", "defaults/", "variables/", "config/"],
      "correct": 1,
      "explanation": "The defaults/ directory contains default variables that have the lowest precedence in Ansible variable hierarchy."
    },
    {
      "question": "What command creates a new Ansible role structure?",
      "options": [
        "ansible-create role_name",
        "ansible-galaxy init role_name",
        "ansible-role create role_name",
        "ansible init role_name"
      ],
      "correct": 1,
      "explanation": "ansible-galaxy init creates a new role with the standard directory structure and template files."
    },
    {
      "question": "In which file would you define role dependencies?",
      "options": ["dependencies.yml", "meta/main.yml", "requirements.yml", "deps.yml"],
      "correct": 1,
      "explanation": "Role dependencies are defined in the meta/main.yml file within the role structure."
    },
    {
      "question": "What is the purpose of Ansible Vault?",
      "options": [
        "Store playbooks",
        "Encrypt sensitive data",
        "Manage inventory",
        "Create roles"
      ],
      "correct": 1,
      "explanation": "Ansible Vault is used to encrypt sensitive data like passwords, keys, and other secrets in playbooks."
    },
    {
      "question": "Which strategy allows Ansible to run tasks on all hosts simultaneously?",
      "options": ["linear", "free", "parallel", "async"],
      "correct": 1,
      "explanation": "The free strategy allows each host to run through tasks as fast as possible without waiting for other hosts."
    },
    {
      "question": "What is the difference between include and import in Ansible?",
      "options": [
        "No difference, they are synonyms",
        "include is dynamic, import is static",
        "include is for tasks, import is for variables",
        "include is deprecated, import is current"
      ],
      "correct": 1,
      "explanation": "include is processed at runtime (dynamic), while import is processed at parse time (static), affecting when variables and conditionals are evaluated."
    }
  ],
  "passing_score": 80,
  "time_limit": 1200
}',
'{"Ansible Roles: Organizing and Reusing Code"}', 25);

-- Lab 1: Basic Ansible Setup and Inventory
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Setup and Inventory Lab', 'lab', 'ansible', 'beginner',
'{
  "description": "Set up Ansible environment and create inventory files for managing multiple servers",
  "learning_objectives": [
    "Install and configure Ansible",
    "Create static inventory files",
    "Test connectivity to managed nodes",
    "Organize hosts into logical groups"
  ],
  "environment": {
    "type": "ansible",
    "containers": [
      {
        "name": "ansible-control",
        "image": "ansible-control:latest",
        "role": "control_node"
      },
      {
        "name": "web-server-1",
        "image": "ubuntu:20.04",
        "role": "managed_node"
      },
      {
        "name": "web-server-2", 
        "image": "ubuntu:20.04",
        "role": "managed_node"
      },
      {
        "name": "db-server-1",
        "image": "ubuntu:20.04",
        "role": "managed_node"
      }
    ]
  },
  "tasks": [
    {
      "title": "Verify Ansible Installation",
      "description": "Check that Ansible is properly installed on the control node",
      "instructions": [
        "Run ansible --version to check installation",
        "Verify Python version compatibility",
        "Check available modules with ansible-doc -l | head"
      ],
      "validation": {
        "command": "ansible --version",
        "expected_output": "ansible"
      }
    },
    {
      "title": "Create Basic Inventory File",
      "description": "Create an inventory file with web servers and database servers",
      "instructions": [
        "Create a file named inventory.ini",
        "Add web-server-1 and web-server-2 to [webservers] group",
        "Add db-server-1 to [databases] group",
        "Create [production:children] group containing both webservers and databases"
      ],
      "template": "[webservers]\n# Add web servers here\n\n[databases]\n# Add database servers here\n\n[production:children]\n# Add child groups here",
      "validation": {
        "command": "ansible-inventory -i inventory.ini --list",
        "expected_groups": ["webservers", "databases", "production"]
      }
    },
    {
      "title": "Test Connectivity",
      "description": "Test SSH connectivity to all managed nodes",
      "instructions": [
        "Use ansible ping module to test all hosts",
        "Test specific groups separately",
        "Troubleshoot any connection issues"
      ],
      "validation": {
        "command": "ansible all -i inventory.ini -m ping",
        "expected_output": "SUCCESS"
      }
    },
    {
      "title": "Add Host Variables",
      "description": "Add host-specific variables to the inventory",
      "instructions": [
        "Add ansible_host variables for IP addresses",
        "Add ansible_user variable for SSH user",
        "Add custom variables like server_role"
      ],
      "validation": {
        "command": "ansible-inventory -i inventory.ini --host web-server-1",
        "expected_keys": ["ansible_host", "ansible_user"]
      }
    }
  ],
  "completion_criteria": [
    "Ansible is properly installed and configured",
    "Inventory file contains all required hosts and groups",
    "All managed nodes respond to ping module",
    "Host variables are properly configured"
  ]
}',
'{"Ansible Installation and Environment Setup"}', 45);

-- Lab 2: Writing and Running Playbooks
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Playbook Development Lab', 'lab', 'ansible', 'intermediate',
'{
  "description": "Create and execute Ansible playbooks to configure web servers with nginx",
  "learning_objectives": [
    "Write structured Ansible playbooks",
    "Use common Ansible modules",
    "Implement variables and conditionals",
    "Create and use handlers"
  ],
  "environment": {
    "type": "ansible",
    "containers": [
      {
        "name": "ansible-control",
        "image": "ansible-control:latest", 
        "role": "control_node"
      },
      {
        "name": "web-server-1",
        "image": "ubuntu:20.04",
        "role": "managed_node"
      },
      {
        "name": "web-server-2",
        "image": "ubuntu:20.04", 
        "role": "managed_node"
      }
    ]
  },
  "tasks": [
    {
      "title": "Create Basic Web Server Playbook",
      "description": "Write a playbook to install and configure nginx on web servers",
      "instructions": [
        "Create webserver.yml playbook",
        "Target webservers group",
        "Add task to update package cache",
        "Add task to install nginx package",
        "Add task to start and enable nginx service"
      ],
      "template": "---\n- name: Configure web servers\n  hosts: webservers\n  become: yes\n  \n  tasks:\n    # Add your tasks here",
      "validation": {
        "command": "ansible-playbook -i inventory.ini webserver.yml --check",
        "expected_output": "PLAY RECAP"
      }
    },
    {
      "title": "Add Variables and Templates",
      "description": "Enhance the playbook with variables and configuration templates",
      "instructions": [
        "Add vars section with nginx_port and server_name",
        "Create nginx.conf.j2 template file",
        "Add task to deploy template to /etc/nginx/sites-available/",
        "Add task to create symbolic link to sites-enabled"
      ],
      "validation": {
        "command": "ansible-playbook -i inventory.ini webserver.yml --check",
        "expected_tasks": ["template", "file"]
      }
    },
    {
      "title": "Implement Handlers",
      "description": "Add handlers to restart nginx when configuration changes",
      "instructions": [
        "Create handlers section",
        "Add restart nginx handler",
        "Add notify directive to template task",
        "Test handler execution"
      ],
      "validation": {
        "command": "grep -A 5 handlers webserver.yml",
        "expected_output": "restart nginx"
      }
    },
    {
      "title": "Add Conditionals and Loops",
      "description": "Use conditionals for OS-specific tasks and loops for multiple packages",
      "instructions": [
        "Add conditional task for Ubuntu vs CentOS",
        "Use loop to install multiple packages",
        "Add when condition based on ansible_distribution"
      ],
      "validation": {
        "command": "grep -E \"when:|loop:\" webserver.yml",
        "expected_output": "when:"
      }
    },
    {
      "title": "Execute and Verify Playbook",
      "description": "Run the complete playbook and verify web server configuration",
      "instructions": [
        "Run playbook with ansible-playbook command",
        "Verify nginx is running on managed nodes",
        "Test web server response with curl",
        "Run playbook again to test idempotency"
      ],
      "validation": {
        "command": "ansible webservers -i inventory.ini -m service -a \"name=nginx state=started\"",
        "expected_output": "SUCCESS"
      }
    }
  ],
  "completion_criteria": [
    "Playbook successfully installs and configures nginx",
    "Variables and templates are properly implemented",
    "Handlers restart services when needed",
    "Playbook runs idempotently without errors"
  ]
}',
'{"Ansible Playbooks and Tasks"}', 60);

-- Lab 3: Creating and Using Ansible Roles
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Roles Development Lab', 'lab', 'ansible', 'advanced',
'{
  "description": "Create reusable Ansible roles for web server and database configuration",
  "learning_objectives": [
    "Create structured Ansible roles",
    "Organize tasks, variables, and templates in roles",
    "Use roles in playbooks",
    "Implement role dependencies"
  ],
  "environment": {
    "type": "ansible",
    "containers": [
      {
        "name": "ansible-control",
        "image": "ansible-control:latest",
        "role": "control_node"
      },
      {
        "name": "web-server-1",
        "image": "ubuntu:20.04",
        "role": "managed_node"
      },
      {
        "name": "web-server-2",
        "image": "ubuntu:20.04",
        "role": "managed_node"
      },
      {
        "name": "db-server-1",
        "image": "ubuntu:20.04",
        "role": "managed_node"
      }
    ]
  },
  "tasks": [
    {
      "title": "Create Web Server Role Structure",
      "description": "Use ansible-galaxy to create a web server role",
      "instructions": [
        "Run ansible-galaxy init webserver to create role structure",
        "Examine the created directory structure",
        "Understand the purpose of each directory"
      ],
      "validation": {
        "command": "ls -la roles/webserver/",
        "expected_directories": ["tasks", "handlers", "templates", "vars", "defaults", "meta"]
      }
    },
    {
      "title": "Implement Web Server Role Tasks",
      "description": "Create tasks for nginx installation and configuration",
      "instructions": [
        "Edit roles/webserver/tasks/main.yml",
        "Add tasks for package installation",
        "Add tasks for service management",
        "Add tasks for configuration file deployment"
      ],
      "template": "---\n# tasks file for webserver\n- name: Install nginx\n  # Add your task here\n\n- name: Configure nginx\n  # Add your task here",
      "validation": {
        "command": "ansible-playbook --syntax-check site.yml",
        "expected_output": "playbook: site.yml"
      }
    },
    {
      "title": "Create Role Variables and Defaults",
      "description": "Define configurable variables for the web server role",
      "instructions": [
        "Edit roles/webserver/defaults/main.yml with default values",
        "Edit roles/webserver/vars/main.yml with role-specific variables",
        "Create template file for nginx configuration"
      ],
      "validation": {
        "command": "cat roles/webserver/defaults/main.yml",
        "expected_content": "nginx_port"
      }
    },
    {
      "title": "Create Database Role with Dependencies",
      "description": "Create a database role that depends on the common role",
      "instructions": [
        "Create database role with ansible-galaxy init database",
        "Define role dependency on common role in meta/main.yml",
        "Implement MySQL installation and configuration tasks"
      ],
      "validation": {
        "command": "cat roles/database/meta/main.yml",
        "expected_content": "dependencies"
      }
    },
    {
      "title": "Create Site Playbook Using Roles",
      "description": "Create a main playbook that uses the created roles",
      "instructions": [
        "Create site.yml playbook",
        "Apply webserver role to webservers group",
        "Apply database role to databases group",
        "Override role variables as needed"
      ],
      "template": "---\n- name: Configure web servers\n  hosts: webservers\n  roles:\n    # Add your roles here\n\n- name: Configure database servers\n  hosts: databases\n  roles:\n    # Add your roles here",
      "validation": {
        "command": "ansible-playbook -i inventory.ini site.yml --check",
        "expected_output": "PLAY RECAP"
      }
    },
    {
      "title": "Test Role Functionality",
      "description": "Execute the site playbook and verify role functionality",
      "instructions": [
        "Run the site playbook",
        "Verify services are running on target hosts",
        "Test role idempotency",
        "Validate configuration files are properly deployed"
      ],
      "validation": {
        "command": "ansible all -i inventory.ini -m setup -a \"filter=ansible_service_mgr\"",
        "expected_output": "SUCCESS"
      }
    }
  ],
  "completion_criteria": [
    "Web server and database roles are properly structured",
    "Roles contain appropriate tasks, variables, and templates",
    "Role dependencies are correctly configured",
    "Site playbook successfully applies roles to target hosts"
  ]
}',
'{"Ansible Roles: Organizing and Reusing Code"}', 75);

-- Assessment: Comprehensive Ansible Skills
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Comprehensive Ansible Assessment', 'quiz', 'ansible', 'advanced',
'{
  "description": "Comprehensive assessment covering all Ansible concepts from basics to advanced role development",
  "questions": [
    {
      "question": "You need to configure 50 web servers with the same nginx setup. What is the most efficient Ansible approach?",
      "options": [
        "Write 50 separate playbooks",
        "Create a role and apply it to all servers",
        "Use ad-hoc commands for each server",
        "Manually configure each server"
      ],
      "correct": 1,
      "explanation": "Creating a role provides reusability, maintainability, and consistency across all servers."
    },
    {
      "question": "In which scenario would you use the free strategy in Ansible?",
      "options": [
        "When you need tasks to run in specific order across all hosts",
        "When you want each host to run tasks as fast as possible",
        "When you need to debug playbook execution",
        "When you want to limit resource usage"
      ],
      "correct": 1,
      "explanation": "The free strategy allows each host to run through tasks independently without waiting for other hosts."
    },
    {
      "question": "What is the correct way to encrypt a variable file with Ansible Vault?",
      "options": [
        "ansible-vault encrypt vars.yml",
        "ansible-crypt encrypt vars.yml", 
        "ansible-secure vars.yml",
        "ansible encrypt vars.yml"
      ],
      "correct": 0,
      "explanation": "ansible-vault encrypt is the correct command to encrypt files containing sensitive data."
    },
    {
      "question": "How do you override a role default variable in a playbook?",
      "options": [
        "Edit the defaults/main.yml file",
        "Use vars section in the playbook",
        "Create a new role",
        "Use environment variables"
      ],
      "correct": 1,
      "explanation": "Variables defined in the vars section of a playbook have higher precedence than role defaults."
    },
    {
      "question": "What happens when a task fails in an Ansible playbook by default?",
      "options": [
        "Ansible continues with the next task",
        "Ansible stops execution for that host",
        "Ansible retries the task automatically",
        "Ansible skips to the next host"
      ],
      "correct": 1,
      "explanation": "By default, when a task fails, Ansible stops executing tasks for that host but continues with other hosts."
    },
    {
      "question": "Which module would you use to ensure a directory exists with specific permissions?",
      "options": ["copy", "template", "file", "directory"],
      "correct": 2,
      "explanation": "The file module is used to manage file and directory properties including existence, permissions, and ownership."
    },
    {
      "question": "How do you run only specific tags from a playbook?",
      "options": [
        "ansible-playbook playbook.yml --tags tag_name",
        "ansible-playbook playbook.yml --only tag_name",
        "ansible-playbook playbook.yml --select tag_name",
        "ansible-playbook playbook.yml --run tag_name"
      ],
      "correct": 0,
      "explanation": "The --tags option allows you to run only tasks with specific tags."
    },
    {
      "question": "What is the purpose of the gather_facts directive in a playbook?",
      "options": [
        "To collect system information from managed nodes",
        "To validate playbook syntax",
        "To check connectivity to hosts",
        "To display task output"
      ],
      "correct": 0,
      "explanation": "gather_facts collects system information (facts) from managed nodes that can be used in tasks and templates."
    },
    {
      "question": "In Jinja2 templates, how do you access a variable?",
      "options": [
        "$variable_name",
        "{{ variable_name }}",
        "%variable_name%",
        "@variable_name"
      ],
      "correct": 1,
      "explanation": "Jinja2 templates use double curly braces {{ }} to access variables."
    },
    {
      "question": "What is the difference between copy and template modules?",
      "options": [
        "copy is for text files, template is for binary files",
        "copy transfers files as-is, template processes Jinja2 variables",
        "copy is faster, template is more secure",
        "copy works locally, template works remotely"
      ],
      "correct": 1,
      "explanation": "The copy module transfers files without modification, while template processes Jinja2 variables and expressions."
    }
  ],
  "passing_score": 80,
  "time_limit": 1800,
  "certification": {
    "name": "Ansible Automation Specialist",
    "description": "Demonstrates comprehensive understanding of Ansible automation concepts and practical skills"
  }
}',
'{"Ansible Fundamentals Quiz", "Ansible Inventory and Playbooks Quiz", "Advanced Ansible Concepts Quiz", "Ansible Setup and Inventory Lab", "Ansible Playbook Development Lab", "Ansible Roles Development Lab"}', 30);