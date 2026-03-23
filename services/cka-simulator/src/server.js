const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const Docker = require('dockerode');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs').promises;
const yaml = require('yaml');
const { Pool } = require('pg');
const redis = require('redis');

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

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'devops_practice',
  user: process.env.DB_USER || 'devops_user',
  password: process.env.DB_PASSWORD || 'dev_password_2024',
});

// Redis connection
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Store active sessions and terminals
const activeSessions = new Map();
const activeContainers = new Map();
const activeTerminals = new Map();

// Load CKA scenarios from files
let CKA_SCENARIOS = {};

async function loadScenarios() {
  try {
    const scenariosDir = path.join(__dirname, '../scenarios');
    const files = await fs.readdir(scenariosDir);
    
    for (const file of files) {
      if (file.endsWith('.json')) {
        const scenarioPath = path.join(scenariosDir, file);
        const scenarioData = await fs.readFile(scenarioPath, 'utf8');
        const scenario = JSON.parse(scenarioData);
        CKA_SCENARIOS[scenario.id] = scenario;
      }
    }
    
    console.log(`Loaded ${Object.keys(CKA_SCENARIOS).length} CKA scenarios`);
  } catch (error) {
    console.error('Error loading scenarios:', error);
    // Fallback scenarios
    CKA_SCENARIOS = {
      'cluster-setup': {
        id: 'cluster-setup',
        title: 'Cluster Setup and Management',
        description: 'Initialize a Kubernetes cluster using kubeadm',
        timeLimit: 30,
        difficulty: 'medium',
        weight: 25,
        tasks: [
          { id: 1, title: 'Initialize master node', points: 8 },
          { id: 2, title: 'Install CNI plugin', points: 5 },
          { id: 3, title: 'Join worker nodes', points: 7 },
          { id: 4, title: 'Verify cluster health', points: 5 }
        ]
      }
    };
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    activeSessions: activeSessions.size,
    activeContainers: activeContainers.size,
    scenarios: Object.keys(CKA_SCENARIOS).length
  });
});

// Get available scenarios
app.get('/scenarios', (req, res) => {
  const scenarios = Object.values(CKA_SCENARIOS).map(scenario => ({
    id: scenario.id,
    title: scenario.title,
    description: scenario.description,
    timeLimit: scenario.timeLimit,
    difficulty: scenario.difficulty,
    weight: scenario.weight,
    tasks: scenario.tasks.map(task => ({
      id: task.id,
      title: task.title,
      points: task.points
    }))
  }));
  
  res.json({ scenarios });
});

// Get specific scenario details
app.get('/scenarios/:scenarioId', (req, res) => {
  const { scenarioId } = req.params;
  const scenario = CKA_SCENARIOS[scenarioId];
  
  if (!scenario) {
    return res.status(404).json({ error: 'Scenario not found' });
  }
  
  res.json(scenario);
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

    console.log(`Starting CKA session ${sessionId} for scenario ${scenarioId}`);

    // Create dedicated network for this session
    const networkName = `cka-session-${sessionId}`;
    await createSessionNetwork(networkName);

    // Create Ubuntu containers for Kubernetes cluster
    const masterContainer = await createKubernetesNode('master', sessionId, networkName);
    const worker1Container = await createKubernetesNode('worker1', sessionId, networkName);
    const worker2Container = await createKubernetesNode('worker2', sessionId, networkName);

    const session = {
      id: sessionId,
      userId,
      scenarioId,
      scenario,
      startTime: new Date(),
      networkName,
      containers: {
        master: masterContainer.id,
        worker1: worker1Container.id,
        worker2: worker2Container.id
      },
      status: 'initializing',
      progress: {
        currentTask: 0,
        completedTasks: [],
        timeRemaining: scenario.timeLimit * 60,
        score: 0
      }
    };

    activeSessions.set(sessionId, session);
    activeContainers.set(masterContainer.id, sessionId);
    activeContainers.set(worker1Container.id, sessionId);
    activeContainers.set(worker2Container.id, sessionId);

    // Initialize the cluster in background
    initializeCluster(sessionId);

    // Start session timer
    setTimeout(() => {
      if (activeSessions.has(sessionId)) {
        endSession(sessionId, 'timeout');
      }
    }, scenario.timeLimit * 60 * 1000);

    // Store session in database
    await storeSession(session);

    res.json({
      sessionId,
      scenario: {
        id: scenarioId,
        title: scenario.title,
        description: scenario.description,
        context: scenario.context,
        tasks: scenario.tasks,
        timeLimit: scenario.timeLimit
      },
      containers: session.containers,
      networkName
    });

  } catch (error) {
    console.error('Error creating session:', error);
    res.status(500).json({ error: 'Failed to create session', details: error.message });
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
    containers: session.containers,
    networkName: session.networkName
  });
});

