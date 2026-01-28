-- Comprehensive Terraform Learning Content
-- This file contains detailed learning modules, quizzes, and lab exercises for Terraform Infrastructure as Code

\c devops_practice;

-- Delete existing basic Terraform content to replace with comprehensive content
DELETE FROM learning.learning_content WHERE tool_category = 'terraform';

-- Module 1: Terraform Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Fundamentals: Introduction to Infrastructure as Code', 'module', 'terraform', 'beginner', 
'{
  "sections": [
    {
      "title": "What is Infrastructure as Code (IaC)?",
      "content": "Infrastructure as Code is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.",
      "benefits": [
        "Version control for infrastructure",
        "Reproducible environments",
        "Reduced human error",
        "Faster provisioning",
        "Cost optimization",
        "Documentation as code"
      ],
      "code_examples": [
        {
          "title": "Manual vs IaC Approach",
          "description": "Compare manual infrastructure setup with Terraform automation",
          "code": "# Manual approach (time-consuming, error-prone)\n# 1. Log into cloud console\n# 2. Click through UI to create resources\n# 3. Configure settings manually\n# 4. Repeat for each environment\n\n# Terraform approach (automated, consistent)\nresource \"aws_instance\" \"web_server\" {\n  ami           = \"ami-0c55b159cbfafe1d0\"\n  instance_type = \"t2.micro\"\n  \n  tags = {\n    Name        = \"WebServer\"\n    Environment = var.environment\n  }\n}"
        }
      ]
    },
    {
      "title": "Introduction to Terraform",
      "content": "Terraform is an open-source Infrastructure as Code tool created by HashiCorp. It allows you to define infrastructure using a declarative configuration language and manages the lifecycle of that infrastructure.",
      "key_concepts": [
        "Declarative configuration",
        "Provider-based architecture", 
        "State management",
        "Plan and apply workflow",
        "Resource dependencies"
      ]
    },
    {
      "title": "Terraform Architecture",
      "content": "Terraform uses a plugin-based architecture with providers that interact with APIs of various platforms and services.",
      "components": [
        {
          "name": "Terraform Core",
          "description": "The main Terraform binary that reads configuration and manages state"
        },
        {
          "name": "Providers",
          "description": "Plugins that interact with APIs of cloud platforms and services"
        },
        {
          "name": "Resources",
          "description": "Infrastructure objects managed by Terraform"
        },
        {
          "name": "State File",
          "description": "JSON file that maps configuration to real-world resources"
        }
      ]
    },
    {
      "title": "Terraform Workflow",
      "content": "Terraform follows a consistent workflow for managing infrastructure changes.",
      "workflow_steps": [
        {
          "step": "Write",
          "description": "Define infrastructure in configuration files"
        },
        {
          "step": "Plan", 
          "description": "Preview changes before applying them"
        },
        {
          "step": "Apply",
          "description": "Provision real infrastructure"
        },
        {
          "step": "Destroy",
          "description": "Clean up resources when no longer needed"
        }
      ]
    }
  ],
  "objectives": [
    "Understand Infrastructure as Code principles",
    "Learn Terraform architecture and components", 
    "Recognize benefits of declarative infrastructure",
    "Identify use cases for Terraform"
  ],
  "interactive_elements": [
    {
      "type": "knowledge_check",
      "question": "What is the main benefit of Infrastructure as Code?",
      "options": ["Faster servers", "Version control for infrastructure", "Cheaper costs", "Better security"],
      "correct": 1,
      "explanation": "IaC allows infrastructure to be version controlled, making it reproducible, auditable, and manageable like application code."
    }
  ]
}', 
'{}', 45);

-- Module 2: Terraform Installation and Configuration
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Installation and Configuration', 'module', 'terraform', 'beginner',
'{
  "sections": [
    {
      "title": "Installing Terraform",
      "content": "Terraform is distributed as a single binary that can be installed on various operating systems.",
      "installation_methods": [
        {
          "method": "Download Binary",
          "description": "Download from HashiCorp releases page",
          "commands": [
            "wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip",
            "unzip terraform_1.6.0_linux_amd64.zip",
            "sudo mv terraform /usr/local/bin/"
          ]
        },
        {
          "method": "Package Manager (Ubuntu)",
          "commands": [
            "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
            "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
            "sudo apt-get update && sudo apt-get install terraform"
          ]
        },
        {
          "method": "Homebrew (macOS)",
          "commands": [
            "brew tap hashicorp/tap",
            "brew install hashicorp/tap/terraform"
          ]
        }
      ]
    },
    {
      "title": "Terraform Configuration Language (HCL)",
      "content": "Terraform uses HashiCorp Configuration Language (HCL), which is designed to be human-readable and machine-friendly.",
      "syntax_basics": [
        "Blocks define configuration objects",
        "Arguments assign values to names",
        "Expressions represent values",
        "Comments use # or /* */"
      ],
      "code_examples": [
        {
          "title": "Basic HCL Syntax",
          "code": "# This is a comment\nresource \"aws_instance\" \"example\" {\n  ami           = \"ami-0c55b159cbfafe1d0\"\n  instance_type = \"t2.micro\"\n  \n  tags = {\n    Name = \"HelloWorld\"\n  }\n}"
        }
      ]
    },
    {
      "title": "Terraform Configuration Files",
      "content": "Terraform configuration is written in files with .tf extension. Multiple files in a directory are automatically loaded.",
      "file_types": [
        {
          "name": "main.tf",
          "description": "Primary configuration file"
        },
        {
          "name": "variables.tf",
          "description": "Variable definitions"
        },
        {
          "name": "outputs.tf",
          "description": "Output value definitions"
        },
        {
          "name": "terraform.tfvars",
          "description": "Variable value assignments"
        }
      ]
    },
    {
      "title": "Provider Configuration",
      "content": "Providers are plugins that Terraform uses to interact with cloud platforms, SaaS providers, and APIs.",
      "code_examples": [
        {
          "title": "Provider Configuration",
          "code": "terraform {\n  required_providers {\n    aws = {\n      source  = \"hashicorp/aws\"\n      version = \"~> 5.0\"\n    }\n    docker = {\n      source  = \"kreuzwerker/docker\"\n      version = \"~> 3.0\"\n    }\n  }\n}\n\nprovider \"aws\" {\n  region = \"us-west-2\"\n}\n\nprovider \"docker\" {\n  host = \"unix:///var/run/docker.sock\"\n}"
        }
      ]
    }
  ],
  "objectives": [
    "Install Terraform on local system",
    "Understand HCL syntax basics",
    "Configure Terraform providers",
    "Organize configuration files effectively"
  ],
  "hands_on_exercises": [
    {
      "title": "Installation Verification",
      "description": "Verify Terraform installation and check version",
      "commands": [
        "terraform version",
        "terraform -help"
      ]
    }
  ]
}',
'{"Terraform Fundamentals: Introduction to Infrastructure as Code"}', 35);

