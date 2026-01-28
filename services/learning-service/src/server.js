const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { Pool } = require('pg');
const redis = require('redis');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 4001;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || `postgresql://${process.env.DB_USER || 'devops_user'}:${process.env.DB_PASSWORD || 'dev_password_2024'}@${process.env.DB_HOST || 'postgres'}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME || 'devops_practice'}`,
});

// Redis connection
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://redis:6379'
});

redisClient.on('error', (err) => console.log('Redis Client Error', err));
redisClient.connect();

// JWT middleware
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

// Validation schemas
const moduleSchema = Joi.object({
  title: Joi.string().required(),
  content_type: Joi.string().valid('module', 'quiz', 'lab').required(),
  tool_category: Joi.string().valid('docker', 'ansible', 'terraform', 'jenkins', 'git').required(),
  difficulty_level: Joi.string().valid('beginner', 'intermediate', 'advanced').required(),
  content_data: Joi.object().required(),
  prerequisites: Joi.array().items(Joi.string()),
  estimated_duration: Joi.number().integer().min(1)
});

// Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    await redisClient.ping();
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: 'connected',
      redis: 'connected'
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// Get all learning modules
app.get('/learning/modules', authenticateToken, async (req, res) => {
  try {
    const { tool_category, difficulty_level, content_type } = req.query;
    
    let query = 'SELECT * FROM learning_content WHERE 1=1';
    const params = [];
    let paramCount = 0;
    
    if (tool_category) {
      paramCount++;
      query += ` AND tool_category = $${paramCount}`;
      params.push(tool_category);
    }
    
    if (difficulty_level) {
      paramCount++;
      query += ` AND difficulty_level = $${paramCount}`;
      params.push(difficulty_level);
    }
    
    if (content_type) {
      paramCount++;
      query += ` AND content_type = $${paramCount}`;
      params.push(content_type);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, params);
    
    // Cache the result
    const cacheKey = `modules:${JSON.stringify(req.query)}`;
    await redisClient.setEx(cacheKey, 300, JSON.stringify(result.rows)); // Cache for 5 minutes
    
    res.json({
      modules: result.rows,
      total: result.rows.length
    });
  } catch (error) {
    console.error('Error fetching modules:', error);
    res.status(500).json({ error: 'Failed to fetch learning modules' });
  }
});

// Get specific learning module
app.get('/learning/modules/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check cache first
    const cacheKey = `module:${id}`;
    const cached = await redisClient.get(cacheKey);
    
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    const result = await pool.query(
      'SELECT * FROM learning_content WHERE id = $1',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Learning module not found' });
    }
    
    const module = result.rows[0];
    
    // Cache the result
    await redisClient.setEx(cacheKey, 600, JSON.stringify(module)); // Cache for 10 minutes
    
    res.json(module);
  } catch (error) {
    console.error('Error fetching module:', error);
    res.status(500).json({ error: 'Failed to fetch learning module' });
  }
});

