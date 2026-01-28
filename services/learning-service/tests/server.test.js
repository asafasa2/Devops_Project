const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/server');

// Mock dependencies
jest.mock('pg', () => ({
  Pool: jest.fn(() => ({
    query: jest.fn(),
    end: jest.fn()
  }))
}));

jest.mock('redis', () => ({
  createClient: jest.fn(() => ({
    on: jest.fn(),
    connect: jest.fn(),
    ping: jest.fn(),
    get: jest.fn(),
    setEx: jest.fn(),
    keys: jest.fn(),
    del: jest.fn()
  }))
}));

const { Pool } = require('pg');
const redis = require('redis');

describe('Learning Service', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'default-secret';
  let validToken;
  let mockPool;
  let mockRedisClient;

  beforeAll(() => {
    validToken = jwt.sign({ sub: 1, username: 'testuser' }, JWT_SECRET, { expiresIn: '1h' });
    mockPool = new Pool();
    mockRedisClient = redis.createClient();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Health Check', () => {
    test('should return healthy status when all services are up', async () => {
      mockPool.query.mockResolvedValue({ rows: [{ '?column?': 1 }] });
      mockRedisClient.ping.mockResolvedValue('PONG');

      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('database', 'connected');
      expect(response.body).toHaveProperty('redis', 'connected');
    });

    test('should return unhealthy status when database is down', async () => {
      mockPool.query.mockRejectedValue(new Error('Database connection failed'));
      mockRedisClient.ping.mockResolvedValue('PONG');

      const response = await request(app)
        .get('/health')
        .expect(500);

      expect(response.body).toHaveProperty('status', 'unhealthy');
    });
  });

  describe('Learning Modules', () => {
    const sampleModules = [
      {
        id: 1,
        title: 'Docker Basics',
        content_type: 'module',
        tool_category: 'docker',
        difficulty_level: 'beginner',
        content_data: { lessons: ['Introduction', 'Containers'] },
        prerequisites: [],
        estimated_duration: 60,
        created_at: new Date()
      },
      {
        id: 2,
        title: 'Advanced Docker',
        content_type: 'module',
        tool_category: 'docker',
        difficulty_level: 'advanced',
        content_data: { lessons: ['Orchestration', 'Swarm'] },
        prerequisites: ['1'],
        estimated_duration: 120,
        created_at: new Date()
      }
    ];

    test('should get all learning modules', async () => {
      mockPool.query.mockResolvedValue({ rows: sampleModules });
      mockRedisClient.setEx.mockResolvedValue('OK');

      const response = await request(app)
        .get('/learning/modules')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('modules');
      expect(response.body).toHaveProperty('total', 2);
      expect(response.body.modules).toHaveLength(2);
      expect(response.body.modules[0]).toHaveProperty('title', 'Docker Basics');
    });

    test('should filter modules by tool category', async () => {
      const dockerModules = sampleModules.filter(m => m.tool_category === 'docker');
      mockPool.query.mockResolvedValue({ rows: dockerModules });
      mockRedisClient.setEx.mockResolvedValue('OK');

      const response = await request(app)
        .get('/learning/modules?tool_category=docker')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body.modules).toHaveLength(2);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('tool_category = $1'),
        ['docker']
      );
    });

    test('should filter modules by difficulty level', async () => {
      const beginnerModules = sampleModules.filter(m => m.difficulty_level === 'beginner');
      mockPool.query.mockResolvedValue({ rows: beginnerModules });
      mockRedisClient.setEx.mockResolvedValue('OK');

      const response = await request(app)
        .get('/learning/modules?difficulty_level=beginner')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body.modules).toHaveLength(1);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('difficulty_level = $1'),
        ['beginner']
      );
    });

    test('should get specific learning module', async () => {
      mockRedisClient.get.mockResolvedValue(null);
      mockPool.query.mockResolvedValue({ rows: [sampleModules[0]] });
      mockRedisClient.setEx.mockResolvedValue('OK');

      const response = await request(app)
        .get('/learning/modules/1')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('id', 1);
      expect(response.body).toHaveProperty('title', 'Docker Basics');
    });

    test('should return 404 for non-existent module', async () => {
      mockRedisClient.get.mockResolvedValue(null);
      mockPool.query.mockResolvedValue({ rows: [] });

      const response = await request(app)
        .get('/learning/modules/999')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Learning module not found');
    });

    test('should return cached module if available', async () => {
      const cachedModule = JSON.stringify(sampleModules[0]);
      mockRedisClient.get.mockResolvedValue(cachedModule);

      const response = await request(app)
        .get('/learning/modules/1')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('id', 1);
      expect(mockPool.query).not.toHaveBeenCalled();
    });

    test('should create new learning module', async () => {
      const newModule = {
        title: 'Ansible Basics',
        content_type: 'module',
        tool_category: 'ansible',
        difficulty_level: 'beginner',
        content_data: { lessons: ['Introduction', 'Playbooks'] },
        estimated_duration: 90
      };

      mockPool.query.mockResolvedValue({ 
        rows: [{ ...newModule, id: 3, created_at: new Date() }] 
      });
      mockRedisClient.keys.mockResolvedValue(['modules:filter1', 'modules:filter2']);
      mockRedisClient.del.mockResolvedValue(2);

      const response = await request(app)
        .post('/learning/modules')
        .set('Authorization', `Bearer ${validToken}`)
        .send(newModule)
        .expect(201);

      expect(response.body).toHaveProperty('message', 'Learning module created successfully');
      expect(response.body.module).toHaveProperty('title', 'Ansible Basics');
    });

    test('should validate module data when creating', async () => {
      const invalidModule = {
        title: 'Invalid Module',
        // Missing required fields
      };

      const response = await request(app)
        .post('/learning/modules')
        .set('Authorization', `Bearer ${validToken}`)
        .send(invalidModule)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('Learning Recommendations', () => {
    test('should get learning recommendations based on user progress', async () => {
      const userProgress = {
        learning_progress: { '1': { progress: 100 } },
        current_level: 'beginner'
      };
      
      mockPool.query
        .mockResolvedValueOnce({ rows: [userProgress] }) // User query
        .mockResolvedValueOnce({ rows: [sampleModules[1]] }); // Recommendations query

      const response = await request(app)
        .get('/learning/recommendations')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('recommendations');
      expect(response.body).toHaveProperty('user_level', 'beginner');
      expect(response.body).toHaveProperty('completed_count', 1);
    });

    test('should return 404 if user not found for recommendations', async () => {
      mockPool.query.mockResolvedValue({ rows: [] });

      const response = await request(app)
        .get('/learning/recommendations')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'User not found');
    });
  });

  describe('Learning Statistics', () => {
    test('should get learning statistics for user', async () => {
      const userStats = {
        learning_progress: { 
          '1': { progress: 100 },
          '2': { progress: 50 }
        },
        total_points: 25,
        current_level: 'intermediate'
      };

      mockPool.query
        .mockResolvedValueOnce({ rows: [userStats] }) // User query
        .mockResolvedValueOnce({ rows: [{ count: '10' }] }) // Total modules
        .mockResolvedValueOnce({ rows: [
          { tool_category: 'docker', total: '5', completed: '2' },
          { tool_category: 'ansible', total: '3', completed: '1' }
        ] }); // Category stats

      const response = await request(app)
        .get('/learning/stats')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('total_points', 25);
      expect(response.body).toHaveProperty('current_level', 'intermediate');
      expect(response.body.modules).toHaveProperty('total', 10);
      expect(response.body.modules).toHaveProperty('completed', 1);
      expect(response.body.modules).toHaveProperty('in_progress', 1);
      expect(response.body).toHaveProperty('categories');
    });
  });

  describe('Progress Tracking', () => {
    test('should update module progress', async () => {
      const moduleId = '1';
      const progressData = { progress: 75, time_spent: 30 };
      
      mockPool.query
        .mockResolvedValueOnce({ rows: [{ id: 1 }] }) // Module exists
        .mockResolvedValueOnce({ rows: [{ learning_progress: {} }] }) // User progress
        .mockResolvedValueOnce({}); // Update query

      const response = await request(app)
        .post(`/learning/progress/${moduleId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send(progressData)
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Progress updated successfully');
      expect(response.body.progress).toHaveProperty('progress', 75);
      expect(response.body).toHaveProperty('points_earned', 0);
    });

    test('should award points for module completion', async () => {
      const moduleId = '1';
      const progressData = { progress: 100, time_spent: 60 };
      
      mockPool.query
        .mockResolvedValueOnce({ rows: [{ id: 1 }] }) // Module exists
        .mockResolvedValueOnce({ rows: [{ learning_progress: {} }] }) // User progress
        .mockResolvedValueOnce({}); // Update query

      const response = await request(app)
        .post(`/learning/progress/${moduleId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send(progressData)
        .expect(200);

      expect(response.body).toHaveProperty('points_earned', 10);
      expect(response.body.progress).toHaveProperty('completed_at');
    });

    test('should validate progress range', async () => {
      const moduleId = '1';
      const invalidProgress = { progress: 150 };

      const response = await request(app)
        .post(`/learning/progress/${moduleId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send(invalidProgress)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Progress must be between 0 and 100');
    });

    test('should return 404 for non-existent module', async () => {
      const moduleId = '999';
      const progressData = { progress: 50 };
      
      mockPool.query.mockResolvedValue({ rows: [] });

      const response = await request(app)
        .post(`/learning/progress/${moduleId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send(progressData)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Learning module not found');
    });
  });

  describe('Authentication', () => {
    test('should reject requests without token', async () => {
      const response = await request(app)
        .get('/learning/modules')
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Access token required');
    });

    test('should reject requests with invalid token', async () => {
      const response = await request(app)
        .get('/learning/modules')
        .set('Authorization', 'Bearer invalid-token')
        .expect(403);

      expect(response.body).toHaveProperty('error', 'Invalid or expired token');
    });
  });
});