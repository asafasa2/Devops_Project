-- Comprehensive CKA (Certified Kubernetes Administrator) Learning Content
-- This file contains detailed learning modules, quizzes, and lab exercises for Kubernetes administration

\c devops_practice;

-- Insert CKA/Kubernetes learning content
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Kubernetes Fundamentals for CKA', 'module', 'kubernetes', 'beginner', 
'{
  "sections": [
    {
      "title": "What is Kubernetes?",
      "content": "Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications across clusters of hosts.",
      "key_concepts": [
        "Container orchestration",
        "Declarative configuration",
        "Self-healing systems",
        "Horizontal scaling",
        "Service discovery and load balancing",
        "Rolling updates and rollbacks"
      ]
    },
    {
      "title": "Kubernetes Architecture",
      "content": "Kubernetes follows a master-worker architecture with control plane components managing the cluster and worker nodes running application workloads.",
      "control_plane_components": [
        {
          "name": "kube-apiserver",
          "description": "API server that exposes the Kubernetes API"
        },
        {
          "name": "etcd",
          "description": "Distributed key-value store for cluster data"
        },
        {
          "name": "kube-scheduler",
          "description": "Schedules pods to nodes based on resource requirements"
        },
        {
          "name": "kube-controller-manager",
          "description": "Runs controller processes that regulate cluster state"
        },
        {
          "name": "cloud-controller-manager",
          "description": "Integrates with cloud provider APIs"
        }
      ],
      "node_components": [
        {
          "name": "kubelet",
          "description": "Agent that runs on each node and manages containers"
        },
        {
          "name": "kube-proxy",
          "description": "Network proxy that maintains network rules"
        },
        {
          "name": "Container Runtime",
          "description": "Software responsible for running containers (Docker, containerd, CRI-O)"
        }
      ]
    },
    {
      "title": "Core Kubernetes Objects",
      "content": "Understanding the fundamental objects that make up Kubernetes applications.",
      "objects": [
        {
          "name": "Pod",
          "description": "Smallest deployable unit containing one or more containers"
        },
        {
          "name": "Service",
          "description": "Stable network endpoint for accessing pods"
        },
        {
          "name": "Deployment",
          "description": "Manages replica sets and provides declarative updates"
        },
        {
          "name": "ConfigMap",
          "description": "Stores configuration data as key-value pairs"
        },
        {
          "name": "Secret",
          "description": "Stores sensitive information like passwords and tokens"
        },
        {
          "name": "Namespace",
          "description": "Virtual clusters for organizing resources"
        }
      ]
    },
    {
      "title": "kubectl Command Line Tool",
      "content": "kubectl is the primary tool for interacting with Kubernetes clusters.",
      "essential_commands": [
        {
          "command": "kubectl get",
          "description": "List resources",
          "example": "kubectl get pods"
        },
        {
          "command": "kubectl describe",
          "description": "Show detailed information about resources",
          "example": "kubectl describe pod my-pod"
        },
        {
          "command": "kubectl create",
          "description": "Create resources from files or command line",
          "example": "kubectl create -f deployment.yaml"
        },
        {
          "command": "kubectl apply",
          "description": "Apply configuration changes",
          "example": "kubectl apply -f service.yaml"
        },
        {
          "command": "kubectl delete",
          "description": "Delete resources",
          "example": "kubectl delete pod my-pod"
        }
      ]
    }
  ],
  "objectives": [
    "Understand Kubernetes architecture and components",
    "Learn core Kubernetes objects and their purposes",
    "Master essential kubectl commands",
    "Prepare for CKA certification exam"
  ],
  "cka_exam_info": {
    "exam_duration": "2 hours",
    "passing_score": "66%",
    "format": "Performance-based tasks",
    "environment": "Command line only",
    "allowed_resources": ["kubernetes.io documentation"]
  }
}', 
'{}', 60);