-- Module 3: Terraform Resources and Data Sources
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Resources and Data Sources', 'module', 'terraform', 'beginner',
'{
  "sections": [
    {
      "title": "Understanding Resources",
      "content": "Resources are the most important element in Terraform. They describe infrastructure objects like virtual machines, networks, or DNS records.",
      "resource_syntax": "resource \"<provider>_<type>\" \"<name>\" {\n  # Configuration arguments\n}",
      "code_examples": [
        {
          "title": "Docker Container Resource",
          "code": "resource \"docker_container\" \"nginx\" {\n  image = docker_image.nginx.image_id\n  name  = \"tutorial\"\n  \n  ports {\n    internal = 80\n    external = 8000\n  }\n}"
        },
        {
          "title": "Docker Image Resource",
          "code": "resource \"docker_image\" \"nginx\" {\n  name         = \"nginx:latest\"\n  keep_locally = false\n}"
        }
      ]
    },
    {
      "title": "Resource Arguments and Attributes",
      "content": "Resources have arguments (inputs) that you configure and attributes (outputs) that you can reference.",
      "argument_types": [
        "Required arguments - must be specified",
        "Optional arguments - have default values",
        "Computed attributes - set by the provider"
      ],
      "code_examples": [
        {
          "title": "Resource with Arguments and Attribute Reference",
          "code": "resource \"aws_instance\" \"web\" {\n  # Arguments (inputs)\n  ami           = \"ami-0c55b159cbfafe1d0\"\n  instance_type = \"t2.micro\"\n  \n  tags = {\n    Name = \"WebServer\"\n  }\n}\n\n# Reference computed attribute\noutput \"instance_ip\" {\n  value = aws_instance.web.public_ip\n}"
        }
      ]
    },
    {
      "title": "Data Sources",
      "content": "Data sources allow Terraform to fetch information from existing infrastructure or external systems.",
      "use_cases": [
        "Reference existing resources",
        "Fetch dynamic information",
        "Get provider-specific data",
        "Query external APIs"
      ],
      "code_examples": [
        {
          "title": "Data Source Example",
          "code": "# Fetch information about existing VPC\ndata \"aws_vpc\" \"default\" {\n  default = true\n}\n\n# Use data source in resource\nresource \"aws_subnet\" \"example\" {\n  vpc_id     = data.aws_vpc.default.id\n  cidr_block = \"10.0.1.0/24\"\n}"
        }
      ]
    },
    {
      "title": "Resource Dependencies",
      "content": "Terraform automatically determines resource dependencies based on references, but you can also specify explicit dependencies.",
      "dependency_types": [
        {
          "type": "Implicit Dependencies",
          "description": "Automatically determined from resource references"
        },
        {
          "type": "Explicit Dependencies", 
          "description": "Manually specified using depends_on argument"
        }
      ],
      "code_examples": [
        {
          "title": "Implicit Dependency",
          "code": "resource \"docker_image\" \"nginx\" {\n  name = \"nginx:latest\"\n}\n\nresource \"docker_container\" \"nginx\" {\n  # Implicit dependency on docker_image.nginx\n  image = docker_image.nginx.image_id\n  name  = \"tutorial\"\n}"
        },
        {
          "title": "Explicit Dependency",
          "code": "resource \"aws_instance\" \"web\" {\n  ami           = \"ami-0c55b159cbfafe1d0\"\n  instance_type = \"t2.micro\"\n  \n  # Explicit dependency\n  depends_on = [aws_security_group.web_sg]\n}"
        }
      ]
    }
  ],
  "objectives": [
    "Define and configure Terraform resources",
    "Use data sources to fetch existing information",
    "Understand resource dependencies",
    "Reference resource attributes in other resources"
  ],
  "interactive_elements": [
    {
      "type": "code_exercise",
      "title": "Create Docker Resources",
      "description": "Define a Docker image and container resource",
      "template": "resource \"docker_image\" \"nginx\" {\n  # Add configuration here\n}\n\nresource \"docker_container\" \"web\" {\n  # Add configuration here\n}",
      "solution": "resource \"docker_image\" \"nginx\" {\n  name = \"nginx:latest\"\n}\n\nresource \"docker_container\" \"web\" {\n  image = docker_image.nginx.image_id\n  name  = \"web-server\"\n  \n  ports {\n    internal = 80\n    external = 8080\n  }\n}"
    }
  ]
}',
'{"Terraform Installation and Configuration"}', 50);

