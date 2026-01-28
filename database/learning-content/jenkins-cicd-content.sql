-- Comprehensive Jenkins CI/CD Learning Content
-- This file contains detailed learning modules, quizzes, and lab exercises for Jenkins and CI/CD practices

\c devops_practice;

-- Delete existing basic Jenkins content to replace with comprehensive content
DELETE FROM learning.learning_content WHERE tool_category = 'jenkins';

-- Module 1: CI/CD Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('CI/CD Fundamentals with Jenkins', 'module', 'jenkins', 'beginner', 
'{
  "sections": [
    {
      "title": "What is CI/CD?",
      "content": "Continuous Integration and Continuous Deployment (CI/CD) is a software development practice that enables teams to deliver code changes more frequently and reliably through automation.",
      "ci_definition": "Continuous Integration is the practice of merging code changes frequently into a shared repository, with each change verified by automated builds and tests.",
      "cd_definition": "Continuous Deployment extends CI by automatically deploying all code changes to production after passing automated tests.",
      "benefits": [
        "Faster time to market",
        "Reduced risk of deployment failures",
        "Improved code quality through automated testing",
        "Better collaboration between development and operations",
        "Faster feedback loops",
        "Reduced manual errors"
      ]
    },
    {
      "title": "CI/CD Pipeline Components",
      "content": "A typical CI/CD pipeline consists of several stages that automate the software delivery process.",
      "pipeline_stages": [
        {
          "stage": "Source Control",
          "description": "Code is committed to version control system (Git)",
          "tools": ["Git", "GitHub", "GitLab", "Bitbucket"]
        },
        {
          "stage": "Build",
          "description": "Code is compiled and packaged into deployable artifacts",
          "tools": ["Maven", "Gradle", "npm", "Docker"]
        },
        {
          "stage": "Test",
          "description": "Automated tests verify code quality and functionality",
          "test_types": ["Unit tests", "Integration tests", "Security tests", "Performance tests"]
        },
        {
          "stage": "Deploy",
          "description": "Artifacts are deployed to target environments",
          "environments": ["Development", "Staging", "Production"]
        },
        {
          "stage": "Monitor",
          "description": "Applications are monitored for performance and issues",
          "tools": ["Prometheus", "Grafana", "ELK Stack"]
        }
      ]
    },
    {
      "title": "Introduction to Jenkins",
      "content": "Jenkins is an open-source automation server that enables developers to build, test, and deploy applications through CI/CD pipelines.",
      "jenkins_features": [
        "Extensible plugin ecosystem (1800+ plugins)",
        "Distributed builds across multiple machines",
        "Pipeline as Code with Jenkinsfile",
        "Integration with version control systems",
        "Web-based user interface",
        "REST API for automation"
      ],
      "jenkins_architecture": {
        "master": "Coordinates builds, manages plugins, and serves web UI",
        "agents": "Execute build jobs on behalf of the master",
        "executors": "Slots for running builds on master or agents"
      }
    },
    {
      "title": "Jenkins vs Other CI/CD Tools",
      "content": "Comparison of Jenkins with other popular CI/CD platforms.",
      "tool_comparison": [
        {
          "tool": "Jenkins",
          "pros": ["Open source", "Highly customizable", "Large plugin ecosystem"],
          "cons": ["Complex setup", "Maintenance overhead", "UI can be outdated"]
        },
        {
          "tool": "GitHub Actions",
          "pros": ["Integrated with GitHub", "Easy setup", "Good for open source"],
          "cons": ["Limited to GitHub", "Can be expensive for private repos"]
        },
        {
          "tool": "GitLab CI",
          "pros": ["Integrated platform", "Built-in Docker support", "Good documentation"],
          "cons": ["Resource intensive", "Learning curve for complex pipelines"]
        }
      ]
    }
  ],
  "objectives": [
    "Understand CI/CD principles and benefits",
    "Learn Jenkins architecture and components",
    "Compare different CI/CD tools and platforms",
    "Identify use cases for automated pipelines"
  ],
  "interactive_elements": [
    {
      "type": "knowledge_check",
      "question": "What is the main goal of Continuous Integration?",
      "options": [
        "Deploy to production automatically",
        "Merge code changes frequently with automated verification",
        "Monitor application performance",
        "Manage infrastructure as code"
      ],
      "correct": 1,
      "explanation": "Continuous Integration focuses on merging code changes frequently into a shared repository with automated builds and tests to catch issues early."
    }
  ]
}', 
'{}', 50);