-- Module 2: Cluster Installation and Configuration
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('CKA: Cluster Installation and Configuration', 'module', 'kubernetes', 'intermediate',
'{
  "sections": [
    {
      "title": "Cluster Installation Methods",
      "content": "Learn different approaches to installing Kubernetes clusters for various environments.",
      "installation_methods": [
        {
          "method": "kubeadm",
          "description": "Official tool for bootstrapping Kubernetes clusters",
          "use_case": "Production clusters, learning, CKA exam"
        },
        {
          "method": "kops",
          "description": "Kubernetes Operations tool for AWS",
          "use_case": "AWS production clusters"
        },
        {
          "method": "kubespray",
          "description": "Ansible-based cluster deployment",
          "use_case": "On-premises and cloud deployments"
        },
        {
          "method": "Managed Services",
          "description": "EKS, GKE, AKS",
          "use_case": "Cloud-native applications"
        }
      ]
    },
    {
      "title": "Installing with kubeadm",
      "content": "Step-by-step process for installing Kubernetes using kubeadm, the method used in CKA exam.",
      "prerequisites": [
        "Ubuntu 20.04+ or CentOS 7+",
        "2 GB RAM minimum",
        "2 CPUs minimum",
        "Network connectivity between nodes",
        "Unique hostname and MAC address"
      ],
      "installation_steps": [
        {
          "step": "Prepare the system",
          "commands": [
            "sudo swapoff -a",
            "sudo sed -i '/ swap / s/^/#/' /etc/fstab"
          ]
        },
        {
          "step": "Install container runtime",
          "commands": [
            "sudo apt-get update",
            "sudo apt-get install -y containerd",
            "sudo systemctl enable containerd"
          ]
        },
        {
          "step": "Install kubeadm, kubelet, kubectl",
          "commands": [
            "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
            "echo \"deb https://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee /etc/apt/sources.list.d/kubernetes.list",
            "sudo apt-get update",
            "sudo apt-get install -y kubelet kubeadm kubectl",
            "sudo apt-mark hold kubelet kubeadm kubectl"
          ]
        },
        {
          "step": "Initialize the cluster",
          "commands": [
            "sudo kubeadm init --pod-network-cidr=10.244.0.0/16",
            "mkdir -p $HOME/.kube",
            "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
            "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
          ]
        }
      ]
    },
    {
      "title": "Network Configuration",
      "content": "Configure cluster networking with CNI plugins for pod-to-pod communication.",
      "cni_plugins": [
        {
          "name": "Flannel",
          "description": "Simple overlay network",
          "install_command": "kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"
        },
        {
          "name": "Calico",
          "description": "Network policy and security",
          "install_command": "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
        },
        {
          "name": "Weave Net",
          "description": "Easy to use overlay network",
          "install_command": "kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\\n')\""
        }
      ]
    },
    {
      "title": "Adding Worker Nodes",
      "content": "Join worker nodes to the cluster and verify cluster health.",
      "join_process": [
        "Prepare worker node with same prerequisites",
        "Run kubeadm join command from master init output",
        "Verify node joined successfully with kubectl get nodes"
      ],
      "troubleshooting": [
        "Check kubelet logs: journalctl -xeu kubelet",
        "Verify network connectivity between nodes",
        "Ensure container runtime is running",
        "Check firewall rules and required ports"
      ]
    },
    {
      "title": "Cluster Validation",
      "content": "Verify that the cluster is properly configured and all components are healthy.",
      "validation_commands": [
        {
          "command": "kubectl get nodes",
          "purpose": "Check node status"
        },
        {
          "command": "kubectl get pods -n kube-system",
          "purpose": "Verify system pods are running"
        },
        {
          "command": "kubectl cluster-info",
          "purpose": "Display cluster information"
        },
        {
          "command": "kubectl get componentstatuses",
          "purpose": "Check control plane component health"
        }
      ]
    }
  ],
  "objectives": [
    "Install Kubernetes cluster using kubeadm",
    "Configure cluster networking with CNI plugins",
    "Add worker nodes to the cluster",
    "Validate cluster installation and health"
  ],
  "cka_exam_weight": "25%"
}',
'{"Kubernetes Fundamentals for CKA"}', 75);

