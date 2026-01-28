const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const Docker = require('dockerode');
const pty = require('node-pty');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs').promises;
const yaml = require('yaml');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 4005;
const docker = new Docker();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Store active sessions
const activeSessions = new Map();
const activeContainers = new Map();

// CKA Scenario definitions
const CKA_SCENARIOS = {
  'cluster-setup': {
    title: 'Cluster Setup and Management',
    description: 'Initialize a Kubernetes cluster using kubeadm',
    timeLimit: 30,
    tasks: [
      'Initialize a Kubernetes cluster on the master node',
      'Join worker nodes to the cluster',
      'Install a CNI plugin (Calico)',
      'Verify all nodes are Ready'
    ],
    validation: {
      commands: [
        'kubectl get nodes',
        'kubectl get pods -n kube-system'
      ],
      expectedOutputs: [
        'Ready',
        'calico'
      ]
    }
  },
  'pod-management': {
    title: 'Pod Creation and Management',
    description: 'Create and manage pods with various configurations',
    timeLimit: 20,
    tasks: [
      'Create a pod named "web-server" using nginx image',
      'Add resource limits (CPU: 100m, Memory: 128Mi)',
      'Add environment variable APP_ENV=production',
      'Verify the pod is running'
    ],
    validation: {
      commands: ['kubectl get pod web-server -o yaml'],
      expectedOutputs: ['nginx', 'APP_ENV', 'production']
    }
  },
  'service-networking': {
    title: 'Service and Networking',
    description: 'Create services and configure networking',
    timeLimit: 25,
    tasks: [
      'Create a deployment with 3 replicas of nginx',
      'Expose the deployment using a ClusterIP service',
      'Create an Ingress resource for external access',
      'Test connectivity between pods'
    ]
  },
  'storage-management': {
    title: 'Storage and Persistent Volumes',
    description: 'Configure storage solutions',
    timeLimit: 30,
    tasks: [
      'Create a PersistentVolume with 1Gi capacity',
      'Create a PersistentVolumeClaim',
      'Mount the PVC in a pod',
      'Verify data persistence'
    ]
  },
  'troubleshooting': {
    title: 'Cluster Troubleshooting',
    description: 'Diagnose and fix cluster issues',
    timeLimit: 35,
    tasks: [
      'Identify why a pod is not starting',
      'Fix node NotReady status',
      'Resolve DNS issues',
      'Check cluster component health'
    ]
  }
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    activeSessions: activeSessions.size,
    activeContainers: activeContainers.size
  });
});

// Get available scenarios
app.get('/scenarios', (req, res) => {
  res.json({
    scenarios: Object.keys(CKA_SCENARIOS).map(key => ({
      id: key,
      title: CKA_SCENARIOS[key].title,
      description: CKA_SCENARIOS[key].description,
      timeLimit: CKA_SCENARIOS[key].timeLimit,
      tasks: CKA_SCENARIOS[key].tasks
    }))
  });
});

// Start a new CKA session
app.post('/sessions', async (req, res) => {
  try {
    const { scenarioId, userId } = req.body;
    
    if (!CKA_SCENARIOS[scenarioId]) {
      return res.status(400).json({ error: 'Invalid scenario ID' });
    }

    const sessionId = uuidv4();
    const scenario = CKA_SCENARIOS[scenarioId];

    // Create Ubuntu containers for Kubernetes cluster
    const masterContainer = await createKubernetesNode('master', sessionId);
    const worker1Container = await createKubernetesNode('worker1', sessionId);
    const worker2Container = await createKubernetesNode('worker2', sessionId);

    const session = {
      id: sessionId,
      userId,
      scenarioId,
      scenario,
      startTime: new Date(),
      containers: {
        master: masterContainer.id,
        worker1: worker1Container.id,
        worker2: worker2Container.id
      },
      status: 'active',
      progress: {
        currentTask: 0,
        completedTasks: [],
        timeRemaining: scenario.timeLimit * 60 // Convert to seconds
      }
    };

    activeSessions.set(sessionId, session);
    activeContainers.set(masterContainer.id, sessionId);
    activeContainers.set(worker1Container.id, sessionId);
    activeContainers.set(worker2Container.id, sessionId);

    // Start timer
    setTimeout(() => {
      if (activeSessions.has(sessionId)) {
        endSession(sessionId);
      }
    }, scenario.timeLimit * 60 * 1000);

    res.json({
      sessionId,
      scenario: {
        id: scenarioId,
        title: scenario.title,
        description: scenario.description,
        tasks: scenario.tasks,
        timeLimit: scenario.timeLimit
      },
      containers: session.containers
    });

  } catch (error) {
    console.error('Error creating session:', error);
    res.status(500).json({ error: 'Failed to create session' });
  }
});

// Get session status
app.get('/sessions/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  const session = activeSessions.get(sessionId);

  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  res.json({
    id: session.id,
    scenarioId: session.scenarioId,
    status: session.status,
    progress: session.progress,
    startTime: session.startTime,
    containers: session.containers
  });
});

