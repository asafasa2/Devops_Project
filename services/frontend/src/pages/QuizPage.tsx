import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { learningService } from '../services/learningService'
import { LearningContent } from '../types'
import QuizInterface from '../components/QuizInterface'
import QuizResults from '../components/QuizResults'

interface QuizResult {
  score: number
  maxScore: number
  answers: Record<string, any>
  timeSpent: number
  passed: boolean
}

const QuizPage: React.FC = () => {
  const { quizId } = useParams<{ quizId: string }>()
  const navigate = useNavigate()
  const [quiz, setQuiz] = useState<LearningContent | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [quizStarted, setQuizStarted] = useState(false)
  const [quizCompleted, setQuizCompleted] = useState(false)
  const [quizResult, setQuizResult] = useState<QuizResult | null>(null)
  const [startTime, setStartTime] = useState<Date | null>(null)

  useEffect(() => {
    const fetchQuiz = async () => {
      if (!quizId) return
      
      try {
        setLoading(true)
        const quizData = await learningService.getLearningModule(parseInt(quizId))
        
        if (quizData.content_type !== 'quiz') {
          setError('This content is not a quiz')
          return
        }
        
        setQuiz(quizData)
      } catch (error: any) {
        console.error('Failed to fetch quiz:', error)
        setError('Failed to load quiz')
      } finally {
        setLoading(false)
      }
    }

    fetchQuiz()
  }, [quizId])

  const handleStartQuiz = () => {
    setQuizStarted(true)
    setStartTime(new Date())
  }

  const handleQuizComplete = async (answers: Record<string, any>, score: number, maxScore: number) => {
    const endTime = new Date()
    const timeSpent = startTime ? Math.floor((endTime.getTime() - startTime.getTime()) / 1000) : 0
    const passed = score >= (maxScore * 0.7) // 70% passing grade

    const result: QuizResult = {
      score,
      maxScore,
      answers,
      timeSpent,
      passed
    }

    setQuizResult(result)
    setQuizCompleted(true)

    // Save assessment result
    if (quiz) {
      try {
        await learningService.updateProgress(quiz.id, {
          completed: true,
          score,
          maxScore,
          answers,
          timeSpent,
          passed,
          completedAt: endTime.toISOString()
        })
      } catch (error) {
        console.error('Failed to save quiz result:', error)
      }
    }
  }

  const handleRetakeQuiz = () => {
    setQuizStarted(false)
    setQuizCompleted(false)
    setQuizResult(null)
    setStartTime(null)
  }

  const handleBackToDashboard = () => {
    navigate('/dashboard')
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner">Loading quiz...</div>
      </div>
    )
  }

  if (error || !quiz) {
    return (
      <div className="error-container">
        <div className="error-message">{error || 'Quiz not found'}</div>
        <button onClick={handleBackToDashboard} className="back-button">
          Back to Dashboard
        </button>
      </div>
    )
  }

  return (
    <div className="quiz-page">
      <div className="quiz-header">
        <div className="breadcrumb">
          <span onClick={handleBackToDashboard} className="breadcrumb-link">
            Dashboard
          </span>
          <span className="breadcrumb-separator">›</span>
          <span className="breadcrumb-current">Quiz: {quiz.title}</span>
        </div>
      </div>

      {!quizStarted && !quizCompleted && (
        <div className="quiz-intro">
          <div className="quiz-intro-card">
            <h1>{quiz.title}</h1>
            
            <div className="quiz-meta">
              <div className="meta-item">
                <span className="meta-label">Tool:</span>
                <span className="meta-value">{quiz.tool_category}</span>
              </div>
              <div className="meta-item">
                <span className="meta-label">Difficulty:</span>
                <span className="meta-value">{quiz.difficulty_level}</span>
              </div>
              <div className="meta-item">
                <span className="meta-label">Questions:</span>
                <span className="meta-value">{quiz.content_data?.questions?.length || 0}</span>
              </div>
              <div className="meta-item">
                <span className="meta-label">Time Limit:</span>
                <span className="meta-value">{quiz.estimated_duration} minutes</span>
              </div>
            </div>

            <div className="quiz-description">
              <p>{quiz.content_data?.description || 'Test your knowledge with this quiz.'}</p>
            </div>

            <div className="quiz-instructions">
              <h3>Instructions:</h3>
              <ul>
                <li>Read each question carefully</li>
                <li>Select the best answer for each question</li>
                <li>You can review and change your answers before submitting</li>
                <li>Passing score is 70%</li>
                <li>You can retake the quiz if needed</li>
              </ul>
            </div>

            <button onClick={handleStartQuiz} className="start-quiz-button">
              Start Quiz
            </button>
          </div>
        </div>
      )}

      {quizStarted && !quizCompleted && (
        <QuizInterface
          quiz={quiz}
          onComplete={handleQuizComplete}
          startTime={startTime}
        />
      )}

      {quizCompleted && quizResult && (
        <QuizResults
          quiz={quiz}
          result={quizResult}
          onRetake={handleRetakeQuiz}
          onBackToDashboard={handleBackToDashboard}
        />
      )}
    </div>
  )
}

export default QuizPage