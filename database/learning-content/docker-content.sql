-- Comprehensive Docker Learning Content
-- This file contains detailed learning modules, quizzes, and lab exercises for Docker containerization

\c devops_practice;

-- Delete existing basic Docker content to replace with comprehensive content
DELETE FROM learning.learning_content WHERE tool_category = 'docker';

-- Module 1: Docker Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Docker Fundamentals: Introduction to Containerization', 'module', 'docker', 'beginner', 
'{
  "sections": [
    {
      "title": "What is Containerization?",
      "content": "Containerization is a lightweight form of virtualization that packages applications and their dependencies into portable containers that can run consistently across different environments.",
      "benefits": [
        "Consistent environments across development, testing, and production",
        "Improved resource utilization compared to virtual machines",
        "Faster deployment and scaling",
        "Better isolation and security",
        "Simplified dependency management"
      ]
    },
    {
      "title": "Introduction to Docker",
      "content": "Docker is a platform that uses OS-level virtualization to deliver software in packages called containers. It provides tools to build, ship, and run applications anywhere.",
      "key_concepts": [
        "Containers vs Virtual Machines",
        "Docker Engine architecture",
        "Images and containers relationship",
        "Docker Hub registry",
        "Dockerfile for building images"
      ]
    },
    {
      "title": "Docker Architecture",
      "content": "Docker uses a client-server architecture with the Docker daemon managing containers and the Docker client providing the command-line interface.",
      "components": [
        {
          "name": "Docker Client",
          "description": "Command-line interface for interacting with Docker"
        },
        {
          "name": "Docker Daemon",
          "description": "Background service that manages containers, images, and networks"
        },
        {
          "name": "Docker Images",
          "description": "Read-only templates used to create containers"
        },
        {
          "name": "Docker Containers",
          "description": "Running instances of Docker images"
        },
        {
          "name": "Docker Registry",
          "description": "Storage and distribution system for Docker images"
        }
      ]
    },
    {
      "title": "Containers vs Virtual Machines",
      "content": "Understanding the differences between containers and VMs is crucial for choosing the right technology.",
      "comparison": {
        "containers": {
          "pros": ["Lightweight", "Fast startup", "Better resource utilization", "Portable"],
          "cons": ["Shared kernel", "Less isolation", "OS dependency"]
        },
        "virtual_machines": {
          "pros": ["Complete isolation", "Different OS support", "Mature ecosystem"],
          "cons": ["Resource overhead", "Slower startup", "Larger size"]
        }
      }
    }
  ],
  "objectives": [
    "Understand containerization concepts and benefits",
    "Learn Docker architecture and components",
    "Compare containers with virtual machines",
    "Identify use cases for Docker containers"
  ],
  "interactive_elements": [
    {
      "type": "knowledge_check",
      "question": "What is the main advantage of containers over virtual machines?",
      "options": ["Better security", "Lighter resource usage", "Different OS support", "More isolation"],
      "correct": 1,
      "explanation": "Containers share the host OS kernel, making them much lighter and faster than VMs which require a full guest OS."
    }
  ]
}', 
'{}', 40);

