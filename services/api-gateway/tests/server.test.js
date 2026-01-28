const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/server');

// Mock the proxy middleware to avoid actual service calls
jest.mock('http-proxy-middleware', () => ({
  createProxyMiddleware: jest.fn(() => (req, res, next) => {
    // Mock successful proxy response
    res.status(200).json({ message: 'Proxied successfully', service: req.path });
  })
}));

describe('API Gateway', () => {
  const JWT_SECRET = process.env.JWT_SECRET || 'default-secret';
  let validToken;
  let invalidToken;

  beforeAll(() => {
    // Create valid JWT token for testing
    validToken = jwt.sign({ sub: 1, username: 'testuser' }, JWT_SECRET, { expiresIn: '1h' });
    invalidToken = 'invalid.token.here';
  });

  describe('Health Check', () => {
    test('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('services');
    });
  });

  describe('Authentication Middleware', () => {
    test('should allow access to public auth routes without token', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({ username: 'test', password: 'test' })
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Proxied successfully');
    });

    test('should reject protected routes without token', async () => {
      const response = await request(app)
        .get('/api/users/profile')
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Access token required');
    });

    test('should reject protected routes with invalid token', async () => {
      const response = await request(app)
        .get('/api/users/profile')
        .set('Authorization', `Bearer ${invalidToken}`)
        .expect(403);

      expect(response.body).toHaveProperty('error', 'Invalid or expired token');
    });

    test('should allow protected routes with valid token', async () => {
      const response = await request(app)
        .get('/api/users/profile')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Proxied successfully');
    });
  });

  describe('Route Proxying', () => {
    test('should proxy user service routes', async () => {
      const response = await request(app)
        .get('/api/users/profile')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body.service).toBe('/profile');
    });

    test('should proxy learning service routes', async () => {
      const response = await request(app)
        .get('/api/learning/modules')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body.service).toBe('/modules');
    });

    test('should proxy assessment service routes', async () => {
      const response = await request(app)
        .get('/api/assessments/quizzes')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body.service).toBe('/quizzes');
    });

    test('should proxy lab service routes', async () => {
      const response = await request(app)
        .get('/api/labs/sessions')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body.service).toBe('/sessions');
    });
  });

  describe('Rate Limiting', () => {
    test('should apply rate limiting', async () => {
      // Make multiple requests to test rate limiting
      const requests = Array(5).fill().map(() => 
        request(app).get('/health')
      );

      const responses = await Promise.all(requests);
      
      // All requests should succeed within the limit
      responses.forEach(response => {
        expect(response.status).toBe(200);
      });
    });
  });

  describe('Error Handling', () => {
    test('should return 404 for unknown routes', async () => {
      const response = await request(app)
        .get('/api/unknown/route')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Route not found');
      expect(response.body).toHaveProperty('path', '/api/unknown/route');
    });
  });
});