-- Module 2: Jenkins Installation and Configuration
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Jenkins Installation and Configuration', 'module', 'jenkins', 'beginner',
'{
  "sections": [
    {
      "title": "Jenkins Installation Methods",
      "content": "Jenkins can be installed using various methods depending on your environment and requirements.",
      "installation_options": [
        {
          "method": "Docker",
          "description": "Quick setup using Docker containers",
          "pros": ["Easy to start", "Isolated environment", "Version control"],
          "command": "docker run -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts"
        },
        {
          "method": "Package Manager",
          "description": "Install using system package managers",
          "ubuntu_commands": [
            "wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -",
            "sudo sh -c echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list",
            "sudo apt update",
            "sudo apt install jenkins"
          ]
        },
        {
          "method": "WAR File",
          "description": "Run Jenkins as a standalone application",
          "command": "java -jar jenkins.war --httpPort=8080"
        },
        {
          "method": "Kubernetes",
          "description": "Deploy Jenkins on Kubernetes cluster",
          "benefits": ["Scalability", "High availability", "Cloud-native"]
        }
      ]
    },
    {
      "title": "Initial Setup and Configuration",
      "content": "Complete the initial Jenkins setup including security configuration and plugin installation.",
      "setup_steps": [
        {
          "step": "Access Jenkins Web Interface",
          "description": "Navigate to http://localhost:8080 after installation"
        },
        {
          "step": "Unlock Jenkins",
          "description": "Enter the initial admin password found in initialAdminPassword file"
        },
        {
          "step": "Install Plugins",
          "description": "Choose suggested plugins or select specific plugins for your needs"
        },
        {
          "step": "Create Admin User",
          "description": "Set up the first admin user account"
        },
        {
          "step": "Configure Instance",
          "description": "Set Jenkins URL and other basic configurations"
        }
      ],
      "essential_plugins": [
        "Git plugin - Version control integration",
        "Pipeline plugin - Pipeline as Code support",
        "Blue Ocean - Modern UI for pipelines",
        "Docker plugin - Docker integration",
        "Slack Notification - Team communication",
        "Build Timeout - Prevent hanging builds"
      ]
    },
    {
      "title": "Jenkins Security Configuration",
      "content": "Configure Jenkins security settings to protect your CI/CD environment.",
      "security_aspects": [
        {
          "aspect": "Authentication",
          "description": "Control who can access Jenkins",
          "options": ["Jenkins database", "LDAP", "Active Directory", "GitHub OAuth"]
        },
        {
          "aspect": "Authorization",
          "description": "Control what users can do in Jenkins",
          "strategies": ["Matrix-based security", "Project-based security", "Role-based security"]
        },
        {
          "aspect": "CSRF Protection",
          "description": "Prevent Cross-Site Request Forgery attacks",
          "setting": "Enable CSRF Protection in Global Security settings"
        },
        {
          "aspect": "Agent Security",
          "description": "Secure communication between master and agents",
          "methods": ["JNLP protocols", "SSH connections", "Certificate-based authentication"]
        }
      ]
    },
    {
      "title": "Global Tool Configuration",
      "content": "Configure global tools that will be available to all Jenkins jobs.",
      "tool_categories": [
        {
          "category": "JDK",
          "description": "Java Development Kit installations",
          "configuration": "Manage Jenkins > Global Tool Configuration > JDK"
        },
        {
          "category": "Git",
          "description": "Git executable path",
          "note": "Usually auto-detected on most systems"
        },
        {
          "category": "Maven",
          "description": "Apache Maven installations",
          "versions": ["3.6.3", "3.8.1", "3.9.0"]
        },
        {
          "category": "Node.js",
          "description": "Node.js runtime for JavaScript projects",
          "plugin_required": "NodeJS Plugin"
        },
        {
          "category": "Docker",
          "description": "Docker installation for containerized builds",
          "configuration": "Docker plugin settings"
        }
      ]
    },
    {
      "title": "Jenkins System Configuration",
      "content": "Configure system-wide Jenkins settings for optimal performance.",
      "system_settings": [
        {
          "setting": "Number of Executors",
          "description": "Controls how many builds can run simultaneously on master",
          "recommendation": "Set to 0 for master, use agents for builds"
        },
        {
          "setting": "Quiet Period",
          "description": "Delay before starting builds to batch multiple triggers",
          "default": "5 seconds"
        },
        {
          "setting": "SCM Checkout Retry Count",
          "description": "Number of retries for source code checkout failures",
          "default": "0"
        },
        {
          "setting": "Workspace Cleanup",
          "description": "Automatic cleanup of old workspaces",
          "plugin": "Workspace Cleanup Plugin"
        }
      ]
    }
  ],
  "objectives": [
    "Install Jenkins using different methods",
    "Complete initial setup and security configuration",
    "Install and configure essential plugins",
    "Configure global tools and system settings"
  ],
  "hands_on_exercises": [
    {
      "title": "Docker Installation",
      "description": "Install Jenkins using Docker and complete initial setup",
      "steps": [
        "Pull Jenkins Docker image",
        "Run Jenkins container with proper port mapping",
        "Complete web-based setup wizard",
        "Install recommended plugins"
      ]
    }
  ]
}',
'{"CI/CD Fundamentals with Jenkins"}', 60);

