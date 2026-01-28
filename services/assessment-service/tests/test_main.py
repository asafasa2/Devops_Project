import pytest
import json
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys
import os

# Add the parent directory to the path to import the app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app, get_db, Base, Assessment, Quiz, Certification

# Create test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture
def sample_quiz_data():
    """Sample quiz data for testing."""
    return {
        "title": "Docker Basics Quiz",
        "description": "Test your Docker knowledge",
        "tool_category": "docker",
        "difficulty_level": "beginner",
        "questions": [
            {
                "id": 1,
                "type": "multiple_choice",
                "question": "What is Docker?",
                "options": ["Container platform", "Virtual machine", "Programming language", "Database"],
                "correct_answer": "Container platform",
                "explanation": "Docker is a containerization platform",
                "points": 2
            },
            {
                "id": 2,
                "type": "true_false",
                "question": "Docker containers share the host OS kernel",
                "options": ["True", "False"],
                "correct_answer": "True",
                "explanation": "Containers share the kernel unlike VMs",
                "points": 1
            }
        ],
        "time_limit": 30,
        "passing_score": 70
    }

@pytest.fixture
def auth_headers():
    """Mock authentication headers."""
    # In a real scenario, this would be a valid JWT token
    return {"Authorization": "Bearer mock-jwt-token"}

@pytest.fixture
def mock_jwt_decode():
    """Mock JWT decode to return a user ID."""
    with patch('main.jwt.decode') as mock_decode:
        mock_decode.return_value = {"sub": 1}
        yield mock_decode

class TestHealthCheck:
    """Test health check endpoint."""
    
    @patch('main.redis_client')
    def test_health_check_success(self, mock_redis):
        """Test successful health check."""
        mock_redis.ping.return_value = True
        
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data
        assert data["database"] == "healthy"
        assert data["redis"] == "healthy"

    @patch('main.redis_client')
    def test_health_check_redis_failure(self, mock_redis):
        """Test health check with Redis failure."""
        mock_redis.ping.side_effect = Exception("Redis connection failed")
        
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["database"] == "healthy"
        assert data["redis"] == "unhealthy"