-- Module 4: Terraform Variables and Outputs
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Variables and Outputs', 'module', 'terraform', 'intermediate',
'{
  "sections": [
    {
      "title": "Input Variables",
      "content": "Input variables make Terraform configurations flexible and reusable by allowing values to be customized without changing the source code.",
      "variable_syntax": "variable \"<name>\" {\n  description = \"Description of the variable\"\n  type        = <type>\n  default     = <default_value>\n  validation {\n    # Validation rules\n  }\n}",
      "code_examples": [
        {
          "title": "Variable Definition",
          "code": "variable \"instance_type\" {\n  description = \"EC2 instance type\"\n  type        = string\n  default     = \"t2.micro\"\n  \n  validation {\n    condition     = contains([\"t2.micro\", \"t2.small\", \"t2.medium\"], var.instance_type)\n    error_message = \"Instance type must be t2.micro, t2.small, or t2.medium.\"\n  }\n}"
        },
        {
          "title": "Using Variables",
          "code": "resource \"aws_instance\" \"web\" {\n  ami           = var.ami_id\n  instance_type = var.instance_type\n  \n  tags = {\n    Name = var.instance_name\n  }\n}"
        }
      ]
    },
    {
      "title": "Variable Types",
      "content": "Terraform supports various data types for variables to ensure type safety and validation.",
      "types": [
        {
          "type": "string",
          "description": "Sequence of Unicode characters",
          "example": "\"hello world\""
        },
        {
          "type": "number",
          "description": "Numeric value",
          "example": "42"
        },
        {
          "type": "bool",
          "description": "Boolean value",
          "example": "true"
        },
        {
          "type": "list(type)",
          "description": "Ordered sequence of values",
          "example": "[\"web\", \"app\", \"db\"]"
        },
        {
          "type": "map(type)",
          "description": "Collection of key-value pairs",
          "example": "{\"dev\" = \"t2.micro\", \"prod\" = \"t2.large\"}"
        },
        {
          "type": "object",
          "description": "Structural type with named attributes",
          "example": "{name = string, age = number}"
        }
      ],
      "code_examples": [
        {
          "title": "Complex Variable Types",
          "code": "variable \"server_config\" {\n  description = \"Server configuration\"\n  type = object({\n    name          = string\n    instance_type = string\n    disk_size     = number\n    tags          = map(string)\n  })\n  \n  default = {\n    name          = \"web-server\"\n    instance_type = \"t2.micro\"\n    disk_size     = 20\n    tags = {\n      Environment = \"dev\"\n      Team        = \"platform\"\n    }\n  }\n}"
        }
      ]
    },
    {
      "title": "Variable Assignment",
      "content": "Variables can be assigned values through multiple methods with different precedence levels.",
      "assignment_methods": [
        {
          "method": "Command line flags",
          "example": "terraform apply -var=\"instance_type=t2.small\"",
          "precedence": 1
        },
        {
          "method": "Variable files (.tfvars)",
          "example": "terraform apply -var-file=\"production.tfvars\"",
          "precedence": 2
        },
        {
          "method": "Environment variables",
          "example": "export TF_VAR_instance_type=t2.small",
          "precedence": 3
        },
        {
          "method": "Default values",
          "example": "default = \"t2.micro\"",
          "precedence": 4
        }
      ],
      "code_examples": [
        {
          "title": "terraform.tfvars File",
          "code": "# terraform.tfvars\ninstance_type = \"t2.small\"\ninstance_name = \"production-web\"\nami_id        = \"ami-0c55b159cbfafe1d0\"\n\nserver_tags = {\n  Environment = \"production\"\n  Team        = \"web\"\n  Project     = \"ecommerce\"\n}"
        }
      ]
    },
    {
      "title": "Output Values",
      "content": "Output values expose information about your infrastructure and can be used by other Terraform configurations or external systems.",
      "output_syntax": "output \"<name>\" {\n  description = \"Description of the output\"\n  value       = <expression>\n  sensitive   = <true|false>\n}",
      "code_examples": [
        {
          "title": "Output Examples",
          "code": "output \"instance_id\" {\n  description = \"ID of the EC2 instance\"\n  value       = aws_instance.web.id\n}\n\noutput \"instance_public_ip\" {\n  description = \"Public IP address of the instance\"\n  value       = aws_instance.web.public_ip\n}\n\noutput \"database_password\" {\n  description = \"Database password\"\n  value       = aws_db_instance.database.password\n  sensitive   = true\n}"
        }
      ]
    },
    {
      "title": "Local Values",
      "content": "Local values assign names to expressions to avoid repetition and improve readability.",
      "code_examples": [
        {
          "title": "Local Values Example",
          "code": "locals {\n  common_tags = {\n    Environment = var.environment\n    Project     = \"web-app\"\n    ManagedBy   = \"terraform\"\n  }\n  \n  instance_name = \"${var.environment}-web-server\"\n}\n\nresource \"aws_instance\" \"web\" {\n  ami           = var.ami_id\n  instance_type = var.instance_type\n  \n  tags = merge(local.common_tags, {\n    Name = local.instance_name\n  })\n}"
        }
      ]
    }
  ],
  "objectives": [
    "Define and use input variables effectively",
    "Understand variable types and validation",
    "Assign variable values using different methods",
    "Create meaningful output values",
    "Use local values to reduce repetition"
  ],
  "hands_on_exercises": [
    {
      "title": "Variable Configuration",
      "description": "Create a configuration with variables for different environments",
      "requirements": [
        "Define variables for instance type and environment",
        "Create a tfvars file for production values",
        "Use variables in resource configuration",
        "Output important resource attributes"
      ]
    }
  ]
}',
'{"Terraform Resources and Data Sources"}', 55);

-- Module 5: Terraform State Management
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform State Management', 'module', 'terraform', 'intermediate',
'{
  "sections": [
    {
      "title": "Understanding Terraform State",
      "content": "Terraform state is a JSON file that maps your configuration to real-world resources. It tracks metadata and improves performance for large infrastructures.",
      "state_purposes": [
        "Map configuration to real resources",
        "Track resource metadata",
        "Improve performance with caching",
        "Enable collaboration through locking",
        "Store sensitive values securely"
      ],
      "state_file_structure": {
        "version": "State file format version",
        "terraform_version": "Terraform version used",
        "serial": "Incremental counter for state changes",
        "resources": "List of managed resources with attributes"
      }
    },
    {
      "title": "Local vs Remote State",
      "content": "State can be stored locally or remotely. Remote state is recommended for team collaboration and production environments.",
      "local_state": {
        "pros": ["Simple setup", "No additional infrastructure", "Fast access"],
        "cons": ["No collaboration", "No locking", "Risk of loss", "Sensitive data exposure"]
      },
      "remote_state": {
        "pros": ["Team collaboration", "State locking", "Backup and versioning", "Secure storage"],
        "cons": ["Additional setup", "Network dependency", "Potential costs"]
      }
    },
    {
      "title": "Remote State Backends",
      "content": "Terraform supports various backends for storing state remotely with different features and capabilities.",
      "backends": [
        {
          "name": "S3",
          "description": "AWS S3 bucket with DynamoDB for locking",
          "features": ["Versioning", "Encryption", "Locking", "Cost-effective"]
        },
        {
          "name": "Azure Storage",
          "description": "Azure Storage Account with blob storage",
          "features": ["Versioning", "Encryption", "Access control"]
        },
        {
          "name": "Google Cloud Storage",
          "description": "GCS bucket for state storage",
          "features": ["Versioning", "Encryption", "IAM integration"]
        },
        {
          "name": "Terraform Cloud",
          "description": "HashiCorp managed service",
          "features": ["Built-in locking", "UI", "VCS integration", "Policy as code"]
        }
      ],
      "code_examples": [
        {
          "title": "S3 Backend Configuration",
          "code": "terraform {\n  backend \"s3\" {\n    bucket         = \"my-terraform-state\"\n    key            = \"prod/terraform.tfstate\"\n    region         = \"us-west-2\"\n    encrypt        = true\n    dynamodb_table = \"terraform-locks\"\n  }\n}"
        }
      ]
    },
    {
      "title": "State Locking",
      "content": "State locking prevents multiple users from running Terraform simultaneously, which could corrupt the state file.",
      "locking_benefits": [
        "Prevents concurrent modifications",
        "Ensures state consistency",
        "Provides operation visibility",
        "Enables safe team collaboration"
      ],
      "code_examples": [
        {
          "title": "DynamoDB Table for State Locking",
          "code": "resource \"aws_dynamodb_table\" \"terraform_locks\" {\n  name           = \"terraform-locks\"\n  billing_mode   = \"PAY_PER_REQUEST\"\n  hash_key       = \"LockID\"\n  \n  attribute {\n    name = \"LockID\"\n    type = \"S\"\n  }\n  \n  tags = {\n    Name = \"Terraform State Lock Table\"\n  }\n}"
        }
      ]
    },
    {
      "title": "State Commands",
      "content": "Terraform provides commands to inspect and manipulate state when necessary.",
      "commands": [
        {
          "command": "terraform state list",
          "description": "List all resources in state"
        },
        {
          "command": "terraform state show <resource>",
          "description": "Show detailed information about a resource"
        },
        {
          "command": "terraform state mv <source> <destination>",
          "description": "Move a resource in state"
        },
        {
          "command": "terraform state rm <resource>",
          "description": "Remove a resource from state"
        },
        {
          "command": "terraform state pull",
          "description": "Download and output remote state"
        },
        {
          "command": "terraform state push",
          "description": "Upload local state to remote backend"
        }
      ]
    },
    {
      "title": "State Best Practices",
      "content": "Following best practices ensures reliable and secure state management.",
      "best_practices": [
        {
          "practice": "Use Remote State",
          "description": "Always use remote state for team environments"
        },
        {
          "practice": "Enable State Locking",
          "description": "Configure locking to prevent concurrent modifications"
        },
        {
          "practice": "Backup State Files",
          "description": "Regularly backup state files and enable versioning"
        },
        {
          "practice": "Secure Sensitive Data",
          "description": "Use encryption and access controls for state storage"
        },
        {
          "practice": "Separate Environments",
          "description": "Use different state files for different environments"
        },
        {
          "practice": "Avoid Manual State Editing",
          "description": "Use Terraform commands instead of manual state file editing"
        }
      ]
    }
  ],
  "objectives": [
    "Understand the purpose and structure of Terraform state",
    "Configure remote state backends",
    "Implement state locking for team collaboration",
    "Use state commands for troubleshooting",
    "Apply state management best practices"
  ],
  "hands_on_exercises": [
    {
      "title": "Remote State Setup",
      "description": "Configure S3 backend with DynamoDB locking",
      "requirements": [
        "Create S3 bucket for state storage",
        "Create DynamoDB table for locking",
        "Configure backend in Terraform",
        "Migrate local state to remote backend"
      ]
    }
  ]
}',
'{"Terraform Variables and Outputs"}', 60);