-- Module 3: Jenkins Jobs and Builds
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Jenkins Jobs and Build Management', 'module', 'jenkins', 'intermediate',
'{
  "sections": [
    {
      "title": "Types of Jenkins Jobs",
      "content": "Jenkins supports different types of jobs for various automation scenarios.",
      "job_types": [
        {
          "type": "Freestyle Project",
          "description": "Traditional job type with GUI configuration",
          "use_cases": ["Simple build tasks", "Legacy projects", "Quick prototyping"],
          "pros": ["Easy to configure", "Visual interface", "Good for beginners"],
          "cons": ["Limited version control", "Hard to maintain", "Not scalable"]
        },
        {
          "type": "Pipeline",
          "description": "Jobs defined as code using Groovy DSL",
          "use_cases": ["Complex workflows", "Modern CI/CD", "Version-controlled pipelines"],
          "pros": ["Pipeline as Code", "Version controlled", "Highly flexible"],
          "cons": ["Learning curve", "Groovy knowledge required"]
        },
        {
          "type": "Multi-configuration Project",
          "description": "Run same job with different configurations",
          "use_cases": ["Matrix builds", "Multiple environments", "Cross-platform testing"]
        },
        {
          "type": "Folder",
          "description": "Organize jobs into hierarchical structure",
          "benefits": ["Better organization", "Access control", "Namespace management"]
        }
      ]
    },
    {
      "title": "Creating Freestyle Jobs",
      "content": "Step-by-step guide to creating and configuring freestyle jobs.",
      "configuration_sections": [
        {
          "section": "General",
          "settings": ["Project name", "Description", "Discard old builds", "GitHub project URL"]
        },
        {
          "section": "Source Code Management",
          "options": ["Git", "Subversion", "Mercurial", "None"],
          "git_config": {
            "repository_url": "https://github.com/user/repo.git",
            "credentials": "Username/password or SSH key",
            "branches": "*/main or specific branch",
            "additional_behaviors": ["Clean before checkout", "Checkout to subdirectory"]
          }
        },
        {
          "section": "Build Triggers",
          "triggers": [
            "Build after other projects are built",
            "Build periodically (cron syntax)",
            "GitHub hook trigger for GITScm polling",
            "Poll SCM (check for changes periodically)",
            "Trigger builds remotely"
          ]
        },
        {
          "section": "Build Environment",
          "options": [
            "Delete workspace before build starts",
            "Use secret text(s) or file(s)",
            "Add timestamps to Console Output",
            "Set Build Name",
            "Timeout strategy"
          ]
        },
        {
          "section": "Build Steps",
          "step_types": [
            "Execute shell (Linux/Mac)",
            "Execute Windows batch command",
            "Invoke Ant",
            "Invoke Gradle script",
            "Invoke top-level Maven targets"
          ]
        }
      ]
    },
    {
      "title": "Build Parameters and Variables",
      "content": "Make jobs flexible using parameters and environment variables.",
      "parameter_types": [
        {
          "type": "String Parameter",
          "description": "Simple text input",
          "example": "BRANCH_NAME with default value main"
        },
        {
          "type": "Choice Parameter",
          "description": "Dropdown selection",
          "example": "ENVIRONMENT with options: dev, staging, prod"
        },
        {
          "type": "Boolean Parameter",
          "description": "Checkbox for true/false values",
          "example": "SKIP_TESTS to optionally skip test execution"
        },
        {
          "type": "File Parameter",
          "description": "Upload file for build",
          "example": "CONFIG_FILE for deployment configuration"
        }
      ],
      "environment_variables": [
        "BUILD_NUMBER - Current build number",
        "BUILD_URL - URL to current build",
        "JOB_NAME - Name of the job",
        "WORKSPACE - Path to job workspace",
        "GIT_COMMIT - Git commit hash",
        "GIT_BRANCH - Git branch name"
      ]
    },
    {
      "title": "Build Artifacts and Reports",
      "content": "Manage build outputs and generate reports for better visibility.",
      "artifact_management": {
        "description": "Preserve important files from builds for later use",
        "configuration": "Post-build Actions > Archive the artifacts",
        "patterns": ["target/*.jar", "dist/**", "reports/*.html"],
        "benefits": ["Deployment packages", "Test reports", "Documentation"]
      },
      "report_types": [
        {
          "type": "JUnit Test Results",
          "description": "Display test results and trends",
          "file_pattern": "target/surefire-reports/*.xml"
        },
        {
          "type": "Code Coverage",
          "description": "Show code coverage metrics",
          "tools": ["JaCoCo", "Cobertura", "Clover"]
        },
        {
          "type": "Static Analysis",
          "description": "Code quality and security analysis",
          "tools": ["SonarQube", "Checkstyle", "FindBugs"]
        }
      ]
    },
    {
      "title": "Build Notifications",
      "content": "Configure notifications to keep teams informed about build status.",
      "notification_methods": [
        {
          "method": "Email",
          "description": "Send email notifications for build results",
          "triggers": ["Build failure", "Build recovery", "Unstable builds"]
        },
        {
          "method": "Slack",
          "description": "Send messages to Slack channels",
          "plugin": "Slack Notification Plugin",
          "configuration": "Webhook URL and channel settings"
        },
        {
          "method": "Microsoft Teams",
          "description": "Notify Microsoft Teams channels",
          "plugin": "Office 365 Connector"
        },
        {
          "method": "Custom Scripts",
          "description": "Execute custom notification scripts",
          "use_cases": ["Database updates", "Custom webhooks", "Integration with other tools"]
        }
      ]
    }
  ],
  "objectives": [
    "Create and configure different types of Jenkins jobs",
    "Implement parameterized builds for flexibility",
    "Manage build artifacts and generate reports",
    "Set up build notifications and alerts"
  ],
  "hands_on_exercises": [
    {
      "title": "Maven Project Build",
      "description": "Create a freestyle job to build a Maven project",
      "requirements": [
        "Configure Git repository",
        "Set up Maven build steps",
        "Archive JAR artifacts",
        "Publish JUnit test results",
        "Send Slack notification on failure"
      ]
    }
  ]
}',
'{"Jenkins Installation and Configuration"}', 70);