-- Module 3: Workloads and Scheduling
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('CKA: Workloads and Scheduling', 'module', 'kubernetes', 'intermediate',
'{
  "sections": [
    {
      "title": "Understanding Pods",
      "content": "Pods are the smallest deployable units in Kubernetes, containing one or more containers that share storage and network.",
      "pod_characteristics": [
        "Shared network namespace (IP address)",
        "Shared storage volumes",
        "Containers in pod can communicate via localhost",
        "Pods are ephemeral and replaceable",
        "Each pod gets unique IP address"
      ],
      "yaml_example": {
        "title": "Basic Pod Definition",
        "code": "apiVersion: v1\nkind: Pod\nmetadata:\n  name: nginx-pod\n  labels:\n    app: nginx\nspec:\n  containers:\n  - name: nginx\n    image: nginx:1.20\n    ports:\n    - containerPort: 80\n    resources:\n      requests:\n        memory: \"64Mi\"\n        cpu: \"250m\"\n      limits:\n        memory: \"128Mi\"\n        cpu: \"500m\""
      }
    },
    {
      "title": "Deployments and ReplicaSets",
      "content": "Deployments provide declarative updates for pods and ReplicaSets, managing application lifecycle and scaling.",
      "deployment_features": [
        "Declarative updates and rollbacks",
        "Scaling up and down",
        "Rolling updates with zero downtime",
        "Revision history and rollback capability",
        "Pause and resume deployments"
      ],
      "yaml_example": {
        "title": "Deployment Configuration",
        "code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: nginx-deployment\nspec:\n  replicas: 3\n  selector:\n    matchLabels:\n      app: nginx\n  template:\n    metadata:\n      labels:\n        app: nginx\n    spec:\n      containers:\n      - name: nginx\n        image: nginx:1.20\n        ports:\n        - containerPort: 80"
      }
    },
    {
      "title": "DaemonSets and StatefulSets",
      "content": "Specialized workload controllers for specific use cases.",
      "daemonset": {
        "description": "Ensures a copy of pod runs on all (or some) nodes",
        "use_cases": ["Log collection", "Monitoring agents", "Network plugins"],
        "example": "apiVersion: apps/v1\nkind: DaemonSet\nmetadata:\n  name: fluentd-daemonset\nspec:\n  selector:\n    matchLabels:\n      name: fluentd\n  template:\n    metadata:\n      labels:\n        name: fluentd\n    spec:\n      containers:\n      - name: fluentd\n        image: fluentd:latest"
      },
      "statefulset": {
        "description": "Manages stateful applications with stable network identities",
        "use_cases": ["Databases", "Distributed systems", "Applications requiring persistent storage"],
        "features": ["Stable network identities", "Ordered deployment and scaling", "Persistent storage"]
      }
    },
    {
      "title": "Jobs and CronJobs",
      "content": "Run batch workloads and scheduled tasks in Kubernetes.",
      "job_types": [
        {
          "type": "Job",
          "description": "Run pods to completion for batch processing",
          "example": "apiVersion: batch/v1\nkind: Job\nmetadata:\n  name: pi-calculation\nspec:\n  template:\n    spec:\n      containers:\n      - name: pi\n        image: perl\n        command: [\"perl\", \"-Mbignum=bpi\", \"-wle\", \"print bpi(2000)\"]\n      restartPolicy: Never\n  backoffLimit: 4"
        },
        {
          "type": "CronJob",
          "description": "Run jobs on a schedule using cron syntax",
          "example": "apiVersion: batch/v1\nkind: CronJob\nmetadata:\n  name: backup-job\nspec:\n  schedule: \"0 2 * * *\"\n  jobTemplate:\n    spec:\n      template:\n        spec:\n          containers:\n          - name: backup\n            image: backup-tool:latest\n            command: [\"/bin/sh\", \"-c\", \"backup-script.sh\"]\n          restartPolicy: OnFailure"
        }
      ]
    },
    {
      "title": "Pod Scheduling",
      "content": "Control where pods are scheduled using various scheduling mechanisms.",
      "scheduling_methods": [
        {
          "method": "Node Selector",
          "description": "Simple node selection using labels",
          "example": "spec:\n  nodeSelector:\n    disktype: ssd"
        },
        {
          "method": "Node Affinity",
          "description": "More expressive node selection rules",
          "example": "spec:\n  affinity:\n    nodeAffinity:\n      requiredDuringSchedulingIgnoredDuringExecution:\n        nodeSelectorTerms:\n        - matchExpressions:\n          - key: kubernetes.io/arch\n            operator: In\n            values:\n            - amd64"
        },
        {
          "method": "Taints and Tolerations",
          "description": "Prevent pods from being scheduled on certain nodes",
          "taint_example": "kubectl taint nodes node1 key1=value1:NoSchedule",
          "toleration_example": "spec:\n  tolerations:\n  - key: \"key1\"\n    operator: \"Equal\"\n    value: \"value1\"\n    effect: \"NoSchedule\""
        }
      ]
    }
  ],
  "objectives": [
    "Create and manage pods, deployments, and other workloads",
    "Understand different workload controllers and their use cases",
    "Implement pod scheduling strategies",
    "Configure resource requests and limits"
  ],
  "cka_exam_weight": "15%"
}',
'{"CKA: Cluster Installation and Configuration"}', 80);