-- Module 6: Terraform Modules
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Modules: Reusable Infrastructure Components', 'module', 'terraform', 'intermediate',
'{
  "sections": [
    {
      "title": "Introduction to Modules",
      "content": "Modules are containers for multiple resources that are used together. They enable code reuse, organization, and abstraction of complex infrastructure patterns.",
      "benefits": [
        "Code reusability across projects",
        "Better organization and structure",
        "Abstraction of complexity",
        "Standardization of patterns",
        "Easier testing and validation",
        "Team collaboration and sharing"
      ]
    },
    {
      "title": "Module Structure",
      "content": "A module is simply a directory containing Terraform configuration files. The root module is the working directory where Terraform is run.",
      "module_files": [
        {
          "file": "main.tf",
          "description": "Primary configuration file with resources"
        },
        {
          "file": "variables.tf",
          "description": "Input variable definitions"
        },
        {
          "file": "outputs.tf",
          "description": "Output value definitions"
        },
        {
          "file": "README.md",
          "description": "Documentation for module usage"
        },
        {
          "file": "versions.tf",
          "description": "Provider version constraints"
        }
      ],
      "directory_structure": "modules/\n└── vpc/\n    ├── main.tf\n    ├── variables.tf\n    ├── outputs.tf\n    ├── README.md\n    └── versions.tf"
    },
    {
      "title": "Creating a Module",
      "content": "Modules encapsulate related resources and expose a clean interface through variables and outputs.",
      "code_examples": [
        {
          "title": "VPC Module - variables.tf",
          "code": "variable \"vpc_cidr\" {\n  description = \"CIDR block for VPC\"\n  type        = string\n  default     = \"10.0.0.0/16\"\n}\n\nvariable \"environment\" {\n  description = \"Environment name\"\n  type        = string\n}\n\nvariable \"availability_zones\" {\n  description = \"List of availability zones\"\n  type        = list(string)\n}"
        },
        {
          "title": "VPC Module - main.tf",
          "code": "resource \"aws_vpc\" \"main\" {\n  cidr_block           = var.vpc_cidr\n  enable_dns_hostnames = true\n  enable_dns_support   = true\n  \n  tags = {\n    Name        = \"${var.environment}-vpc\"\n    Environment = var.environment\n  }\n}\n\nresource \"aws_subnet\" \"public\" {\n  count             = length(var.availability_zones)\n  vpc_id            = aws_vpc.main.id\n  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)\n  availability_zone = var.availability_zones[count.index]\n  \n  map_public_ip_on_launch = true\n  \n  tags = {\n    Name = \"${var.environment}-public-${count.index + 1}\"\n    Type = \"public\"\n  }\n}"
        },
        {
          "title": "VPC Module - outputs.tf",
          "code": "output \"vpc_id\" {\n  description = \"ID of the VPC\"\n  value       = aws_vpc.main.id\n}\n\noutput \"public_subnet_ids\" {\n  description = \"IDs of the public subnets\"\n  value       = aws_subnet.public[*].id\n}\n\noutput \"vpc_cidr_block\" {\n  description = \"CIDR block of the VPC\"\n  value       = aws_vpc.main.cidr_block\n}"
        }
      ]
    },
    {
      "title": "Using Modules",
      "content": "Modules are called from other configurations using module blocks, which specify the source and input variables.",
      "module_sources": [
        "Local paths (./modules/vpc)",
        "Git repositories (git::https://github.com/user/repo.git)",
        "Terraform Registry (terraform-aws-modules/vpc/aws)",
        "HTTP URLs",
        "S3 buckets"
      ],
      "code_examples": [
        {
          "title": "Using a Local Module",
          "code": "module \"vpc\" {\n  source = \"./modules/vpc\"\n  \n  vpc_cidr           = \"10.0.0.0/16\"\n  environment        = \"production\"\n  availability_zones = [\"us-west-2a\", \"us-west-2b\", \"us-west-2c\"]\n}\n\n# Reference module outputs\nresource \"aws_security_group\" \"web\" {\n  name   = \"web-sg\"\n  vpc_id = module.vpc.vpc_id\n  \n  ingress {\n    from_port   = 80\n    to_port     = 80\n    protocol    = \"tcp\"\n    cidr_blocks = [module.vpc.vpc_cidr_block]\n  }\n}"
        },
        {
          "title": "Using Registry Module",
          "code": "module \"vpc\" {\n  source  = \"terraform-aws-modules/vpc/aws\"\n  version = \"~> 3.0\"\n  \n  name = \"my-vpc\"\n  cidr = \"10.0.0.0/16\"\n  \n  azs             = [\"us-west-2a\", \"us-west-2b\", \"us-west-2c\"]\n  private_subnets = [\"10.0.1.0/24\", \"10.0.2.0/24\", \"10.0.3.0/24\"]\n  public_subnets  = [\"10.0.101.0/24\", \"10.0.102.0/24\", \"10.0.103.0/24\"]\n  \n  enable_nat_gateway = true\n  enable_vpn_gateway = true\n  \n  tags = {\n    Terraform   = \"true\"\n    Environment = \"dev\"\n  }\n}"
        }
      ]
    },
    {
      "title": "Module Composition",
      "content": "Complex infrastructure can be built by composing multiple modules together, creating layered architectures.",
      "composition_patterns": [
        {
          "pattern": "Layered Architecture",
          "description": "Network layer, compute layer, data layer modules"
        },
        {
          "pattern": "Service Modules",
          "description": "Complete service definitions with all dependencies"
        },
        {
          "pattern": "Environment Modules",
          "description": "Environment-specific configurations using base modules"
        }
      ],
      "code_examples": [
        {
          "title": "Module Composition Example",
          "code": "# Network layer\nmodule \"network\" {\n  source = \"./modules/network\"\n  \n  environment = var.environment\n  vpc_cidr    = var.vpc_cidr\n}\n\n# Compute layer\nmodule \"compute\" {\n  source = \"./modules/compute\"\n  \n  environment       = var.environment\n  vpc_id           = module.network.vpc_id\n  private_subnet_ids = module.network.private_subnet_ids\n  \n  depends_on = [module.network]\n}\n\n# Data layer\nmodule \"database\" {\n  source = \"./modules/database\"\n  \n  environment       = var.environment\n  vpc_id           = module.network.vpc_id\n  database_subnet_ids = module.network.database_subnet_ids\n  \n  depends_on = [module.network]\n}"
        }
      ]
    },
    {
      "title": "Module Best Practices",
      "content": "Following best practices ensures modules are maintainable, reusable, and reliable.",
      "best_practices": [
        {
          "practice": "Single Responsibility",
          "description": "Each module should have a single, well-defined purpose"
        },
        {
          "practice": "Clear Interface",
          "description": "Use descriptive variable names and comprehensive outputs"
        },
        {
          "practice": "Documentation",
          "description": "Include README with usage examples and requirements"
        },
        {
          "practice": "Version Constraints",
          "description": "Specify provider version constraints in modules"
        },
        {
          "practice": "Testing",
          "description": "Test modules with different input combinations"
        },
        {
          "practice": "Semantic Versioning",
          "description": "Use semantic versioning for module releases"
        }
      ]
    }
  ],
  "objectives": [
    "Understand module concepts and benefits",
    "Create reusable Terraform modules",
    "Use modules from different sources",
    "Compose complex infrastructure using modules",
    "Apply module development best practices"
  ],
  "hands_on_exercises": [
    {
      "title": "Web Application Module",
      "description": "Create a module for a complete web application stack",
      "requirements": [
        "Create module for load balancer, web servers, and database",
        "Define appropriate input variables and outputs",
        "Use the module in a root configuration",
        "Test with different variable values"
      ]
    }
  ]
}',
'{"Terraform State Management"}', 65);