-- Module 2: Docker Installation and Basic Commands
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Docker Installation and Basic Commands', 'module', 'docker', 'beginner',
'{
  "sections": [
    {
      "title": "Installing Docker",
      "content": "Docker can be installed on various operating systems including Linux, macOS, and Windows.",
      "installation_methods": [
        {
          "platform": "Ubuntu/Debian",
          "commands": [
            "sudo apt-get update",
            "sudo apt-get install docker.io",
            "sudo systemctl start docker",
            "sudo systemctl enable docker"
          ]
        },
        {
          "platform": "CentOS/RHEL",
          "commands": [
            "sudo yum install -y docker",
            "sudo systemctl start docker",
            "sudo systemctl enable docker"
          ]
        },
        {
          "platform": "macOS/Windows",
          "description": "Download Docker Desktop from docker.com"
        }
      ]
    },
    {
      "title": "Essential Docker Commands",
      "content": "Master the fundamental Docker commands for managing images and containers.",
      "command_categories": [
        {
          "category": "Image Management",
          "commands": [
            {
              "command": "docker pull <image>",
              "description": "Download an image from registry"
            },
            {
              "command": "docker images",
              "description": "List all local images"
            },
            {
              "command": "docker rmi <image>",
              "description": "Remove an image"
            },
            {
              "command": "docker build -t <name> .",
              "description": "Build image from Dockerfile"
            }
          ]
        },
        {
          "category": "Container Management",
          "commands": [
            {
              "command": "docker run <image>",
              "description": "Create and start a container"
            },
            {
              "command": "docker ps",
              "description": "List running containers"
            },
            {
              "command": "docker ps -a",
              "description": "List all containers"
            },
            {
              "command": "docker stop <container>",
              "description": "Stop a running container"
            },
            {
              "command": "docker rm <container>",
              "description": "Remove a container"
            }
          ]
        }
      ]
    },
    {
      "title": "Working with Docker Images",
      "content": "Docker images are the foundation of containers. Learn how to find, pull, and manage images.",
      "code_examples": [
        {
          "title": "Pulling and Running Images",
          "code": "# Pull an image from Docker Hub\ndocker pull nginx:latest\n\n# Run a container from the image\ndocker run -d -p 8080:80 --name my-nginx nginx:latest\n\n# Check running containers\ndocker ps\n\n# View container logs\ndocker logs my-nginx"
        }
      ]
    },
    {
      "title": "Container Lifecycle Management",
      "content": "Understanding how to manage the complete lifecycle of containers from creation to removal.",
      "lifecycle_stages": [
        "Create: docker create",
        "Start: docker start", 
        "Run: docker run (create + start)",
        "Pause: docker pause",
        "Stop: docker stop",
        "Remove: docker rm"
      ],
      "code_examples": [
        {
          "title": "Container Lifecycle Example",
          "code": "# Create a container without starting it\ndocker create --name my-app nginx:latest\n\n# Start the created container\ndocker start my-app\n\n# Execute commands in running container\ndocker exec -it my-app bash\n\n# Stop the container\ndocker stop my-app\n\n# Remove the container\ndocker rm my-app"
        }
      ]
    }
  ],
  "objectives": [
    "Install Docker on different operating systems",
    "Execute essential Docker commands",
    "Manage Docker images and containers",
    "Understand container lifecycle management"
  ],
  "hands_on_exercises": [
    {
      "title": "First Container",
      "description": "Pull and run your first Docker container",
      "steps": [
        "Pull the hello-world image",
        "Run the hello-world container",
        "List running and stopped containers",
        "Remove the container"
      ]
    }
  ]
}',
'{"Docker Fundamentals: Introduction to Containerization"}', 45);

-- Module 3: Dockerfile and Image Building
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Dockerfile and Image Building', 'module', 'docker', 'intermediate',
'{
  "sections": [
    {
      "title": "Introduction to Dockerfile",
      "content": "A Dockerfile is a text file containing instructions to build a Docker image. It defines the environment, dependencies, and configuration for your application.",
      "dockerfile_structure": [
        "Base image specification (FROM)",
        "Metadata and labels (LABEL)",
        "Environment setup (ENV, ARG)",
        "File operations (COPY, ADD)",
        "Command execution (RUN)",
        "Container configuration (EXPOSE, VOLUME)",
        "Startup command (CMD, ENTRYPOINT)"
      ]
    },
    {
      "title": "Dockerfile Instructions",
      "content": "Learn the most important Dockerfile instructions and their proper usage.",
      "instructions": [
        {
          "instruction": "FROM",
          "description": "Specifies the base image",
          "example": "FROM node:18-alpine"
        },
        {
          "instruction": "WORKDIR",
          "description": "Sets the working directory",
          "example": "WORKDIR /app"
        },
        {
          "instruction": "COPY",
          "description": "Copies files from host to container",
          "example": "COPY package*.json ./"
        },
        {
          "instruction": "RUN",
          "description": "Executes commands during build",
          "example": "RUN npm install"
        },
        {
          "instruction": "EXPOSE",
          "description": "Documents which ports the container listens on",
          "example": "EXPOSE 3000"
        },
        {
          "instruction": "CMD",
          "description": "Default command to run when container starts",
          "example": "CMD [\"npm\", \"start\"]"
        }
      ]
    },
    {
      "title": "Building Docker Images",
      "content": "Learn how to build efficient and secure Docker images using best practices.",
      "build_process": [
        "Docker reads the Dockerfile",
        "Each instruction creates a new layer",
        "Layers are cached for faster builds",
        "Final image is tagged and stored"
      ],
      "code_examples": [
        {
          "title": "Node.js Application Dockerfile",
          "code": "# Use official Node.js runtime as base image\nFROM node:18-alpine\n\n# Set working directory in container\nWORKDIR /app\n\n# Copy package files\nCOPY package*.json ./\n\n# Install dependencies\nRUN npm ci --only=production\n\n# Copy application code\nCOPY . .\n\n# Create non-root user\nRUN addgroup -g 1001 -S nodejs\nRUN adduser -S nextjs -u 1001\n\n# Change ownership of app directory\nRUN chown -R nextjs:nodejs /app\nUSER nextjs\n\n# Expose port\nEXPOSE 3000\n\n# Define startup command\nCMD [\"npm\", \"start\"]"
        }
      ]
    },
    {
      "title": "Multi-stage Builds",
      "content": "Multi-stage builds allow you to create smaller, more secure images by separating build and runtime environments.",
      "benefits": [
        "Smaller final image size",
        "Improved security (no build tools in production)",
        "Better separation of concerns",
        "Reduced attack surface"
      ],
      "code_examples": [
        {
          "title": "Multi-stage Build Example",
          "code": "# Build stage\nFROM node:18-alpine AS builder\nWORKDIR /app\nCOPY package*.json ./\nRUN npm ci\nCOPY . .\nRUN npm run build\n\n# Production stage\nFROM node:18-alpine AS production\nWORKDIR /app\nCOPY package*.json ./\nRUN npm ci --only=production\nCOPY --from=builder /app/dist ./dist\nEXPOSE 3000\nCMD [\"npm\", \"start\"]"
        }
      ]
    },
    {
      "title": "Image Optimization Best Practices",
      "content": "Techniques to create smaller, faster, and more secure Docker images.",
      "best_practices": [
        {
          "practice": "Use Alpine Linux base images",
          "description": "Alpine images are much smaller than standard Linux distributions"
        },
        {
          "practice": "Minimize layers",
          "description": "Combine RUN commands to reduce the number of layers"
        },
        {
          "practice": "Use .dockerignore",
          "description": "Exclude unnecessary files from the build context"
        },
        {
          "practice": "Run as non-root user",
          "description": "Improve security by avoiding root privileges"
        },
        {
          "practice": "Order instructions by change frequency",
          "description": "Put frequently changing instructions at the end"
        }
      ]
    }
  ],
  "objectives": [
    "Write effective Dockerfiles for different applications",
    "Build Docker images using best practices",
    "Implement multi-stage builds for optimization",
    "Apply security and performance optimizations"
  ],
  "hands_on_exercises": [
    {
      "title": "Build a Web Application Image",
      "description": "Create a Dockerfile for a simple web application",
      "requirements": [
        "Use appropriate base image",
        "Copy application files",
        "Install dependencies",
        "Configure proper startup command",
        "Implement security best practices"
      ]
    }
  ]
}',
'{"Docker Installation and Basic Commands"}', 55);