// Create new learning module (admin only)
app.post('/learning/modules', authenticateToken, async (req, res) => {
  try {
    const { error, value } = moduleSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    const {
      title,
      content_type,
      tool_category,
      difficulty_level,
      content_data,
      prerequisites = [],
      estimated_duration
    } = value;
    
    const result = await pool.query(
      `INSERT INTO learning_content 
       (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration]
    );
    
    // Clear related caches
    const keys = await redisClient.keys('modules:*');
    if (keys.length > 0) {
      await redisClient.del(keys);
    }
    
    res.status(201).json({
      message: 'Learning module created successfully',
      module: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating module:', error);
    res.status(500).json({ error: 'Failed to create learning module' });
  }
});

// Get learning path recommendations
app.get('/learning/recommendations', authenticateToken, async (req, res) => {
  try {
    const userId = req.user;
    
    // Get user's current progress and level
    const userResult = await pool.query(
      'SELECT learning_progress, current_level FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const { learning_progress = {}, current_level } = userResult.rows[0];
    
    // Get completed modules
    const completedModules = Object.keys(learning_progress).filter(
      moduleId => learning_progress[moduleId].progress >= 100
    );
    
    // Find recommended modules based on prerequisites and level
    let query = `
      SELECT * FROM learning_content 
      WHERE difficulty_level = $1 
      AND id NOT IN (${completedModules.map((_, i) => `$${i + 2}`).join(',') || 'NULL'})
      ORDER BY created_at ASC
      LIMIT 10
    `;
    
    const params = [current_level, ...completedModules];
    const result = await pool.query(query, params);
    
    // Filter by prerequisites
    const recommendations = result.rows.filter(module => {
      if (!module.prerequisites || module.prerequisites.length === 0) {
        return true;
      }
      
      return module.prerequisites.every(prereq => 
        completedModules.includes(prereq.toString())
      );
    });
    
    res.json({
      recommendations,
      user_level: current_level,
      completed_count: completedModules.length
    });
  } catch (error) {
    console.error('Error getting recommendations:', error);
    res.status(500).json({ error: 'Failed to get recommendations' });
  }
});

// Get learning statistics
app.get('/learning/stats', authenticateToken, async (req, res) => {
  try {
    const userId = req.user;
    
    // Get user progress
    const userResult = await pool.query(
      'SELECT learning_progress, total_points, current_level FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const { learning_progress = {}, total_points, current_level } = userResult.rows[0];
    
    // Calculate statistics
    const totalModules = await pool.query('SELECT COUNT(*) FROM learning_content');
    const completedModules = Object.values(learning_progress).filter(
      progress => progress.progress >= 100
    ).length;
    
    const inProgressModules = Object.values(learning_progress).filter(
      progress => progress.progress > 0 && progress.progress < 100
    ).length;
    
    // Get category breakdown
    const categoryStats = await pool.query(`
      SELECT tool_category, COUNT(*) as total,
      COUNT(CASE WHEN id::text = ANY($1) THEN 1 END) as completed
      FROM learning_content
      GROUP BY tool_category
    `, [Object.keys(learning_progress).filter(id => learning_progress[id].progress >= 100)]);
    
    res.json({
      total_points,
      current_level,
      modules: {
        total: parseInt(totalModules.rows[0].count),
        completed: completedModules,
        in_progress: inProgressModules,
        not_started: parseInt(totalModules.rows[0].count) - completedModules - inProgressModules
      },
      categories: categoryStats.rows.reduce((acc, row) => {
        acc[row.tool_category] = {
          total: parseInt(row.total),
          completed: parseInt(row.completed)
        };
        return acc;
      }, {})
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({ error: 'Failed to get learning statistics' });
  }
});

// Update module progress
app.post('/learning/progress/:moduleId', authenticateToken, async (req, res) => {
  try {
    const { moduleId } = req.params;
    const { progress, time_spent } = req.body;
    const userId = req.user;
    
    if (progress < 0 || progress > 100) {
      return res.status(400).json({ error: 'Progress must be between 0 and 100' });
    }
    
    // Verify module exists
    const moduleResult = await pool.query(
      'SELECT id FROM learning_content WHERE id = $1',
      [moduleId]
    );
    
    if (moduleResult.rows.length === 0) {
      return res.status(404).json({ error: 'Learning module not found' });
    }
    
    // Get current user progress
    const userResult = await pool.query(
      'SELECT learning_progress FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    let learningProgress = userResult.rows[0].learning_progress || {};
    
    // Update progress
    learningProgress[moduleId] = {
      progress,
      time_spent: (learningProgress[moduleId]?.time_spent || 0) + (time_spent || 0),
      last_accessed: new Date().toISOString(),
      completed_at: progress >= 100 ? new Date().toISOString() : learningProgress[moduleId]?.completed_at
    };
    
    // Calculate points (10 points per completed module)
    let pointsToAdd = 0;
    if (progress >= 100 && (!learningProgress[moduleId]?.completed_at || learningProgress[moduleId].progress < 100)) {
      pointsToAdd = 10;
    }
    
    // Update user record
    await pool.query(
      'UPDATE users SET learning_progress = $1, total_points = total_points + $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3',
      [JSON.stringify(learningProgress), pointsToAdd, userId]
    );
    
    res.json({
      message: 'Progress updated successfully',
      progress: learningProgress[moduleId],
      points_earned: pointsToAdd
    });
  } catch (error) {
    console.error('Error updating progress:', error);
    res.status(500).json({ error: 'Failed to update progress' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Learning Service Error:', err);
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
  console.log(`Learning Service running on port ${PORT}`);
});

module.exports = app;