-- Quiz 1: Terraform Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Fundamentals Quiz', 'quiz', 'terraform', 'beginner',
'{
  "questions": [
    {
      "question": "What is the primary benefit of Infrastructure as Code?",
      "options": [
        "Faster server performance",
        "Version control and reproducibility of infrastructure", 
        "Reduced hardware costs",
        "Better network security"
      ],
      "correct": 1,
      "explanation": "IaC allows infrastructure to be version controlled, making it reproducible, auditable, and manageable like application code."
    },
    {
      "question": "What language does Terraform use for configuration?",
      "options": ["JSON", "YAML", "HCL (HashiCorp Configuration Language)", "Python"],
      "correct": 2,
      "explanation": "Terraform uses HCL (HashiCorp Configuration Language), which is designed to be human-readable and machine-friendly."
    },
    {
      "question": "What is a Terraform provider?",
      "options": [
        "A cloud service company",
        "A plugin that interacts with APIs of platforms and services",
        "A configuration file",
        "A state management tool"
      ],
      "correct": 1,
      "explanation": "Providers are plugins that Terraform uses to interact with cloud platforms, SaaS providers, and other APIs."
    },
    {
      "question": "What is the correct order of Terraform workflow?",
      "options": [
        "Apply, Plan, Write, Destroy",
        "Write, Apply, Plan, Destroy",
        "Write, Plan, Apply, Destroy",
        "Plan, Write, Apply, Destroy"
      ],
      "correct": 2,
      "explanation": "The Terraform workflow is: Write configuration, Plan changes, Apply changes, and optionally Destroy resources."
    },
    {
      "question": "What file extension do Terraform configuration files use?",
      "options": [".terraform", ".tf", ".hcl", ".config"],
      "correct": 1,
      "explanation": "Terraform configuration files use the .tf extension and are written in HCL."
    }
  ],
  "passing_score": 80,
  "time_limit": 600
}',
'{"Terraform Fundamentals: Introduction to Infrastructure as Code", "Terraform Installation and Configuration"}', 15);

-- Quiz 2: Resources and Variables
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Resources and Variables Quiz', 'quiz', 'terraform', 'intermediate',
'{
  "questions": [
    {
      "question": "What is the syntax for referencing a resource attribute?",
      "options": [
        "resource.type.name.attribute",
        "type.name.attribute",
        "resource_type.resource_name.attribute",
        "${resource_type.resource_name.attribute}"
      ],
      "correct": 2,
      "explanation": "Resource attributes are referenced using the syntax: resource_type.resource_name.attribute"
    },
    {
      "question": "What is the difference between a resource and a data source?",
      "options": [
        "Resources create infrastructure, data sources fetch existing information",
        "Resources are for AWS, data sources are for Azure", 
        "Resources are required, data sources are optional",
        "There is no difference"
      ],
      "correct": 0,
      "explanation": "Resources create and manage infrastructure objects, while data sources fetch information about existing infrastructure."
    },
    {
      "question": "Which variable assignment method has the highest precedence?",
      "options": [
        "Environment variables",
        "terraform.tfvars file",
        "Command line -var flags",
        "Default values in variable blocks"
      ],
      "correct": 2,
      "explanation": "Command line -var flags have the highest precedence in Terraform variable assignment."
    },
    {
      "question": "What keyword is used to create local values in Terraform?",
      "options": ["local", "locals", "values", "vars"],
      "correct": 1,
      "explanation": "The locals block is used to define local values that can be referenced throughout the configuration."
    },
    {
      "question": "How do you mark an output value as sensitive?",
      "options": [
        "Add sensitive = true to the output block",
        "Use the sensitive() function",
        "Prefix the name with underscore",
        "Store it in a separate file"
      ],
      "correct": 0,
      "explanation": "Adding sensitive = true to an output block marks it as sensitive and prevents it from being displayed in logs."
    },
    {
      "question": "What is the purpose of variable validation blocks?",
      "options": [
        "To set default values",
        "To define variable types",
        "To enforce custom validation rules",
        "To document variables"
      ],
      "correct": 2,
      "explanation": "Validation blocks allow you to define custom rules to validate variable values before they are used."
    }
  ],
  "passing_score": 75,
  "time_limit": 900
}',
'{"Terraform Resources and Data Sources", "Terraform Variables and Outputs"}', 20);