-- Quiz 1: Jenkins Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Jenkins Fundamentals Quiz', 'quiz', 'jenkins', 'beginner',
'{
  "questions": [
    {
      "question": "What is the main purpose of Continuous Integration?",
      "options": [
        "Deploy applications to production",
        "Merge code changes frequently with automated verification",
        "Monitor application performance",
        "Manage server infrastructure"
      ],
      "correct": 1,
      "explanation": "Continuous Integration focuses on merging code changes frequently into a shared repository with automated builds and tests to detect issues early."
    },
    {
      "question": "Which file contains the initial admin password for Jenkins?",
      "options": [
        "jenkins.log",
        "admin.password",
        "initialAdminPassword",
        "setup.key"
      ],
      "correct": 2,
      "explanation": "The initialAdminPassword file contains the randomly generated password needed to unlock Jenkins during initial setup."
    },
    {
      "question": "What is the recommended number of executors for Jenkins master?",
      "options": ["1", "2", "4", "0"],
      "correct": 3,
      "explanation": "It is recommended to set master executors to 0 and use dedicated agents for running builds to avoid resource conflicts."
    },
    {
      "question": "Which job type is best for implementing Pipeline as Code?",
      "options": ["Freestyle Project", "Pipeline", "Multi-configuration", "External Job"],
      "correct": 1,
      "explanation": "Pipeline jobs allow you to define your build process as code using Jenkinsfile, enabling version control and better maintainability."
    },
    {
      "question": "What does the BUILD_NUMBER environment variable contain?",
      "options": [
        "Git commit hash",
        "Current build number",
        "Job creation date",
        "Jenkins version"
      ],
      "correct": 1,
      "explanation": "BUILD_NUMBER is an environment variable that contains the current build number, which increments with each build."
    }
  ],
  "passing_score": 80,
  "time_limit": 600
}',
'{"CI/CD Fundamentals with Jenkins", "Jenkins Installation and Configuration"}', 15);

