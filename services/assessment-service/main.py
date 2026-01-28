from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, DateTime, JSON, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import redis
import os
import json
from jose import JWTError, jwt
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Assessment Service", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/devops_learning")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Redis setup
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'redis'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    decode_responses=True
)

# JWT setup
JWT_SECRET = os.getenv("JWT_SECRET", "default-jwt-secret")
JWT_ALGORITHM = "HS256"

security = HTTPBearer()

# Database Models
class Assessment(Base):
    __tablename__ = "assessments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    content_id = Column(Integer, nullable=False)
    score = Column(Integer, nullable=False)
    max_score = Column(Integer, nullable=False)
    completion_time = Column(Integer)  # in seconds
    answers = Column(JSON)
    completed_at = Column(DateTime, default=datetime.utcnow)

class Quiz(Base):
    __tablename__ = "quizzes"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    tool_category = Column(String(50), nullable=False)
    difficulty_level = Column(String(20), nullable=False)
    questions = Column(JSON, nullable=False)
    time_limit = Column(Integer)  # in minutes
    passing_score = Column(Integer, default=70)
    created_at = Column(DateTime, default=datetime.utcnow)

class Certification(Base):
    __tablename__ = "certifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    tool_category = Column(String(50), nullable=False)
    level = Column(String(20), nullable=False)
    score = Column(Integer, nullable=False)
    issued_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class QuestionModel(BaseModel):
    id: int
    type: str  # multiple_choice, true_false, fill_blank
    question: str
    options: Optional[List[str]] = None
    correct_answer: str
    explanation: Optional[str] = None
    points: int = 1

class QuizCreate(BaseModel):
    title: str
    description: Optional[str] = None
    tool_category: str
    difficulty_level: str
    questions: List[QuestionModel]
    time_limit: Optional[int] = None
    passing_score: int = 70

class QuizResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    tool_category: str
    difficulty_level: str
    question_count: int
    time_limit: Optional[int]
    passing_score: int
    created_at: datetime

class AnswerSubmission(BaseModel):
    question_id: int
    answer: str

class QuizSubmission(BaseModel):
    quiz_id: int
    answers: List[AnswerSubmission]
    completion_time: Optional[int] = None

class AssessmentResult(BaseModel):
    id: int
    quiz_id: int
    score: int
    max_score: int
    percentage: float
    passed: bool
    completion_time: Optional[int]
    completed_at: datetime
    detailed_results: List[Dict[str, Any]]

# Dependency functions
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return user_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

# Health check
@app.get("/health")
async def health_check():
    try:
        # Test database connection
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"
    
    try:
        # Test Redis connection
        redis_client.ping()
        redis_status = "healthy"
    except Exception:
        redis_status = "unhealthy"
    
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "database": db_status,
        "redis": redis_status
    }

# Quiz management endpoints
@app.get("/assessments/quizzes", response_model=List[QuizResponse])
async def get_quizzes(
    tool_category: Optional[str] = None,
    difficulty_level: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: int = Depends(get_current_user)
):
    query = db.query(Quiz)
    
    if tool_category:
        query = query.filter(Quiz.tool_category == tool_category)
    if difficulty_level:
        query = query.filter(Quiz.difficulty_level == difficulty_level)
    
    quizzes = query.all()
    
    return [
        QuizResponse(
            id=quiz.id,
            title=quiz.title,
            description=quiz.description,
            tool_category=quiz.tool_category,
            difficulty_level=quiz.difficulty_level,
            question_count=len(quiz.questions),
            time_limit=quiz.time_limit,
            passing_score=quiz.passing_score,
            created_at=quiz.created_at
        )
        for quiz in quizzes
    ]

