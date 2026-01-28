import React from 'react'
import { LearningContent } from '../types'

interface QuizResult {
  score: number
  maxScore: number
  answers: Record<string, any>
  timeSpent: number
  passed: boolean
}

interface QuizResultsProps {
  quiz: LearningContent
  result: QuizResult
  onRetake: () => void
  onBackToDashboard: () => void
}

const QuizResults: React.FC<QuizResultsProps> = ({
  quiz,
  result,
  onRetake,
  onBackToDashboard
}) => {
  const percentage = Math.round((result.score / result.maxScore) * 100)
  const questions = quiz.content_data?.questions || []
  
  const formatTime = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes}m ${remainingSeconds}s`
  }

  const getGradeColor = (percentage: number): string => {
    if (percentage >= 90) return '#4caf50' // Green
    if (percentage >= 80) return '#8bc34a' // Light green
    if (percentage >= 70) return '#ff9800' // Orange
    if (percentage >= 60) return '#ff5722' // Red-orange
    return '#f44336' // Red
  }

  const getGradeLetter = (percentage: number): string => {
    if (percentage >= 90) return 'A'
    if (percentage >= 80) return 'B'
    if (percentage >= 70) return 'C'
    if (percentage >= 60) return 'D'
    return 'F'
  }

  const getPerformanceMessage = (percentage: number): string => {
    if (percentage >= 90) return 'Excellent work! You have mastered this topic.'
    if (percentage >= 80) return 'Great job! You have a solid understanding.'
    if (percentage >= 70) return 'Good work! You passed the quiz.'
    if (percentage >= 60) return 'You passed, but consider reviewing the material.'
    return 'You did not pass. Please review the material and try again.'
  }

  return (
    <div className="quiz-results">
      <div className="results-container">
        <div className="results-header">
          <div className={`results-status ${result.passed ? 'passed' : 'failed'}`}>
            <div className="status-icon">
              {result.passed ? '🎉' : '📚'}
            </div>
            <div className="status-text">
              {result.passed ? 'Quiz Passed!' : 'Quiz Not Passed'}
            </div>
          </div>
          
          <h2>{quiz.title}</h2>
        </div>

        <div className="results-summary">
          <div className="score-display">
            <div className="score-circle" style={{ borderColor: getGradeColor(percentage) }}>
              <div className="score-percentage" style={{ color: getGradeColor(percentage) }}>
                {percentage}%
              </div>
              <div className="score-grade" style={{ color: getGradeColor(percentage) }}>
                {getGradeLetter(percentage)}
              </div>
            </div>
            
            <div className="score-details">
              <div className="score-fraction">
                {result.score} / {result.maxScore} points
              </div>
              <div className="performance-message">
                {getPerformanceMessage(percentage)}
              </div>
            </div>
          </div>

          <div className="results-stats">
            <div className="stat-item">
              <div className="stat-label">Questions</div>
              <div className="stat-value">{questions.length}</div>
            </div>
            <div className="stat-item">
              <div className="stat-label">Time Spent</div>
              <div className="stat-value">{formatTime(result.timeSpent)}</div>
            </div>
            <div className="stat-item">
              <div className="stat-label">Passing Score</div>
              <div className="stat-value">70%</div>
            </div>
          </div>
        </div>

        <div className="results-breakdown">
          <h3>Question Breakdown</h3>
          <div className="questions-list">
            {questions.map((question: any, index: number) => {
              const userAnswer = result.answers[question.id]
              const isCorrect = isAnswerCorrect(question, userAnswer)
              
              return (
                <div key={question.id} className={`question-result ${isCorrect ? 'correct' : 'incorrect'}`}>
                  <div className="question-header">
                    <div className="question-number">Q{index + 1}</div>
                    <div className="question-status">
                      {isCorrect ? '✅' : '❌'}
                    </div>
                    <div className="question-points">
                      {isCorrect ? question.points : 0} / {question.points} pts
                    </div>
                  </div>
                  
                  <div className="question-text">{question.question}</div>
                  
                  <div className="answer-comparison">
                    <div className="user-answer">
                      <strong>Your Answer:</strong> {formatAnswer(userAnswer)}
                    </div>
                    <div className="correct-answer">
                      <strong>Correct Answer:</strong> {formatAnswer(question.correctAnswer)}
                    </div>
                  </div>
                  
                  {question.explanation && (
                    <div className="question-explanation">
                      <strong>Explanation:</strong> {question.explanation}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        </div>

        <div className="results-actions">
          <button onClick={onBackToDashboard} className="dashboard-button">
            Back to Dashboard
          </button>
          <button onClick={onRetake} className="retake-button">
            Retake Quiz
          </button>
        </div>
      </div>
    </div>
  )
}

const isAnswerCorrect = (question: any, userAnswer: any): boolean => {
  if (Array.isArray(question.correctAnswer)) {
    if (Array.isArray(userAnswer)) {
      return question.correctAnswer.length === userAnswer.length &&
             question.correctAnswer.every((answer: any) => userAnswer.includes(answer))
    }
    return question.correctAnswer.includes(userAnswer)
  }
  
  if (typeof question.correctAnswer === 'string' && typeof userAnswer === 'string') {
    return question.correctAnswer.toLowerCase().trim() === userAnswer.toLowerCase().trim()
  }
  
  return question.correctAnswer === userAnswer
}

const formatAnswer = (answer: any): string => {
  if (Array.isArray(answer)) {
    return answer.join(', ')
  }
  if (answer === null || answer === undefined || answer === '') {
    return 'No answer provided'
  }
  return String(answer)
}

export default QuizResults