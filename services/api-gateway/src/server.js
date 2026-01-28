const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 4000;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// Service discovery configuration
const services = {
  user: process.env.USER_SERVICE_URL || 'http://user-service:4002',
  learning: process.env.LEARNING_SERVICE_URL || 'http://learning-service:4001',
  assessment: process.env.ASSESSMENT_SERVICE_URL || 'http://assessment-service:4004',
  lab: process.env.LAB_SERVICE_URL || 'http://lab-service:4003'
};

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'default-secret', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: services
  });
});

// Public routes (no authentication required)
app.use('/api/auth', createProxyMiddleware({
  target: services.user,
  changeOrigin: true,
  pathRewrite: {
    '^/api/auth': '/auth'
  }
}));

// Protected routes (authentication required)
app.use('/api/users', authenticateToken, createProxyMiddleware({
  target: services.user,
  changeOrigin: true,
  pathRewrite: {
    '^/api/users': '/users'
  }
}));

app.use('/api/learning', authenticateToken, createProxyMiddleware({
  target: services.learning,
  changeOrigin: true,
  pathRewrite: {
    '^/api/learning': '/learning'
  }
}));

app.use('/api/assessments', authenticateToken, createProxyMiddleware({
  target: services.assessment,
  changeOrigin: true,
  pathRewrite: {
    '^/api/assessments': '/assessments'
  }
}));

app.use('/api/labs', authenticateToken, createProxyMiddleware({
  target: services.lab,
  changeOrigin: true,
  pathRewrite: {
    '^/api/labs': '/labs'
  }
}));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('API Gateway Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
});

app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
  console.log('Service endpoints:', services);
});

module.exports = app;