-- Quiz 1: Kubernetes Fundamentals
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('CKA Fundamentals Quiz', 'quiz', 'kubernetes', 'beginner',
'{
  "questions": [
    {
      "question": "Which component stores all cluster data in Kubernetes?",
      "options": ["kube-apiserver", "etcd", "kube-scheduler", "kubelet"],
      "correct": 1,
      "explanation": "etcd is the distributed key-value store that stores all cluster data including configuration, state, and metadata."
    },
    {
      "question": "What is the smallest deployable unit in Kubernetes?",
      "options": ["Container", "Pod", "Service", "Deployment"],
      "correct": 1,
      "explanation": "A Pod is the smallest deployable unit in Kubernetes and can contain one or more containers."
    },
    {
      "question": "Which kubectl command shows detailed information about a resource?",
      "options": ["kubectl get", "kubectl describe", "kubectl explain", "kubectl show"],
      "correct": 1,
      "explanation": "kubectl describe provides detailed information about a specific resource including events and status."
    },
    {
      "question": "What is the primary purpose of a Service in Kubernetes?",
      "options": [
        "Store configuration data",
        "Provide stable network endpoint for pods",
        "Manage container images",
        "Schedule pods to nodes"
      ],
      "correct": 1,
      "explanation": "Services provide stable network endpoints and load balancing for accessing pods, which have ephemeral IP addresses."
    },
    {
      "question": "Which tool is commonly used for bootstrapping Kubernetes clusters?",
      "options": ["kubectl", "kubeadm", "kubelet", "kube-proxy"],
      "correct": 1,
      "explanation": "kubeadm is the official tool for bootstrapping Kubernetes clusters and is used in the CKA exam."
    }
  ],
  "passing_score": 80,
  "time_limit": 900
}',
'{"Kubernetes Fundamentals for CKA"}', 20);

-- Lab 1: CKA Cluster Setup Lab
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('CKA Cluster Setup Lab', 'lab', 'kubernetes', 'intermediate',
'{
  "description": "Hands-on lab for setting up a Kubernetes cluster using kubeadm, similar to CKA exam environment",
  "learning_objectives": [
    "Install Kubernetes cluster using kubeadm",
    "Configure cluster networking",
    "Join worker nodes to the cluster",
    "Validate cluster functionality"
  ],
  "environment": {
    "type": "kubernetes",
    "nodes": [
      {"name": "master", "role": "control-plane", "specs": "2 CPU, 4GB RAM"},
      {"name": "worker1", "role": "worker", "specs": "2 CPU, 2GB RAM"},
      {"name": "worker2", "role": "worker", "specs": "2 CPU, 2GB RAM"}
    ]
  },
  "tasks": [
    {
      "title": "Prepare All Nodes",
      "description": "Configure prerequisites on all nodes",
      "instructions": [
        "Disable swap on all nodes",
        "Install container runtime (containerd)",
        "Install kubeadm, kubelet, and kubectl",
        "Configure system settings"
      ],
      "commands": [
        "sudo swapoff -a",
        "sudo sed -i '/ swap / s/^/#/' /etc/fstab",
        "sudo apt-get update && sudo apt-get install -y containerd",
        "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
        "echo \"deb https://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee /etc/apt/sources.list.d/kubernetes.list",
        "sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl"
      ]
    },
    {
      "title": "Initialize Control Plane",
      "description": "Initialize the Kubernetes control plane on master node",
      "instructions": [
        "Run kubeadm init with appropriate parameters",
        "Configure kubectl for regular user",
        "Save the join command for worker nodes"
      ],
      "commands": [
        "sudo kubeadm init --pod-network-cidr=10.244.0.0/16",
        "mkdir -p $HOME/.kube",
        "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
        "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
      ],
      "validation": {
        "command": "kubectl get nodes",
        "expected_output": "master node in NotReady state"
      }
    },
    {
      "title": "Install Network Plugin",
      "description": "Install Flannel CNI plugin for pod networking",
      "instructions": [
        "Apply Flannel network plugin manifest",
        "Wait for all system pods to be running",
        "Verify master node becomes Ready"
      ],
      "commands": [
        "kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml",
        "kubectl get pods -n kube-system",
        "kubectl get nodes"
      ],
      "validation": {
        "command": "kubectl get nodes",
        "expected_output": "master node in Ready state"
      }
    },
    {
      "title": "Join Worker Nodes",
      "description": "Add worker nodes to the cluster",
      "instructions": [
        "Run the kubeadm join command on each worker node",
        "Verify nodes appear in cluster",
        "Check that all nodes are in Ready state"
      ],
      "validation": {
        "command": "kubectl get nodes",
        "expected_output": "All nodes in Ready state"
      }
    },
    {
      "title": "Deploy Test Application",
      "description": "Deploy a test application to verify cluster functionality",
      "instructions": [
        "Create a deployment with nginx",
        "Expose the deployment as a service",
        "Verify pods are running on worker nodes",
        "Test service connectivity"
      ],
      "commands": [
        "kubectl create deployment nginx --image=nginx",
        "kubectl scale deployment nginx --replicas=3",
        "kubectl expose deployment nginx --port=80 --type=NodePort",
        "kubectl get pods -o wide",
        "kubectl get services"
      ],
      "validation": {
        "command": "kubectl get pods",
        "expected_output": "3 nginx pods running"
      }
    }
  ],
  "completion_criteria": [
    "Kubernetes cluster with 1 master and 2 worker nodes",
    "All nodes in Ready state",
    "All system pods running in kube-system namespace",
    "Test application deployed and accessible"
  ]
}',
'{"CKA: Cluster Installation and Configuration"}', 120);