// Validate task completion
app.post('/sessions/:sessionId/validate', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { taskIndex } = req.body;
    
    const session = activeSessions.get(sessionId);
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const scenario = session.scenario;
    const validation = scenario.validation;
    
    if (!validation) {
      return res.json({ valid: true, message: 'No validation configured' });
    }

    // Execute validation commands in master container
    const container = docker.getContainer(session.containers.master);
    const results = [];

    for (const command of validation.commands) {
      const exec = await container.exec({
        Cmd: command.split(' '),
        AttachStdout: true,
        AttachStderr: true
      });

      const stream = await exec.start();
      const output = await streamToString(stream);
      results.push(output);
    }

    // Check if expected outputs are present
    const isValid = validation.expectedOutputs.every(expected =>
      results.some(result => result.includes(expected))
    );

    if (isValid) {
      session.progress.completedTasks.push(taskIndex);
      session.progress.currentTask = Math.min(taskIndex + 1, scenario.tasks.length);
    }

    res.json({
      valid: isValid,
      message: isValid ? 'Task completed successfully!' : 'Task validation failed',
      output: results.join('\n'),
      progress: session.progress
    });

  } catch (error) {
    console.error('Error validating task:', error);
    res.status(500).json({ error: 'Validation failed' });
  }
});

// End session
app.delete('/sessions/:sessionId', async (req, res) => {
  const { sessionId } = req.params;
  await endSession(sessionId);
  res.json({ message: 'Session ended successfully' });
});

// Socket.IO for terminal connections
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  socket.on('start-terminal', async (data) => {
    try {
      const { sessionId, containerId } = data;
      const session = activeSessions.get(sessionId);
      
      if (!session) {
        socket.emit('error', 'Session not found');
        return;
      }

      const container = docker.getContainer(containerId);
      
      // Create exec instance for interactive shell
      const exec = await container.exec({
        Cmd: ['/bin/bash'],
        AttachStdin: true,
        AttachStdout: true,
        AttachStderr: true,
        Tty: true
      });

      const stream = await exec.start({ Tty: true, stdin: true });
      
      // Forward terminal data
      stream.on('data', (data) => {
        socket.emit('terminal-data', data.toString());
      });

      // Handle input from client
      socket.on('terminal-input', (input) => {
        stream.write(input);
      });

      // Handle terminal resize
      socket.on('terminal-resize', (size) => {
        exec.resize({ h: size.rows, w: size.cols });
      });

      socket.on('disconnect', () => {
        stream.end();
      });

    } catch (error) {
      console.error('Terminal connection error:', error);
      socket.emit('error', 'Failed to connect to terminal');
    }
  });
});

// Helper functions
async function createKubernetesNode(nodeType, sessionId) {
  const containerName = `cka-${sessionId}-${nodeType}`;
  
  const container = await docker.createContainer({
    Image: 'cka-ubuntu:latest', // Custom Ubuntu image with kubeadm
    name: containerName,
    Hostname: nodeType,
    Tty: true,
    OpenStdin: true,
    Privileged: true,
    NetworkMode: `cka-network-${sessionId}`,
    Env: [
      `NODE_TYPE=${nodeType}`,
      `SESSION_ID=${sessionId}`
    ],
    HostConfig: {
      Memory: nodeType === 'master' ? 2147483648 : 1073741824, // 2GB for master, 1GB for workers
      CpuShares: 1024,
      Tmpfs: {
        '/tmp': 'rw,noexec,nosuid,size=100m',
        '/run': 'rw,noexec,nosuid,size=100m'
      }
    },
    Labels: {
      'cka-session': sessionId,
      'node-type': nodeType
    }
  });

  await container.start();
  
  // Initialize the node based on type
  if (nodeType === 'master') {
    await initializeMasterNode(container);
  } else {
    await initializeWorkerNode(container, sessionId);
  }

  return container;
}

async function initializeMasterNode(container) {
  const commands = [
    'kubeadm init --pod-network-cidr=192.168.0.0/16',
    'mkdir -p $HOME/.kube',
    'cp -i /etc/kubernetes/admin.conf $HOME/.kube/config',
    'chown $(id -u):$(id -g) $HOME/.kube/config',
    'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml'
  ];

  for (const command of commands) {
    await executeCommand(container, command);
  }
}

async function initializeWorkerNode(container, sessionId) {
  // Worker nodes will join the cluster when the join command is available
  // This would typically involve getting the join token from the master
  await executeCommand(container, 'echo "Worker node ready for join command"');
}

async function executeCommand(container, command) {
  const exec = await container.exec({
    Cmd: ['/bin/bash', '-c', command],
    AttachStdout: true,
    AttachStderr: true
  });

  const stream = await exec.start();
  return streamToString(stream);
}

async function streamToString(stream) {
  return new Promise((resolve, reject) => {
    let data = '';
    stream.on('data', chunk => data += chunk.toString());
    stream.on('end', () => resolve(data));
    stream.on('error', reject);
  });
}

async function endSession(sessionId) {
  const session = activeSessions.get(sessionId);
  if (!session) return;

  // Stop and remove containers
  for (const containerId of Object.values(session.containers)) {
    try {
      const container = docker.getContainer(containerId);
      await container.stop();
      await container.remove();
      activeContainers.delete(containerId);
    } catch (error) {
      console.error(`Error cleaning up container ${containerId}:`, error);
    }
  }

  // Remove session
  activeSessions.delete(sessionId);
  
  console.log(`Session ${sessionId} ended and cleaned up`);
}

// Cleanup on exit
process.on('SIGTERM', async () => {
  console.log('Cleaning up active sessions...');
  for (const sessionId of activeSessions.keys()) {
    await endSession(sessionId);
  }
  process.exit(0);
});

server.listen(PORT, () => {
  console.log(`CKA Simulator Service running on port ${PORT}`);
});

module.exports = app;