// Validate task completion
app.post('/sessions/:sessionId/validate/:taskId', async (req, res) => {
  try {
    const { sessionId, taskId } = req.params;
    
    const session = activeSessions.get(sessionId);
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const scenario = session.scenario;
    const task = scenario.tasks.find(t => t.id === parseInt(taskId));
    
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    console.log(`Validating task ${taskId} for session ${sessionId}`);

    // Execute validation commands in master container
    const container = docker.getContainer(session.containers.master);
    const validationResults = [];
    let isValid = true;

    if (task.validation) {
      for (const command of task.validation.commands) {
        try {
          const result = await executeCommandInContainer(container, command);
          validationResults.push({
            command,
            output: result.output,
            exitCode: result.exitCode
          });

          // Check if expected outputs are present
          const hasExpectedOutput = task.validation.expectedOutputs.some(expected =>
            result.output.includes(expected)
          );

          if (!hasExpectedOutput) {
            isValid = false;
          }
        } catch (error) {
          console.error(`Validation command failed: ${command}`, error);
          isValid = false;
          validationResults.push({
            command,
            output: error.message,
            exitCode: 1
          });
        }
      }
    }

    if (isValid && !session.progress.completedTasks.includes(parseInt(taskId))) {
      session.progress.completedTasks.push(parseInt(taskId));
      session.progress.score += task.points;
      session.progress.currentTask = Math.max(session.progress.currentTask, parseInt(taskId));
    }

    // Update session in database
    await updateSessionProgress(sessionId, session.progress);

    res.json({
      valid: isValid,
      message: isValid ? `Task ${taskId} completed successfully! (+${task.points} points)` : `Task ${taskId} validation failed`,
      results: validationResults,
      progress: session.progress,
      hints: !isValid ? task.hints : undefined
    });

  } catch (error) {
    console.error('Error validating task:', error);
    res.status(500).json({ error: 'Validation failed', details: error.message });
  }
});

// Get task hint
app.get('/sessions/:sessionId/tasks/:taskId/hint', (req, res) => {
  const { sessionId, taskId } = req.params;
  const session = activeSessions.get(sessionId);
  
  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  const task = session.scenario.tasks.find(t => t.id === parseInt(taskId));
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }

  const hints = task.hints || ['No hints available for this task'];
  const randomHint = hints[Math.floor(Math.random() * hints.length)];

  res.json({ hint: randomHint });
});

// End session
app.delete('/sessions/:sessionId', async (req, res) => {
  const { sessionId } = req.params;
  await endSession(sessionId, 'manual');
  res.json({ message: 'Session ended successfully' });
});

// Socket.IO for terminal connections
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  socket.on('start-terminal', async (data) => {
    try {
      const { sessionId, containerId, nodeType } = data;
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
        Tty: true,
        User: 'root',
        WorkingDir: '/root'
      });

      const stream = await exec.start({ 
        Tty: true, 
        stdin: true,
        hijack: true
      });
      
      // Store terminal reference
      const terminalId = `${sessionId}-${nodeType}`;
      activeTerminals.set(terminalId, { stream, exec });

      // Send initial prompt
      stream.write(`\r\n🚀 Connected to ${nodeType} node\r\n`);
      stream.write(`📋 CKA Session: ${sessionId}\r\n`);
      stream.write(`⏰ Scenario: ${session.scenario.title}\r\n\r\n`);
      
      // Forward terminal data to client
      stream.on('data', (data) => {
        socket.emit('terminal-data', data.toString());
      });

      // Handle input from client
      socket.on('terminal-input', (input) => {
        if (stream && !stream.destroyed) {
          stream.write(input);
        }
      });

      // Handle terminal resize
      socket.on('terminal-resize', async (size) => {
        try {
          await exec.resize({ h: size.rows, w: size.cols });
        } catch (error) {
          console.error('Error resizing terminal:', error);
        }
      });

      socket.on('disconnect', () => {
        if (stream && !stream.destroyed) {
          stream.end();
        }
        activeTerminals.delete(terminalId);
      });

    } catch (error) {
      console.error('Terminal connection error:', error);
      socket.emit('error', `Failed to connect to terminal: ${error.message}`);
    }
  });
});

// Helper functions
async function createSessionNetwork(networkName) {
  try {
    await docker.createNetwork({
      Name: networkName,
      Driver: 'bridge',
      IPAM: {
        Config: [{
          Subnet: '172.30.0.0/16',
          Gateway: '172.30.0.1'
        }]
      }
    });
    console.log(`Created network: ${networkName}`);
  } catch (error) {
    if (!error.message.includes('already exists')) {
      throw error;
    }
  }
}

async function createKubernetesNode(nodeType, sessionId, networkName) {
  const containerName = `cka-${sessionId}-${nodeType}`;
  
  const container = await docker.createContainer({
    Image: process.env.CKA_IMAGE_NAME || 'cka-ubuntu:latest',
    name: containerName,
    Hostname: nodeType,
    Tty: true,
    OpenStdin: true,
    Privileged: true,
    NetworkMode: networkName,
    Env: [
      `NODE_TYPE=${nodeType}`,
      `SESSION_ID=${sessionId}`,
      `KUBECONFIG=/root/.kube/config`
    ],
    HostConfig: {
      Memory: nodeType === 'master' ? 2147483648 : 1073741824, // 2GB for master, 1GB for workers
      CpuShares: 1024,
      Tmpfs: {
        '/tmp': 'rw,noexec,nosuid,size=100m',
        '/run': 'rw,noexec,nosuid,size=100m'
      },
      Binds: [
        '/sys/fs/cgroup:/sys/fs/cgroup:ro'
      ]
    },
    Labels: {
      'cka-session': sessionId,
      'node-type': nodeType,
      'managed-by': 'cka-simulator'
    }
  });

  await container.start();
  console.log(`Started container: ${containerName}`);
  
  return container;
}