@app.get("/assessments/quizzes/{quiz_id}")
async def get_quiz(
    quiz_id: int,
    db: Session = Depends(get_db),
    current_user: int = Depends(get_current_user)
):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    
    # Remove correct answers from questions for security
    questions_for_user = []
    for question in quiz.questions:
        user_question = {
            "id": question["id"],
            "type": question["type"],
            "question": question["question"],
            "points": question.get("points", 1)
        }
        if question["type"] in ["multiple_choice", "true_false"]:
            user_question["options"] = question.get("options", [])
        questions_for_user.append(user_question)
    
    return {
        "id": quiz.id,
        "title": quiz.title,
        "description": quiz.description,
        "tool_category": quiz.tool_category,
        "difficulty_level": quiz.difficulty_level,
        "questions": questions_for_user,
        "time_limit": quiz.time_limit,
        "passing_score": quiz.passing_score
    }

@app.post("/assessments/quizzes", response_model=QuizResponse)
async def create_quiz(
    quiz: QuizCreate,
    db: Session = Depends(get_db),
    current_user: int = Depends(get_current_user)
):
    # Convert questions to dict format
    questions_data = [question.dict() for question in quiz.questions]
    
    db_quiz = Quiz(
        title=quiz.title,
        description=quiz.description,
        tool_category=quiz.tool_category,
        difficulty_level=quiz.difficulty_level,
        questions=questions_data,
        time_limit=quiz.time_limit,
        passing_score=quiz.passing_score
    )
    
    db.add(db_quiz)
    db.commit()
    db.refresh(db_quiz)
    
    return QuizResponse(
        id=db_quiz.id,
        title=db_quiz.title,
        description=db_quiz.description,
        tool_category=db_quiz.tool_category,
        difficulty_level=db_quiz.difficulty_level,
        question_count=len(db_quiz.questions),
        time_limit=db_quiz.time_limit,
        passing_score=db_quiz.passing_score,
        created_at=db_quiz.created_at
    )