-- Quiz 3: Advanced Terraform Concepts
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Advanced Terraform Concepts Quiz', 'quiz', 'terraform', 'advanced',
'{
  "questions": [
    {
      "question": "What is the primary purpose of Terraform state?",
      "options": [
        "Store configuration files",
        "Map configuration to real-world resources",
        "Store provider credentials",
        "Cache downloaded providers"
      ],
      "correct": 1,
      "explanation": "Terraform state maps your configuration to real-world resources and tracks metadata about those resources."
    },
    {
      "question": "Why is remote state recommended for team environments?",
      "options": [
        "It is faster than local state",
        "It provides state locking and collaboration features",
        "It is required by Terraform",
        "It reduces costs"
      ],
      "correct": 1,
      "explanation": "Remote state enables state locking, prevents concurrent modifications, and allows team collaboration."
    },
    {
      "question": "What command would you use to see all resources in the current state?",
      "options": [
        "terraform state list",
        "terraform show",
        "terraform state show",
        "terraform list"
      ],
      "correct": 0,
      "explanation": "terraform state list shows all resources currently tracked in the Terraform state."
    },
    {
      "question": "What is the main benefit of using Terraform modules?",
      "options": [
        "Faster execution",
        "Code reusability and organization",
        "Better security",
        "Reduced costs"
      ],
      "correct": 1,
      "explanation": "Modules enable code reusability, better organization, and abstraction of complex infrastructure patterns."
    },
    {
      "question": "How do you reference an output from a module?",
      "options": [
        "module.module_name.output_name",
        "output.module_name.output_name",
        "module_name.output_name",
        "${module.module_name.output_name}"
      ],
      "correct": 0,
      "explanation": "Module outputs are referenced using the syntax: module.module_name.output_name"
    },
    {
      "question": "What is the recommended approach for managing different environments in Terraform?",
      "options": [
        "Use the same state file for all environments",
        "Use separate state files and configurations for each environment",
        "Use different providers for each environment",
        "Use environment variables only"
      ],
      "correct": 1,
      "explanation": "Best practice is to use separate state files and configurations for each environment to prevent accidental changes."
    }
  ],
  "passing_score": 80,
  "time_limit": 1200
}',
'{"Terraform State Management", "Terraform Modules: Reusable Infrastructure Components"}', 25);

-- Lab 1: Basic Terraform Setup and Resources
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Setup and Basic Resources Lab', 'lab', 'terraform', 'beginner',
'{
  "description": "Set up Terraform environment and create basic Docker resources to understand Terraform workflow",
  "learning_objectives": [
    "Install and configure Terraform",
    "Create basic resource configurations",
    "Understand Terraform workflow (init, plan, apply)",
    "Manage resource lifecycle"
  ],
  "environment": {
    "type": "terraform",
    "containers": [
      {
        "name": "terraform-workspace",
        "image": "hashicorp/terraform:latest",
        "role": "terraform_client"
      },
      {
        "name": "docker-daemon",
        "image": "docker:dind",
        "role": "docker_host",
        "privileged": true
      }
    ]
  },
  "tasks": [
    {
      "title": "Verify Terraform Installation",
      "description": "Check that Terraform is properly installed and working",
      "instructions": [
        "Run terraform version to check installation",
        "Verify Docker provider availability",
        "Check available commands with terraform -help"
      ],
      "validation": {
        "command": "terraform version",
        "expected_output": "Terraform v"
      }
    },
    {
      "title": "Create Basic Configuration",
      "description": "Create a simple Terraform configuration for Docker resources",
      "instructions": [
        "Create main.tf file",
        "Configure Docker provider",
        "Define a Docker image resource",
        "Define a Docker container resource"
      ],
      "template": "terraform {\n  required_providers {\n    docker = {\n      source  = \"kreuzwerker/docker\"\n      version = \"~> 3.0\"\n    }\n  }\n}\n\nprovider \"docker\" {\n  host = \"tcp://docker-daemon:2376\"\n}\n\n# Add your resources here",
      "validation": {
        "command": "terraform validate",
        "expected_output": "Success"
      }
    },
    {
      "title": "Initialize Terraform",
      "description": "Initialize the Terraform working directory",
      "instructions": [
        "Run terraform init to initialize the directory",
        "Observe the .terraform directory creation",
        "Check the lock file creation"
      ],
      "validation": {
        "command": "terraform init",
        "expected_output": "Terraform has been successfully initialized"
      }
    },
    {
      "title": "Plan Infrastructure Changes",
      "description": "Create an execution plan to preview changes",
      "instructions": [
        "Run terraform plan to see planned changes",
        "Analyze the output to understand what will be created",
        "Save the plan to a file using -out option"
      ],
      "validation": {
        "command": "terraform plan",
        "expected_output": "Plan:"
      }
    },
    {
      "title": "Apply Configuration",
      "description": "Apply the configuration to create resources",
      "instructions": [
        "Run terraform apply to create resources",
        "Confirm the apply when prompted",
        "Verify resources are created successfully",
        "Check the terraform.tfstate file"
      ],
      "validation": {
        "command": "terraform apply -auto-approve",
        "expected_output": "Apply complete"
      }
    },
    {
      "title": "Inspect State and Resources",
      "description": "Examine the created resources and state",
      "instructions": [
        "Use terraform state list to see managed resources",
        "Use terraform state show to inspect specific resources",
        "Verify container is running with docker ps"
      ],
      "validation": {
        "command": "terraform state list",
        "expected_output": "docker_"
      }
    },
    {
      "title": "Modify and Update Resources",
      "description": "Make changes to the configuration and apply updates",
      "instructions": [
        "Modify container configuration (add environment variables)",
        "Run terraform plan to see the changes",
        "Apply the changes",
        "Verify the updates were applied"
      ],
      "validation": {
        "command": "terraform plan",
        "expected_output": "will be updated in-place"
      }
    },
    {
      "title": "Destroy Resources",
      "description": "Clean up resources using Terraform",
      "instructions": [
        "Run terraform destroy to remove all resources",
        "Confirm the destruction when prompted",
        "Verify all resources are removed",
        "Check that state file is updated"
      ],
      "validation": {
        "command": "terraform destroy -auto-approve",
        "expected_output": "Destroy complete"
      }
    }
  ],
  "completion_criteria": [
    "Terraform is properly installed and configured",
    "Basic Docker resources are successfully created and managed",
    "Terraform workflow (init, plan, apply, destroy) is understood",
    "State management concepts are demonstrated"
  ]
}',
'{"Terraform Installation and Configuration"}', 60);