async function initializeCluster(sessionId) {
  try {
    const session = activeSessions.get(sessionId);
    if (!session) return;

    console.log(`Initializing cluster for session ${sessionId}`);
    session.status = 'initializing';

    const masterContainer = docker.getContainer(session.containers.master);
    
    // Wait for container to be fully ready
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    // Initialize master node
    console.log('Initializing master node...');
    await executeCommandInContainer(masterContainer, '/opt/cka-scripts/init-master.sh');
    
    session.status = 'ready';
    console.log(`Cluster initialized for session ${sessionId}`);
    
  } catch (error) {
    console.error(`Error initializing cluster for session ${sessionId}:`, error);
    const session = activeSessions.get(sessionId);
    if (session) {
      session.status = 'error';
    }
  }
}

async function executeCommandInContainer(container, command) {
  const exec = await container.exec({
    Cmd: ['/bin/bash', '-c', command],
    AttachStdout: true,
    AttachStderr: true
  });

  const stream = await exec.start();
  const output = await streamToString(stream);
  const inspect = await exec.inspect();
  
  return {
    output,
    exitCode: inspect.ExitCode
  };
}

async function streamToString(stream) {
  return new Promise((resolve, reject) => {
    let data = '';
    stream.on('data', chunk => data += chunk.toString());
    stream.on('end', () => resolve(data));
    stream.on('error', reject);
  });
}

async function endSession(sessionId, reason = 'manual') {
  const session = activeSessions.get(sessionId);
  if (!session) return;

  console.log(`Ending session ${sessionId} (reason: ${reason})`);

  try {
    // Stop and remove containers
    for (const containerId of Object.values(session.containers)) {
      try {
        const container = docker.getContainer(containerId);
        await container.stop({ t: 10 });
        await container.remove();
        activeContainers.delete(containerId);
      } catch (error) {
        console.error(`Error cleaning up container ${containerId}:`, error);
      }
    }

    // Remove network
    try {
      const network = docker.getNetwork(session.networkName);
      await network.remove();
    } catch (error) {
      console.error(`Error removing network ${session.networkName}:`, error);
    }

    // Close terminals
    for (const [terminalId, terminal] of activeTerminals.entries()) {
      if (terminalId.startsWith(sessionId)) {
        if (terminal.stream && !terminal.stream.destroyed) {
          terminal.stream.end();
        }
        activeTerminals.delete(terminalId);
      }
    }

    // Update session in database
    await updateSessionEnd(sessionId, reason, session.progress);

    // Remove session
    activeSessions.delete(sessionId);
    
    console.log(`Session ${sessionId} ended and cleaned up`);
  } catch (error) {
    console.error(`Error ending session ${sessionId}:`, error);
  }
}

async function storeSession(session) {
  try {
    await pool.query(
      'INSERT INTO cka_sessions (id, user_id, scenario_id, start_time, status, containers, network_name) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [session.id, session.userId, session.scenarioId, session.startTime, session.status, JSON.stringify(session.containers), session.networkName]
    );
  } catch (error) {
    console.error('Error storing session:', error);
  }
}

async function updateSessionProgress(sessionId, progress) {
  try {
    await pool.query(
      'UPDATE cka_sessions SET progress = $1, updated_at = NOW() WHERE id = $2',
      [JSON.stringify(progress), sessionId]
    );
  } catch (error) {
    console.error('Error updating session progress:', error);
  }
}

async function updateSessionEnd(sessionId, endReason, progress) {
  try {
    await pool.query(
      'UPDATE cka_sessions SET end_time = NOW(), end_reason = $1, progress = $2, status = $3 WHERE id = $4',
      [endReason, JSON.stringify(progress), 'completed', sessionId]
    );
  } catch (error) {
    console.error('Error updating session end:', error);
  }
}

// Cleanup on exit
process.on('SIGTERM', async () => {
  console.log('Cleaning up active sessions...');
  for (const sessionId of activeSessions.keys()) {
    await endSession(sessionId, 'shutdown');
  }
  await pool.end();
  await redisClient.quit();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('Cleaning up active sessions...');
  for (const sessionId of activeSessions.keys()) {
    await endSession(sessionId, 'shutdown');
  }
  await pool.end();
  await redisClient.quit();
  process.exit(0);
});

// Initialize and start server
async function startServer() {
  try {
    await loadScenarios();
    
    server.listen(PORT, () => {
      console.log(`🚀 CKA Simulator Service running on port ${PORT}`);
      console.log(`📋 Loaded ${Object.keys(CKA_SCENARIOS).length} scenarios`);
      console.log(`🔗 WebSocket endpoint: ws://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;