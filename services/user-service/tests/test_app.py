import pytest
import json
from unittest.mock import patch, MagicMock
from flask import Flask
from flask_jwt_extended import create_access_token
import sys
import os

# Add the parent directory to the path to import the app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app, db, User, bcrypt

@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['JWT_SECRET_KEY'] = 'test-secret'
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()

@pytest.fixture
def sample_user():
    """Create a sample user for testing."""
    return {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'testpassword123'
    }

@pytest.fixture
def auth_headers(client, sample_user):
    """Create authentication headers with a valid JWT token."""
    # Create user first
    response = client.post('/auth/register', 
                          data=json.dumps(sample_user),
                          content_type='application/json')
    
    token = response.json['access_token']
    return {'Authorization': f'Bearer {token}'}

class TestHealthCheck:
    """Test health check endpoint."""
    
    @patch('app.redis_client')
    def test_health_check_success(self, mock_redis, client):
        """Test successful health check."""
        mock_redis.ping.return_value = True
        
        response = client.get('/health')
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'healthy'
        assert 'timestamp' in data
        assert data['database'] == 'healthy'
        assert data['redis'] == 'healthy'

    @patch('app.redis_client')
    def test_health_check_redis_failure(self, mock_redis, client):
        """Test health check with Redis failure."""
        mock_redis.ping.side_effect = Exception("Redis connection failed")
        
        response = client.get('/health')
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'healthy'
        assert data['database'] == 'healthy'
        assert data['redis'] == 'unhealthy'

class TestAuthentication:
    """Test authentication endpoints."""
    
    def test_register_success(self, client, sample_user):
        """Test successful user registration."""
        response = client.post('/auth/register',
                              data=json.dumps(sample_user),
                              content_type='application/json')
        
        assert response.status_code == 201
        data = response.get_json()
        assert data['message'] == 'User registered successfully'
        assert 'access_token' in data
        assert data['user']['username'] == sample_user['username']
        assert data['user']['email'] == sample_user['email']
        assert 'password_hash' not in data['user']

    def test_register_missing_fields(self, client):
        """Test registration with missing required fields."""
        incomplete_user = {'username': 'testuser'}
        
        response = client.post('/auth/register',
                              data=json.dumps(incomplete_user),
                              content_type='application/json')
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'Missing required fields' in data['error']

    def test_register_duplicate_username(self, client, sample_user):
        """Test registration with duplicate username."""
        # Register first user
        client.post('/auth/register',
                   data=json.dumps(sample_user),
                   content_type='application/json')
        
        # Try to register with same username
        duplicate_user = sample_user.copy()
        duplicate_user['email'] = 'different@example.com'
        
        response = client.post('/auth/register',
                              data=json.dumps(duplicate_user),
                              content_type='application/json')
        
        assert response.status_code == 409
        data = response.get_json()
        assert data['error'] == 'Username already exists'

    def test_register_duplicate_email(self, client, sample_user):
        """Test registration with duplicate email."""
        # Register first user
        client.post('/auth/register',
                   data=json.dumps(sample_user),
                   content_type='application/json')
        
        # Try to register with same email
        duplicate_user = sample_user.copy()
        duplicate_user['username'] = 'differentuser'
        
        response = client.post('/auth/register',
                              data=json.dumps(duplicate_user),
                              content_type='application/json')
        
        assert response.status_code == 409
        data = response.get_json()
        assert data['error'] == 'Email already exists'

    @patch('app.redis_client')
    def test_login_success(self, mock_redis, client, sample_user):
        """Test successful login."""
        mock_redis.setex.return_value = True
        
        # Register user first
        client.post('/auth/register',
                   data=json.dumps(sample_user),
                   content_type='application/json')
        
        # Login
        login_data = {
            'username': sample_user['username'],
            'password': sample_user['password']
        }
        
        response = client.post('/auth/login',
                              data=json.dumps(login_data),
                              content_type='application/json')
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['message'] == 'Login successful'
        assert 'access_token' in data
        assert data['user']['username'] == sample_user['username']

    def test_login_invalid_credentials(self, client, sample_user):
        """Test login with invalid credentials."""
        # Register user first
        client.post('/auth/register',
                   data=json.dumps(sample_user),
                   content_type='application/json')
        
        # Try login with wrong password
        login_data = {
            'username': sample_user['username'],
            'password': 'wrongpassword'
        }
        
        response = client.post('/auth/login',
                              data=json.dumps(login_data),
                              content_type='application/json')
        
        assert response.status_code == 401
        data = response.get_json()
        assert data['error'] == 'Invalid credentials'

    def test_login_missing_fields(self, client):
        """Test login with missing fields."""
        login_data = {'username': 'testuser'}
        
        response = client.post('/auth/login',
                              data=json.dumps(login_data),
                              content_type='application/json')
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'Missing username or password' in data['error']

    @patch('app.redis_client')
    def test_logout_success(self, mock_redis, client, auth_headers):
        """Test successful logout."""
        mock_redis.delete.return_value = True
        
        response = client.post('/auth/logout', headers=auth_headers)
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['message'] == 'Logout successful'

class TestUserProfile:
    """Test user profile endpoints."""
    
    def test_get_profile_success(self, client, auth_headers):
        """Test successful profile retrieval."""
        response = client.get('/users/profile', headers=auth_headers)
        
        assert response.status_code == 200
        data = response.get_json()
        assert 'username' in data
        assert 'email' in data
        assert 'learning_progress' in data
        assert 'current_level' in data
        assert 'total_points' in data

    def test_get_profile_unauthorized(self, client):
        """Test profile retrieval without authentication."""
        response = client.get('/users/profile')
        
        assert response.status_code == 422  # JWT missing

    def test_update_profile_success(self, client, auth_headers):
        """Test successful profile update."""
        update_data = {
            'email': 'newemail@example.com',
            'current_level': 'intermediate'
        }
        
        response = client.put('/users/profile',
                             data=json.dumps(update_data),
                             content_type='application/json',
                             headers=auth_headers)
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['message'] == 'Profile updated successfully'
        assert data['user']['email'] == update_data['email']
        assert data['user']['current_level'] == update_data['current_level']

class TestLearningProgress:
    """Test learning progress endpoints."""
    
    def test_get_progress_success(self, client, auth_headers):
        """Test successful progress retrieval."""
        response = client.get('/users/progress', headers=auth_headers)
        
        assert response.status_code == 200
        data = response.get_json()
        assert 'learning_progress' in data
        assert 'current_level' in data
        assert 'total_points' in data

    def test_update_progress_success(self, client, auth_headers):
        """Test successful progress update."""
        progress_data = {
            'module_id': 1,
            'progress': 75,
            'points': 10,
            'level': 'intermediate'
        }
        
        response = client.post('/users/progress',
                              data=json.dumps(progress_data),
                              content_type='application/json',
                              headers=auth_headers)
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['message'] == 'Progress updated successfully'
        assert '1' in data['learning_progress']
        assert data['learning_progress']['1']['progress'] == 75
        assert data['total_points'] == 10
        assert data['current_level'] == 'intermediate'

    def test_update_progress_completion(self, client, auth_headers):
        """Test progress update with completion."""
        progress_data = {
            'module_id': 2,
            'progress': 100,
            'points': 15
        }
        
        response = client.post('/users/progress',
                              data=json.dumps(progress_data),
                              content_type='application/json',
                              headers=auth_headers)
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['learning_progress']['2']['progress'] == 100
        assert data['learning_progress']['2']['completed_at'] is not None

if __name__ == '__main__':
    pytest.main([__file__])