-- Lab 2: Variables and Outputs
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform Variables and Outputs Lab', 'lab', 'terraform', 'intermediate',
'{
  "description": "Create a flexible Terraform configuration using variables and outputs for a multi-container application",
  "learning_objectives": [
    "Define and use input variables effectively",
    "Create meaningful output values",
    "Use variable files for different environments",
    "Implement variable validation and local values"
  ],
  "environment": {
    "type": "terraform",
    "containers": [
      {
        "name": "terraform-workspace",
        "image": "hashicorp/terraform:latest",
        "role": "terraform_client"
      },
      {
        "name": "docker-daemon",
        "image": "docker:dind",
        "role": "docker_host",
        "privileged": true
      }
    ]
  },
  "tasks": [
    {
      "title": "Create Variable Definitions",
      "description": "Define input variables for a web application stack",
      "instructions": [
        "Create variables.tf file",
        "Define variables for environment, app name, and port",
        "Add variable descriptions and types",
        "Include validation rules where appropriate"
      ],
      "template": "variable \"environment\" {\n  description = \"Environment name\"\n  type        = string\n  default     = \"dev\"\n  \n  validation {\n    condition     = contains([\"dev\", \"staging\", \"prod\"], var.environment)\n    error_message = \"Environment must be dev, staging, or prod.\"\n  }\n}\n\n# Add more variables here",
      "validation": {
        "command": "terraform validate",
        "expected_output": "Success"
      }
    },
    {
      "title": "Create Main Configuration with Variables",
      "description": "Use variables in resource configuration",
      "instructions": [
        "Update main.tf to use defined variables",
        "Create nginx container with variable-driven configuration",
        "Use locals for computed values",
        "Reference variables in resource names and tags"
      ],
      "validation": {
        "command": "terraform plan",
        "expected_output": "Plan:"
      }
    },
    {
      "title": "Define Output Values",
      "description": "Create outputs to expose important resource information",
      "instructions": [
        "Create outputs.tf file",
        "Define outputs for container ID, name, and IP address",
        "Add descriptions to all outputs",
        "Mark sensitive outputs appropriately"
      ],
      "template": "output \"container_id\" {\n  description = \"ID of the nginx container\"\n  value       = docker_container.nginx.id\n}\n\n# Add more outputs here",
      "validation": {
        "command": "terraform validate",
        "expected_output": "Success"
      }
    },
    {
      "title": "Create Environment-Specific Variable Files",
      "description": "Create .tfvars files for different environments",
      "instructions": [
        "Create dev.tfvars with development values",
        "Create prod.tfvars with production values",
        "Include different port numbers and resource counts",
        "Test with different variable files"
      ],
      "validation": {
        "command": "terraform plan -var-file=dev.tfvars",
        "expected_output": "Plan:"
      }
    },
    {
      "title": "Apply Configuration with Variables",
      "description": "Deploy infrastructure using variable files",
      "instructions": [
        "Apply configuration using dev.tfvars",
        "Verify outputs are displayed correctly",
        "Test with different variable values",
        "Observe how changes affect the infrastructure"
      ],
      "validation": {
        "command": "terraform apply -var-file=dev.tfvars -auto-approve",
        "expected_output": "Apply complete"
      }
    },
    {
      "title": "Test Variable Validation",
      "description": "Test variable validation rules",
      "instructions": [
        "Try to apply with invalid environment value",
        "Observe validation error messages",
        "Test other validation rules",
        "Fix validation errors and apply successfully"
      ],
      "validation": {
        "command": "terraform plan -var=\"environment=invalid\"",
        "expected_output": "Error"
      }
    },
    {
      "title": "Use Command Line Variables",
      "description": "Override variables using command line flags",
      "instructions": [
        "Use -var flag to override specific variables",
        "Test variable precedence with different methods",
        "Use environment variables (TF_VAR_*)",
        "Understand variable precedence order"
      ],
      "validation": {
        "command": "terraform plan -var=\"app_name=cli-override\"",
        "expected_output": "cli-override"
      }
    },
    {
      "title": "Extract and Use Outputs",
      "description": "Access output values for use in other configurations",
      "instructions": [
        "Use terraform output to display all outputs",
        "Extract specific output values",
        "Format outputs for use in scripts",
        "Understand output usage patterns"
      ],
      "validation": {
        "command": "terraform output",
        "expected_output": "container_id"
      }
    }
  ],
  "completion_criteria": [
    "Variables are properly defined with types and validation",
    "Configuration uses variables effectively throughout",
    "Outputs provide meaningful information about resources",
    "Different environments can be deployed using variable files"
  ]
}',
'{"Terraform Variables and Outputs"}', 75);

-- Lab 3: State Management and Modules
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Terraform State Management and Modules Lab', 'lab', 'terraform', 'advanced',
'{
  "description": "Implement remote state management and create reusable modules for a complete application stack",
  "learning_objectives": [
    "Configure remote state backend",
    "Create and use Terraform modules",
    "Implement state locking",
    "Build modular infrastructure architecture"
  ],
  "environment": {
    "type": "terraform",
    "containers": [
      {
        "name": "terraform-workspace",
        "image": "hashicorp/terraform:latest",
        "role": "terraform_client"
      },
      {
        "name": "docker-daemon",
        "image": "docker:dind",
        "role": "docker_host",
        "privileged": true
      },
      {
        "name": "minio",
        "image": "minio/minio:latest",
        "role": "s3_backend",
        "environment": {
          "MINIO_ROOT_USER": "terraform",
          "MINIO_ROOT_PASSWORD": "terraform123"
        }
      }
    ]
  },
  "tasks": [
    {
      "title": "Set Up Remote State Backend",
      "description": "Configure S3-compatible backend for remote state storage",
      "instructions": [
        "Configure backend block in terraform configuration",
        "Create S3 bucket using MinIO for state storage",
        "Initialize Terraform with remote backend",
        "Verify state is stored remotely"
      ],
      "template": "terraform {\n  backend \"s3\" {\n    bucket                      = \"terraform-state\"\n    key                         = \"dev/terraform.tfstate\"\n    endpoint                    = \"http://minio:9000\"\n    access_key                  = \"terraform\"\n    secret_key                  = \"terraform123\"\n    region                      = \"us-east-1\"\n    force_path_style           = true\n    skip_credentials_validation = true\n    skip_metadata_api_check    = true\n    skip_region_validation     = true\n  }\n}",
      "validation": {
        "command": "terraform init",
        "expected_output": "Successfully configured the backend"
      }
    },
    {
      "title": "Create Web Server Module",
      "description": "Build a reusable module for web server deployment",
      "instructions": [
        "Create modules/webserver directory structure",
        "Define variables.tf with input parameters",
        "Create main.tf with nginx container resources",
        "Define outputs.tf with container information"
      ],
      "directory_structure": "modules/\n└── webserver/\n    ├── main.tf\n    ├── variables.tf\n    └── outputs.tf",
      "validation": {
        "command": "ls -la modules/webserver/",
        "expected_files": ["main.tf", "variables.tf", "outputs.tf"]
      }
    },
    {
      "title": "Create Database Module",
      "description": "Build a module for database container deployment",
      "instructions": [
        "Create modules/database directory",
        "Define PostgreSQL container configuration",
        "Include environment variables and volume mounts",
        "Create appropriate outputs for connection info"
      ],
      "validation": {
        "command": "terraform validate",
        "expected_output": "Success"
      }
    },
    {
      "title": "Create Root Configuration Using Modules",
      "description": "Use created modules in a root configuration",
      "instructions": [
        "Create main.tf that calls webserver and database modules",
        "Pass appropriate variables to modules",
        "Reference module outputs in root outputs",
        "Create environment-specific configurations"
      ],
      "template": "module \"webserver\" {\n  source = \"./modules/webserver\"\n  \n  app_name    = var.app_name\n  environment = var.environment\n  port        = var.web_port\n}\n\nmodule \"database\" {\n  source = \"./modules/database\"\n  \n  db_name     = var.db_name\n  environment = var.environment\n}",
      "validation": {
        "command": "terraform plan",
        "expected_output": "Plan:"
      }
    },
    {
      "title": "Test Module Composition",
      "description": "Deploy and test the modular infrastructure",
      "instructions": [
        "Apply the configuration to create all resources",
        "Verify both web server and database are running",
        "Test connectivity between modules",
        "Validate module outputs are accessible"
      ],
      "validation": {
        "command": "terraform apply -auto-approve",
        "expected_output": "Apply complete"
      }
    },
    {
      "title": "Implement State Commands",
      "description": "Use Terraform state commands for management",
      "instructions": [
        "List all resources in state",
        "Show detailed information about specific resources",
        "Practice state manipulation commands",
        "Understand state file structure"
      ],
      "validation": {
        "command": "terraform state list",
        "expected_output": "module."
      }
    },
    {
      "title": "Test Module Reusability",
      "description": "Create multiple instances using the same modules",
      "instructions": [
        "Create staging environment using same modules",
        "Use different variable values for staging",
        "Deploy both dev and staging simultaneously",
        "Verify isolation between environments"
      ],
      "validation": {
        "command": "terraform workspace list",
        "expected_output": "default"
      }
    },
    {
      "title": "Validate Remote State Functionality",
      "description": "Verify remote state is working correctly",
      "instructions": [
        "Check state file exists in remote backend",
        "Simulate team collaboration scenario",
        "Test state locking (if configured)",
        "Verify state consistency across operations"
      ],
      "validation": {
        "command": "terraform state pull",
        "expected_output": "version"
      }
    }
  ],
  "completion_criteria": [
    "Remote state backend is properly configured and functional",
    "Reusable modules are created with clear interfaces",
    "Modular architecture is successfully deployed",
    "State management commands are understood and used effectively"
  ]
}',
'{"Terraform State Management", "Terraform Modules: Reusable Infrastructure Components"}', 90);