# Assessment submission and scoring
@app.post("/assessments/submit", response_model=AssessmentResult)
async def submit_assessment(
    submission: QuizSubmission,
    db: Session = Depends(get_db),
    current_user: int = Depends(get_current_user)
):
    # Get quiz
    quiz = db.query(Quiz).filter(Quiz.id == submission.quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    
    # Calculate score
    total_score = 0
    max_score = 0
    detailed_results = []
    
    # Create answer lookup
    user_answers = {answer.question_id: answer.answer for answer in submission.answers}
    
    for question in quiz.questions:
        question_id = question["id"]
        correct_answer = question["correct_answer"]
        points = question.get("points", 1)
        max_score += points
        
        user_answer = user_answers.get(question_id, "")
        is_correct = user_answer.lower().strip() == correct_answer.lower().strip()
        
        if is_correct:
            total_score += points
        
        detailed_results.append({
            "question_id": question_id,
            "question": question["question"],
            "user_answer": user_answer,
            "correct_answer": correct_answer,
            "is_correct": is_correct,
            "points_earned": points if is_correct else 0,
            "points_possible": points,
            "explanation": question.get("explanation")
        })
    
    percentage = (total_score / max_score * 100) if max_score > 0 else 0
    passed = percentage >= quiz.passing_score
    
    # Save assessment result
    assessment = Assessment(
        user_id=current_user,
        content_id=submission.quiz_id,
        score=total_score,
        max_score=max_score,
        completion_time=submission.completion_time,
        answers=user_answers
    )
    
    db.add(assessment)
    db.commit()
    db.refresh(assessment)
    
    # Check for certification eligibility
    if passed and quiz.difficulty_level == "advanced":
        await check_certification_eligibility(current_user, quiz.tool_category, total_score, db)
    
    return AssessmentResult(
        id=assessment.id,
        quiz_id=submission.quiz_id,
        score=total_score,
        max_score=max_score,
        percentage=round(percentage, 2),
        passed=passed,
        completion_time=submission.completion_time,
        completed_at=assessment.completed_at,
        detailed_results=detailed_results
    )

# Get user's assessment history
@app.get("/assessments/history")
async def get_assessment_history(
    tool_category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: int = Depends(get_current_user)
):
    query = db.query(Assessment).filter(Assessment.user_id == current_user)
    
    if tool_category:
        # Join with Quiz to filter by tool_category
        query = query.join(Quiz, Assessment.content_id == Quiz.id).filter(Quiz.tool_category == tool_category)
    
    assessments = query.order_by(Assessment.completed_at.desc()).all()
    
    results = []
    for assessment in assessments:
        quiz = db.query(Quiz).filter(Quiz.id == assessment.content_id).first()
        percentage = (assessment.score / assessment.max_score * 100) if assessment.max_score > 0 else 0
        
        results.append({
            "id": assessment.id,
            "quiz_title": quiz.title if quiz else "Unknown Quiz",
            "tool_category": quiz.tool_category if quiz else "unknown",
            "score": assessment.score,
            "max_score": assessment.max_score,
            "percentage": round(percentage, 2),
            "passed": percentage >= (quiz.passing_score if quiz else 70),
            "completion_time": assessment.completion_time,
            "completed_at": assessment.completed_at
        })
    
    return results

# Certification management
async def check_certification_eligibility(user_id: int, tool_category: str, score: int, db: Session):
    """Check if user is eligible for certification based on their performance"""
    # Get all assessments for this user and tool category
    assessments = db.query(Assessment).join(Quiz, Assessment.content_id == Quiz.id).filter(
        Assessment.user_id == user_id,
        Quiz.tool_category == tool_category
    ).all()
    
    if len(assessments) >= 3:  # Require at least 3 completed assessments
        avg_score = sum(a.score / a.max_score for a in assessments) / len(assessments) * 100
        
        if avg_score >= 80:  # 80% average required for certification
            # Check if certification already exists
            existing_cert = db.query(Certification).filter(
                Certification.user_id == user_id,
                Certification.tool_category == tool_category
            ).first()
            
            if not existing_cert:
                certification = Certification(
                    user_id=user_id,
                    tool_category=tool_category,
                    level="advanced",
                    score=int(avg_score),
                    expires_at=datetime.utcnow() + timedelta(days=365)  # 1 year validity
                )
                db.add(certification)
                db.commit()

@app.get("/assessments/certifications")
async def get_certifications(
    db: Session = Depends(get_db),
    current_user: int = Depends(get_current_user)
):
    certifications = db.query(Certification).filter(Certification.user_id == current_user).all()
    
    return [
        {
            "id": cert.id,
            "tool_category": cert.tool_category,
            "level": cert.level,
            "score": cert.score,
            "issued_at": cert.issued_at,
            "expires_at": cert.expires_at,
            "is_valid": cert.expires_at > datetime.utcnow() if cert.expires_at else True
        }
        for cert in certifications
    ]

# Statistics endpoint
@app.get("/assessments/stats")
async def get_assessment_stats(
    db: Session = Depends(get_db),
    current_user: int = Depends(get_current_user)
):
    assessments = db.query(Assessment).filter(Assessment.user_id == current_user).all()
    
    if not assessments:
        return {
            "total_assessments": 0,
            "average_score": 0,
            "total_time_spent": 0,
            "certifications_earned": 0,
            "category_breakdown": {}
        }
    
    total_assessments = len(assessments)
    average_score = sum(a.score / a.max_score for a in assessments) / total_assessments * 100
    total_time_spent = sum(a.completion_time or 0 for a in assessments)
    
    # Get certifications count
    certifications_count = db.query(Certification).filter(Certification.user_id == current_user).count()
    
    # Category breakdown
    category_stats = {}
    for assessment in assessments:
        quiz = db.query(Quiz).filter(Quiz.id == assessment.content_id).first()
        if quiz:
            category = quiz.tool_category
            if category not in category_stats:
                category_stats[category] = {"count": 0, "total_score": 0, "max_score": 0}
            
            category_stats[category]["count"] += 1
            category_stats[category]["total_score"] += assessment.score
            category_stats[category]["max_score"] += assessment.max_score
    
    # Calculate averages for each category
    for category in category_stats:
        stats = category_stats[category]
        stats["average_percentage"] = (stats["total_score"] / stats["max_score"] * 100) if stats["max_score"] > 0 else 0
    
    return {
        "total_assessments": total_assessments,
        "average_score": round(average_score, 2),
        "total_time_spent": total_time_spent,
        "certifications_earned": certifications_count,
        "category_breakdown": category_stats
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=4004)