-- Lab 1: Jenkins Setup and First Job
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Jenkins Setup and First Job Lab', 'lab', 'jenkins', 'beginner',
'{
  "description": "Hands-on lab to install Jenkins, complete initial setup, and create your first build job",
  "learning_objectives": [
    "Install and configure Jenkins",
    "Complete initial security setup",
    "Create and run a freestyle job",
    "Configure build notifications"
  ],
  "environment": {
    "type": "jenkins",
    "requirements": ["Docker installed", "Git repository access", "Internet connection"]
  },
  "tasks": [
    {
      "title": "Install Jenkins with Docker",
      "description": "Set up Jenkins using Docker container",
      "instructions": [
        "Pull the official Jenkins LTS image",
        "Run Jenkins container with proper port mapping",
        "Access Jenkins web interface",
        "Note the initial admin password location"
      ],
      "commands": [
        "docker pull jenkins/jenkins:lts",
        "docker run -d -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts",
        "docker logs jenkins | grep -A 5 -B 5 password"
      ],
      "validation": {
        "command": "curl -s http://localhost:8080 | grep Jenkins",
        "expected_output": "Jenkins"
      }
    },
    {
      "title": "Complete Initial Setup",
      "description": "Complete Jenkins initial configuration wizard",
      "instructions": [
        "Navigate to http://localhost:8080",
        "Enter the initial admin password",
        "Install suggested plugins",
        "Create first admin user",
        "Configure Jenkins URL"
      ],
      "validation": {
        "description": "Successfully access Jenkins dashboard with admin user"
      }
    },
    {
      "title": "Configure Global Tools",
      "description": "Set up global tool configurations",
      "instructions": [
        "Go to Manage Jenkins > Global Tool Configuration",
        "Configure Git (usually auto-detected)",
        "Add JDK installation (if needed)",
        "Configure Maven installation",
        "Save configuration"
      ],
      "validation": {
        "description": "Tools appear in Global Tool Configuration"
      }
    },
    {
      "title": "Create First Freestyle Job",
      "description": "Create a simple build job for a Git repository",
      "instructions": [
        "Click New Item and select Freestyle project",
        "Configure Git repository URL",
        "Add build step to execute shell command",
        "Configure post-build actions",
        "Save and run the job"
      ],
      "example_commands": [
        "echo Build started at $(date)",
        "echo Workspace: $WORKSPACE",
        "echo Build number: $BUILD_NUMBER",
        "ls -la"
      ],
      "validation": {
        "description": "Job runs successfully and shows console output"
      }
    },
    {
      "title": "Configure Build Triggers",
      "description": "Set up automatic build triggers",
      "instructions": [
        "Edit the created job",
        "Configure Poll SCM trigger",
        "Set polling schedule (e.g., H/5 * * * *)",
        "Test trigger by making a code change",
        "Verify automatic build execution"
      ],
      "validation": {
        "description": "Build triggers automatically when code changes"
      }
    },
    {
      "title": "Add Build Parameters",
      "description": "Make the job parameterized for flexibility",
      "instructions": [
        "Enable This project is parameterized",
        "Add String parameter BRANCH_NAME with default main",
        "Add Choice parameter ENVIRONMENT with dev, staging, prod",
        "Update build steps to use parameters",
        "Test parameterized build"
      ],
      "validation": {
        "description": "Build with Parameters option appears and works correctly"
      }
    }
  ],
  "completion_criteria": [
    "Jenkins is running and accessible via web interface",
    "Initial setup completed with admin user created",
    "Global tools configured properly",
    "Freestyle job created and runs successfully",
    "Build triggers and parameters working correctly"
  ]
}',
'{"Jenkins Installation and Configuration"}', 90);