-- Quiz 1: Docker Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Docker Fundamentals Quiz', 'quiz', 'docker', 'beginner',
'{
  "questions": [
    {
      "question": "What is the main difference between containers and virtual machines?",
      "options": [
        "Containers are slower to start",
        "Containers share the host OS kernel",
        "Containers require more resources",
        "Containers provide better isolation"
      ],
      "correct": 1,
      "explanation": "Containers share the host operating system kernel, making them lightweight and fast to start compared to VMs which require a full guest OS."
    },
    {
      "question": "Which command is used to download a Docker image from a registry?",
      "options": ["docker get", "docker pull", "docker download", "docker fetch"],
      "correct": 1,
      "explanation": "The docker pull command downloads an image from a Docker registry like Docker Hub."
    },
    {
      "question": "What does the docker ps command show?",
      "options": [
        "All Docker images",
        "Running containers only",
        "All containers",
        "Docker processes"
      ],
      "correct": 1,
      "explanation": "docker ps shows only running containers. Use docker ps -a to see all containers including stopped ones."
    },
    {
      "question": "Which Dockerfile instruction sets the base image?",
      "options": ["BASE", "FROM", "IMAGE", "PARENT"],
      "correct": 1,
      "explanation": "The FROM instruction specifies the base image that your Docker image will be built upon."
    },
    {
      "question": "What is the purpose of the EXPOSE instruction in a Dockerfile?",
      "options": [
        "Opens ports on the host",
        "Documents which ports the container uses",
        "Automatically publishes ports",
        "Blocks network access"
      ],
      "correct": 1,
      "explanation": "EXPOSE documents which ports the container listens on but does not actually publish them. You need -p flag with docker run to publish ports."
    }
  ],
  "passing_score": 80,
  "time_limit": 600
}',
'{"Docker Fundamentals: Introduction to Containerization", "Docker Installation and Basic Commands"}', 15);