-- Assessment: Comprehensive Terraform Skills
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Comprehensive Terraform Assessment', 'quiz', 'terraform', 'advanced',
'{
  "description": "Comprehensive assessment covering all Terraform concepts from basics to advanced module development and state management",
  "questions": [
    {
      "question": "You need to deploy the same infrastructure across multiple environments. What is the most efficient Terraform approach?",
      "options": [
        "Copy configuration files for each environment",
        "Use modules with environment-specific variable files",
        "Create separate providers for each environment",
        "Use different Terraform versions for each environment"
      ],
      "correct": 1,
      "explanation": "Using modules with environment-specific variable files provides reusability, maintainability, and consistency across environments."
    },
    {
      "question": "What happens when you run terraform plan?",
      "options": [
        "It applies changes to infrastructure",
        "It creates an execution plan showing what will be changed",
        "It initializes the working directory",
        "It destroys existing resources"
      ],
      "correct": 1,
      "explanation": "terraform plan creates an execution plan, showing what actions Terraform will take to reach the desired state."
    },
    {
      "question": "Which backend feature is essential for team collaboration?",
      "options": [
        "State encryption",
        "State versioning",
        "State locking",
        "State compression"
      ],
      "correct": 2,
      "explanation": "State locking prevents multiple team members from running Terraform simultaneously, which could corrupt the state."
    },
    {
      "question": "How do you reference an attribute from a data source?",
      "options": [
        "data.type.name.attribute",
        "datasource.type.name.attribute",
        "source.type.name.attribute",
        "data_source.type.name.attribute"
      ],
      "correct": 0,
      "explanation": "Data source attributes are referenced using the syntax: data.type.name.attribute"
    },
    {
      "question": "What is the purpose of the depends_on argument?",
      "options": [
        "To specify resource types",
        "To create explicit dependencies between resources",
        "To define variable dependencies",
        "To set provider dependencies"
      ],
      "correct": 1,
      "explanation": "depends_on creates explicit dependencies when Terraform cannot automatically determine the dependency relationship."
    },
    {
      "question": "Which command would you use to import existing infrastructure into Terraform state?",
      "options": [
        "terraform import",
        "terraform add",
        "terraform include",
        "terraform attach"
      ],
      "correct": 0,
      "explanation": "terraform import is used to import existing infrastructure resources into Terraform state management."
    },
    {
      "question": "What is the recommended way to handle sensitive values in Terraform?",
      "options": [
        "Store them in plain text in .tf files",
        "Use environment variables and mark outputs as sensitive",
        "Put them in comments",
        "Store them in a separate repository"
      ],
      "correct": 1,
      "explanation": "Sensitive values should be passed via environment variables or secure backends, and outputs should be marked as sensitive."
    },
    {
      "question": "How do you specify a minimum Terraform version requirement?",
      "options": [
        "In the provider block",
        "In the terraform block with required_version",
        "In a separate version.tf file",
        "As a command line argument"
      ],
      "correct": 1,
      "explanation": "Version requirements are specified in the terraform block using the required_version argument."
    },
    {
      "question": "What is the difference between count and for_each?",
      "options": [
        "count is for numbers, for_each is for strings",
        "count creates indexed instances, for_each creates named instances",
        "count is deprecated, for_each is current",
        "There is no difference"
      ],
      "correct": 1,
      "explanation": "count creates indexed instances (0, 1, 2...), while for_each creates instances with meaningful keys from a map or set."
    },
    {
      "question": "When should you use terraform refresh?",
      "options": [
        "Before every terraform apply",
        "To update state with real-world changes made outside Terraform",
        "To download new provider versions",
        "To validate configuration syntax"
      ],
      "correct": 1,
      "explanation": "terraform refresh updates the state file with the current state of real infrastructure, useful when changes were made outside Terraform."
    }
  ],
  "passing_score": 80,
  "time_limit": 1800,
  "certification": {
    "name": "Terraform Infrastructure Automation Specialist",
    "description": "Demonstrates comprehensive understanding of Terraform Infrastructure as Code concepts and practical skills"
  }
}',
'{"Terraform Fundamentals Quiz", "Terraform Resources and Variables Quiz", "Advanced Terraform Concepts Quiz", "Terraform Setup and Basic Resources Lab", "Terraform Variables and Outputs Lab", "Terraform State Management and Modules Lab"}', 30);