-- Assessment: Jenkins CI/CD Skills
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Comprehensive Jenkins Assessment', 'quiz', 'jenkins', 'intermediate',
'{
  "description": "Comprehensive assessment covering Jenkins installation, job configuration, and CI/CD best practices",
  "questions": [
    {
      "question": "You need to set up a CI pipeline that builds on every commit to the main branch. Which trigger should you use?",
      "options": [
        "Build periodically",
        "GitHub hook trigger for GITScm polling",
        "Poll SCM every minute",
        "Trigger builds remotely"
      ],
      "correct": 1,
      "explanation": "GitHub hook trigger provides immediate builds when commits are pushed, making it more efficient than polling."
    },
    {
      "question": "What is the best practice for managing sensitive information like passwords in Jenkins?",
      "options": [
        "Store in build scripts",
        "Use environment variables",
        "Use Jenkins Credentials Plugin",
        "Store in job configuration"
      ],
      "correct": 2,
      "explanation": "Jenkins Credentials Plugin provides secure storage and management of sensitive information with proper access controls."
    },
    {
      "question": "Which approach is recommended for complex CI/CD workflows?",
      "options": [
        "Multiple freestyle jobs",
        "Single complex freestyle job",
        "Pipeline as Code with Jenkinsfile",
        "External scripts only"
      ],
      "correct": 2,
      "explanation": "Pipeline as Code with Jenkinsfile provides version control, better maintainability, and more sophisticated workflow capabilities."
    },
    {
      "question": "How should you handle build artifacts in a CI/CD pipeline?",
      "options": [
        "Leave them in workspace",
        "Archive important artifacts",
        "Delete all artifacts immediately",
        "Store in Git repository"
      ],
      "correct": 1,
      "explanation": "Archiving important artifacts makes them available for deployment and troubleshooting while managing storage efficiently."
    },
    {
      "question": "What is the purpose of the Quiet Period in Jenkins?",
      "options": [
        "Reduce noise in logs",
        "Batch multiple triggers together",
        "Prevent builds during maintenance",
        "Limit concurrent builds"
      ],
      "correct": 1,
      "explanation": "Quiet Period delays build start to batch multiple rapid triggers together, preventing unnecessary duplicate builds."
    },
    {
      "question": "Which plugin is essential for implementing Pipeline as Code?",
      "options": ["Git Plugin", "Pipeline Plugin", "Build Timeout Plugin", "Slack Plugin"],
      "correct": 1,
      "explanation": "Pipeline Plugin provides the core functionality for creating and running pipeline jobs with Jenkinsfile."
    }
  ],
  "passing_score": 75,
  "time_limit": 1200,
  "certification": {
    "name": "Jenkins CI/CD Specialist",
    "description": "Demonstrates comprehensive understanding of Jenkins CI/CD implementation and best practices"
  }
}',
'{"Jenkins Fundamentals Quiz", "Jenkins Setup and First Job Lab", "Jenkins Jobs and Build Management"}', 30);