class TestQuizManagement:
    """Test quiz management endpoints."""
    
    def test_get_quizzes_empty(self, auth_headers, mock_jwt_decode):
        """Test getting quizzes when none exist."""
        response = client.get("/assessments/quizzes", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0

    def test_create_quiz_success(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test successful quiz creation."""
        response = client.post("/assessments/quizzes", 
                              json=sample_quiz_data, 
                              headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == sample_quiz_data["title"]
        assert data["tool_category"] == sample_quiz_data["tool_category"]
        assert data["question_count"] == len(sample_quiz_data["questions"])

    def test_create_quiz_invalid_data(self, auth_headers, mock_jwt_decode):
        """Test quiz creation with invalid data."""
        invalid_quiz = {
            "title": "Invalid Quiz",
            # Missing required fields
        }
        
        response = client.post("/assessments/quizzes", 
                              json=invalid_quiz, 
                              headers=auth_headers)
        
        assert response.status_code == 422  # Validation error

    def test_get_quiz_by_id(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test getting a specific quiz by ID."""
        # Create quiz first
        create_response = client.post("/assessments/quizzes", 
                                     json=sample_quiz_data, 
                                     headers=auth_headers)
        quiz_id = create_response.json()["id"]
        
        # Get quiz
        response = client.get(f"/assessments/quizzes/{quiz_id}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == quiz_id
        assert data["title"] == sample_quiz_data["title"]
        assert len(data["questions"]) == len(sample_quiz_data["questions"])
        
        # Verify correct answers are not exposed
        for question in data["questions"]:
            assert "correct_answer" not in question
            assert "explanation" not in question

    def test_get_quiz_not_found(self, auth_headers, mock_jwt_decode):
        """Test getting a non-existent quiz."""
        response = client.get("/assessments/quizzes/999", headers=auth_headers)
        
        assert response.status_code == 404
        data = response.json()
        assert data["detail"] == "Quiz not found"

    def test_filter_quizzes_by_category(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test filtering quizzes by tool category."""
        # Create quiz first
        client.post("/assessments/quizzes", json=sample_quiz_data, headers=auth_headers)
        
        # Filter by category
        response = client.get("/assessments/quizzes?tool_category=docker", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["tool_category"] == "docker"

    def test_filter_quizzes_by_difficulty(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test filtering quizzes by difficulty level."""
        # Create quiz first
        client.post("/assessments/quizzes", json=sample_quiz_data, headers=auth_headers)
        
        # Filter by difficulty
        response = client.get("/assessments/quizzes?difficulty_level=beginner", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["difficulty_level"] == "beginner"

class TestAssessmentSubmission:
    """Test assessment submission and scoring."""
    
    def test_submit_assessment_success(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test successful assessment submission."""
        # Create quiz first
        create_response = client.post("/assessments/quizzes", 
                                     json=sample_quiz_data, 
                                     headers=auth_headers)
        quiz_id = create_response.json()["id"]
        
        # Submit assessment
        submission_data = {
            "quiz_id": quiz_id,
            "answers": [
                {"question_id": 1, "answer": "Container platform"},
                {"question_id": 2, "answer": "True"}
            ],
            "completion_time": 300
        }
        
        response = client.post("/assessments/submit", 
                              json=submission_data, 
                              headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["quiz_id"] == quiz_id
        assert data["score"] == 3  # Both answers correct (2+1 points)
        assert data["max_score"] == 3
        assert data["percentage"] == 100.0
        assert data["passed"] == True
        assert len(data["detailed_results"]) == 2

    def test_submit_assessment_partial_correct(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test assessment submission with partial correct answers."""
        # Create quiz first
        create_response = client.post("/assessments/quizzes", 
                                     json=sample_quiz_data, 
                                     headers=auth_headers)
        quiz_id = create_response.json()["id"]
        
        # Submit assessment with one wrong answer
        submission_data = {
            "quiz_id": quiz_id,
            "answers": [
                {"question_id": 1, "answer": "Virtual machine"},  # Wrong
                {"question_id": 2, "answer": "True"}  # Correct
            ]
        }
        
        response = client.post("/assessments/submit", 
                              json=submission_data, 
                              headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["score"] == 1  # Only second answer correct (1 point)
        assert data["max_score"] == 3
        assert data["percentage"] == 33.33
        assert data["passed"] == False  # Below 70% passing score

    def test_submit_assessment_quiz_not_found(self, auth_headers, mock_jwt_decode):
        """Test submitting assessment for non-existent quiz."""
        submission_data = {
            "quiz_id": 999,
            "answers": [{"question_id": 1, "answer": "test"}]
        }
        
        response = client.post("/assessments/submit", 
                              json=submission_data, 
                              headers=auth_headers)
        
        assert response.status_code == 404
        data = response.json()
        assert data["detail"] == "Quiz not found"

class TestAssessmentHistory:
    """Test assessment history endpoints."""
    
    def test_get_assessment_history_empty(self, auth_headers, mock_jwt_decode):
        """Test getting assessment history when none exist."""
        response = client.get("/assessments/history", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0

    def test_get_assessment_history_with_data(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test getting assessment history with existing assessments."""
        # Create and submit quiz
        create_response = client.post("/assessments/quizzes", 
                                     json=sample_quiz_data, 
                                     headers=auth_headers)
        quiz_id = create_response.json()["id"]
        
        submission_data = {
            "quiz_id": quiz_id,
            "answers": [
                {"question_id": 1, "answer": "Container platform"},
                {"question_id": 2, "answer": "True"}
            ]
        }
        
        client.post("/assessments/submit", json=submission_data, headers=auth_headers)
        
        # Get history
        response = client.get("/assessments/history", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["quiz_title"] == sample_quiz_data["title"]
        assert data[0]["tool_category"] == sample_quiz_data["tool_category"]
        assert data[0]["passed"] == True

class TestCertifications:
    """Test certification management."""
    
    def test_get_certifications_empty(self, auth_headers, mock_jwt_decode):
        """Test getting certifications when none exist."""
        response = client.get("/assessments/certifications", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0

    @patch('main.check_certification_eligibility')
    def test_certification_eligibility_check(self, mock_check_cert, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test that certification eligibility is checked for advanced quizzes."""
        # Create advanced quiz
        advanced_quiz = sample_quiz_data.copy()
        advanced_quiz["difficulty_level"] = "advanced"
        
        create_response = client.post("/assessments/quizzes", 
                                     json=advanced_quiz, 
                                     headers=auth_headers)
        quiz_id = create_response.json()["id"]
        
        # Submit passing assessment
        submission_data = {
            "quiz_id": quiz_id,
            "answers": [
                {"question_id": 1, "answer": "Container platform"},
                {"question_id": 2, "answer": "True"}
            ]
        }
        
        response = client.post("/assessments/submit", 
                              json=submission_data, 
                              headers=auth_headers)
        
        assert response.status_code == 200
        assert response.json()["passed"] == True
        
        # Verify certification check was called
        mock_check_cert.assert_called_once()

class TestAssessmentStatistics:
    """Test assessment statistics endpoints."""
    
    def test_get_stats_empty(self, auth_headers, mock_jwt_decode):
        """Test getting statistics when no assessments exist."""
        response = client.get("/assessments/stats", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_assessments"] == 0
        assert data["average_score"] == 0
        assert data["total_time_spent"] == 0
        assert data["certifications_earned"] == 0
        assert data["category_breakdown"] == {}

    def test_get_stats_with_data(self, sample_quiz_data, auth_headers, mock_jwt_decode):
        """Test getting statistics with existing assessments."""
        # Create and submit quiz
        create_response = client.post("/assessments/quizzes", 
                                     json=sample_quiz_data, 
                                     headers=auth_headers)
        quiz_id = create_response.json()["id"]
        
        submission_data = {
            "quiz_id": quiz_id,
            "answers": [
                {"question_id": 1, "answer": "Container platform"},
                {"question_id": 2, "answer": "True"}
            ],
            "completion_time": 300
        }
        
        client.post("/assessments/submit", json=submission_data, headers=auth_headers)
        
        # Get stats
        response = client.get("/assessments/stats", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_assessments"] == 1
        assert data["average_score"] == 100.0
        assert data["total_time_spent"] == 300
        assert "docker" in data["category_breakdown"]

class TestAuthentication:
    """Test authentication requirements."""
    
    def test_endpoints_require_authentication(self):
        """Test that protected endpoints require authentication."""
        protected_endpoints = [
            ("/assessments/quizzes", "GET"),
            ("/assessments/quizzes/1", "GET"),
            ("/assessments/quizzes", "POST"),
            ("/assessments/submit", "POST"),
            ("/assessments/history", "GET"),
            ("/assessments/certifications", "GET"),
            ("/assessments/stats", "GET")
        ]
        
        for endpoint, method in protected_endpoints:
            if method == "GET":
                response = client.get(endpoint)
            elif method == "POST":
                response = client.post(endpoint, json={})
            
            assert response.status_code == 403  # Forbidden without auth

if __name__ == '__main__':
    pytest.main([__file__])