-- Lab 1: Docker Basics Lab
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Docker Basics Hands-on Lab', 'lab', 'docker', 'beginner',
'{
  "description": "Get hands-on experience with Docker basics including running containers, managing images, and basic networking",
  "learning_objectives": [
    "Run your first Docker containers",
    "Manage Docker images and containers",
    "Understand port mapping and networking",
    "Practice essential Docker commands"
  ],
  "environment": {
    "type": "docker",
    "requirements": ["Docker installed", "Internet connection for pulling images"]
  },
  "tasks": [
    {
      "title": "Pull and Run Hello World",
      "description": "Start with the classic hello-world container",
      "instructions": [
        "Pull the hello-world image from Docker Hub",
        "Run the hello-world container",
        "Observe the output and understand what happened"
      ],
      "commands": [
        "docker pull hello-world",
        "docker run hello-world"
      ],
      "validation": {
        "command": "docker images | grep hello-world",
        "expected_output": "hello-world"
      }
    },
    {
      "title": "Run a Web Server Container",
      "description": "Run an nginx web server container with port mapping",
      "instructions": [
        "Pull the nginx image",
        "Run nginx container with port mapping",
        "Access the web server from your browser",
        "Check container logs"
      ],
      "commands": [
        "docker pull nginx:latest",
        "docker run -d -p 8080:80 --name my-nginx nginx:latest",
        "docker logs my-nginx"
      ],
      "validation": {
        "command": "curl -s http://localhost:8080 | grep nginx",
        "expected_output": "nginx"
      }
    },
    {
      "title": "Interactive Container Session",
      "description": "Run an interactive Ubuntu container and explore the filesystem",
      "instructions": [
        "Run an Ubuntu container interactively",
        "Explore the container filesystem",
        "Install a package inside the container",
        "Exit and observe container state"
      ],
      "commands": [
        "docker run -it ubuntu:latest bash",
        "# Inside container: ls -la",
        "# Inside container: apt update && apt install -y curl",
        "# Inside container: exit"
      ],
      "validation": {
        "command": "docker ps -a | grep ubuntu",
        "expected_output": "ubuntu"
      }
    },
    {
      "title": "Container Management",
      "description": "Practice starting, stopping, and removing containers",
      "instructions": [
        "List all containers (running and stopped)",
        "Start a stopped container",
        "Stop a running container",
        "Remove containers and images"
      ],
      "commands": [
        "docker ps -a",
        "docker start my-nginx",
        "docker stop my-nginx",
        "docker rm my-nginx",
        "docker rmi nginx:latest"
      ],
      "validation": {
        "command": "docker ps -a",
        "expected_result": "No nginx containers should be running"
      }
    }
  ],
  "completion_criteria": [
    "Successfully pulled and ran hello-world container",
    "Ran nginx web server with port mapping",
    "Executed interactive session in Ubuntu container",
    "Demonstrated container lifecycle management"
  ]
}',
'{"Docker Installation and Basic Commands"}', 60);

-- Assessment: Comprehensive Docker Skills
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Comprehensive Docker Assessment', 'quiz', 'docker', 'intermediate',
'{
  "description": "Comprehensive assessment covering Docker fundamentals, image building, and container management",
  "questions": [
    {
      "question": "You need to build a Docker image for a Node.js application. What is the most efficient approach?",
      "options": [
        "Use ubuntu:latest as base image",
        "Use node:alpine as base image",
        "Build from scratch",
        "Use centos:latest as base image"
      ],
      "correct": 1,
      "explanation": "node:alpine provides Node.js runtime in a minimal Alpine Linux base, resulting in smaller image size and faster builds."
    },
    {
      "question": "What is the benefit of multi-stage builds in Docker?",
      "options": [
        "Faster container startup",
        "Better networking",
        "Smaller final image size",
        "More security vulnerabilities"
      ],
      "correct": 2,
      "explanation": "Multi-stage builds allow you to separate build and runtime environments, resulting in smaller final images without build tools."
    },
    {
      "question": "Which instruction should you use to copy files from your host to a Docker image during build?",
      "options": ["ADD", "COPY", "MOVE", "TRANSFER"],
      "correct": 1,
      "explanation": "COPY is preferred over ADD for simple file copying as it is more predictable and secure."
    },
    {
      "question": "How do you run a container in detached mode with port mapping?",
      "options": [
        "docker run -p 8080:80 nginx",
        "docker run -d -p 8080:80 nginx", 
        "docker run --detach --port 8080:80 nginx",
        "docker run -background -p 8080:80 nginx"
      ],
      "correct": 1,
      "explanation": "The -d flag runs the container in detached mode, and -p maps host port 8080 to container port 80."
    },
    {
      "question": "What is the purpose of .dockerignore file?",
      "options": [
        "Ignore Docker commands",
        "Exclude files from build context",
        "Hide containers from listing",
        "Prevent image pulls"
      ],
      "correct": 1,
      "explanation": ".dockerignore excludes files and directories from the build context, reducing build time and image size."
    },
    {
      "question": "Which approach is recommended for running applications in containers?",
      "options": [
        "Always run as root user",
        "Create and use non-root user",
        "Use system administrator account",
        "Run with sudo privileges"
      ],
      "correct": 1,
      "explanation": "Running as non-root user improves security by following the principle of least privilege."
    }
  ],
  "passing_score": 80,
  "time_limit": 1200,
  "certification": {
    "name": "Docker Containerization Specialist",
    "description": "Demonstrates comprehensive understanding of Docker containerization concepts and practical skills"
  }
}',
'{"Docker Fundamentals Quiz", "Docker Basics Hands-on Lab", "Dockerfile and Image Building"}', 25);