-- Assessment: CKA Practice Exam
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('CKA Practice Assessment', 'quiz', 'kubernetes', 'advanced',
'{
  "description": "Practice assessment simulating CKA exam format with performance-based tasks",
  "exam_format": "Performance-based tasks in live Kubernetes environment",
  "questions": [
    {
      "question": "Create a pod named web-pod using nginx:1.20 image. The pod should have a label app=web and should be scheduled only on nodes with label disktype=ssd.",
      "type": "practical",
      "points": 4,
      "solution_approach": [
        "Create pod YAML with nodeSelector",
        "Apply the configuration",
        "Verify pod is scheduled correctly"
      ],
      "validation": "kubectl get pod web-pod -o wide"
    },
    {
      "question": "Create a deployment named api-deployment with 3 replicas using nginx:alpine image. Configure resource requests of 100m CPU and 128Mi memory for each container.",
      "type": "practical", 
      "points": 6,
      "solution_approach": [
        "Create deployment YAML with resource requests",
        "Set replica count to 3",
        "Apply and verify deployment"
      ],
      "validation": "kubectl get deployment api-deployment"
    },
    {
      "question": "A pod named broken-pod is not starting. Troubleshoot and fix the issue. The pod should run busybox image and execute sleep 3600 command.",
      "type": "troubleshooting",
      "points": 8,
      "common_issues": [
        "Image pull errors",
        "Resource constraints", 
        "Configuration syntax errors",
        "Node scheduling issues"
      ],
      "validation": "kubectl get pod broken-pod"
    },
    {
      "question": "Create a service named web-service that exposes the web-pod created earlier on port 80. The service should be accessible from outside the cluster.",
      "type": "practical",
      "points": 5,
      "solution_approach": [
        "Create service YAML with NodePort type",
        "Configure proper selector and ports",
        "Apply and test connectivity"
      ],
      "validation": "kubectl get service web-service"
    },
    {
      "question": "Scale the api-deployment to 5 replicas and perform a rolling update to nginx:1.21 image. Monitor the rollout status.",
      "type": "practical",
      "points": 7,
      "solution_approach": [
        "Scale deployment using kubectl scale",
        "Update image using kubectl set image",
        "Monitor rollout with kubectl rollout status"
      ],
      "validation": "kubectl get deployment api-deployment"
    }
  ],
  "time_limit": 7200,
  "passing_score": 66,
  "exam_tips": [
    "Use kubectl documentation (kubernetes.io/docs)",
    "Practice imperative commands for speed",
    "Always verify your solutions",
    "Manage time effectively across all tasks",
    "Use kubectl explain for resource specifications"
  ],
  "certification": {
    "name": "CKA Practice Certification",
    "description": "Demonstrates readiness for the Certified Kubernetes Administrator exam"
  }
}',
'{"CKA Fundamentals Quiz", "CKA Cluster Setup Lab", "CKA: Workloads and Scheduling"}', 120);