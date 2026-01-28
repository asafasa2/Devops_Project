import React, { useState, useEffect } from 'react'
import { LearningContent } from '../types'
import QuizQuestion from './QuizQuestion'
import QuizTimer from './QuizTimer'

interface QuizInterfaceProps {
  quiz: LearningContent
  onComplete: (answers: Record<string, any>, score: number, maxScore: number) => void
  startTime: Date | null
}

interface Question {
  id: string
  type: 'multiple-choice' | 'true-false' | 'fill-blank' | 'code'
  question: string
  options?: string[]
  correctAnswer: string | string[]
  points: number
  explanation?: string
}

const QuizInterface: React.FC<QuizInterfaceProps> = ({
  quiz,
  onComplete,
  startTime
}) => {
  const [currentQuestion, setCurrentQuestion] = useState(0)
  const [answers, setAnswers] = useState<Record<string, any>>({})
  const [showReview, setShowReview] = useState(false)
  const [timeUp, setTimeUp] = useState(false)

  const questions: Question[] = quiz.content_data?.questions || []
  const totalQuestions = questions.length
  const timeLimit = quiz.estimated_duration * 60 // Convert minutes to seconds

  useEffect(() => {
    if (timeUp) {
      handleSubmitQuiz()
    }
  }, [timeUp])

  const handleAnswerChange = (questionId: string, answer: any) => {
    setAnswers(prev => ({
      ...prev,
      [questionId]: answer
    }))
  }

  const handleNextQuestion = () => {
    if (currentQuestion < totalQuestions - 1) {
      setCurrentQuestion(currentQuestion + 1)
    }
  }

  const handlePreviousQuestion = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(currentQuestion - 1)
    }
  }

  const handleGoToQuestion = (questionIndex: number) => {
    setCurrentQuestion(questionIndex)
  }

  const handleReviewQuiz = () => {
    setShowReview(true)
  }

  const handleSubmitQuiz = () => {
    const { score, maxScore } = calculateScore()
    onComplete(answers, score, maxScore)
  }

  const calculateScore = () => {
    let score = 0
    let maxScore = 0

    questions.forEach(question => {
      maxScore += question.points
      const userAnswer = answers[question.id]
      
      if (userAnswer !== undefined && userAnswer !== null && userAnswer !== '') {
        if (isAnswerCorrect(question, userAnswer)) {
          score += question.points
        }
      }
    })

    return { score, maxScore }
  }

  const isAnswerCorrect = (question: Question, userAnswer: any): boolean => {
    if (Array.isArray(question.correctAnswer)) {
      if (Array.isArray(userAnswer)) {
        return question.correctAnswer.length === userAnswer.length &&
               question.correctAnswer.every(answer => userAnswer.includes(answer))
      }
      return question.correctAnswer.includes(userAnswer)
    }
    
    if (typeof question.correctAnswer === 'string' && typeof userAnswer === 'string') {
      return question.correctAnswer.toLowerCase().trim() === userAnswer.toLowerCase().trim()
    }
    
    return question.correctAnswer === userAnswer
  }

  const getAnsweredCount = () => {
    return Object.keys(answers).filter(key => 
      answers[key] !== undefined && answers[key] !== null && answers[key] !== ''
    ).length
  }

  if (showReview) {
    return (
      <div className="quiz-review">
        <div className="quiz-container">
          <div className="quiz-header-section">
            <h2>Review Your Answers</h2>
            <div className="quiz-progress">
              <span>Answered: {getAnsweredCount()} / {totalQuestions}</span>
            </div>
          </div>

          <div className="review-grid">
            {questions.map((question, index) => (
              <div 
                key={question.id} 
                className={`review-item ${answers[question.id] ? 'answered' : 'unanswered'}`}
                onClick={() => {
                  setShowReview(false)
                  setCurrentQuestion(index)
                }}
              >
                <div className="review-number">Q{index + 1}</div>
                <div className="review-status">
                  {answers[question.id] ? '✓' : '○'}
                </div>
              </div>
            ))}
          </div>

          <div className="review-actions">
            <button 
              onClick={() => setShowReview(false)} 
              className="back-to-quiz-button"
            >
              Back to Quiz
            </button>
            <button 
              onClick={handleSubmitQuiz} 
              className="submit-quiz-button"
            >
              Submit Quiz
            </button>
          </div>
        </div>
      </div>
    )
  }

  if (totalQuestions === 0) {
    return (
      <div className="quiz-error">
        <p>No questions found in this quiz.</p>
      </div>
    )
  }

  const currentQ = questions[currentQuestion]

  return (
    <div className="quiz-interface">
      <div className="quiz-container">
        <div className="quiz-header-section">
          <div className="quiz-progress-bar">
            <div className="progress-info">
              <span>Question {currentQuestion + 1} of {totalQuestions}</span>
              <span>Answered: {getAnsweredCount()}</span>
            </div>
            <div className="progress-bar">
              <div 
                className="progress-fill" 
                style={{ width: `${((currentQuestion + 1) / totalQuestions) * 100}%` }}
              />
            </div>
          </div>

          <QuizTimer
            timeLimit={timeLimit}
            startTime={startTime}
            onTimeUp={() => setTimeUp(true)}
          />
        </div>

        <div className="quiz-content">
          <QuizQuestion
            question={currentQ}
            answer={answers[currentQ.id]}
            onAnswerChange={(answer) => handleAnswerChange(currentQ.id, answer)}
            questionNumber={currentQuestion + 1}
          />
        </div>

        <div className="quiz-navigation">
          <div className="nav-buttons">
            <button
              onClick={handlePreviousQuestion}
              disabled={currentQuestion === 0}
              className="nav-button prev-button"
            >
              ← Previous
            </button>

            <button
              onClick={handleReviewQuiz}
              className="review-button"
            >
              Review ({getAnsweredCount()}/{totalQuestions})
            </button>

            {currentQuestion === totalQuestions - 1 ? (
              <button
                onClick={handleSubmitQuiz}
                className="nav-button submit-button"
              >
                Submit Quiz
              </button>
            ) : (
              <button
                onClick={handleNextQuestion}
                className="nav-button next-button"
              >
                Next →
              </button>
            )}
          </div>

          <div className="question-dots">
            {questions.map((_, index) => (
              <button
                key={index}
                onClick={() => handleGoToQuestion(index)}
                className={`question-dot ${index === currentQuestion ? 'active' : ''} ${answers[questions[index].id] ? 'answered' : ''}`}
                title={`Question ${index + 1}`}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default QuizInterface