import React from 'react'

interface Question {
  id: string
  type: 'multiple-choice' | 'true-false' | 'fill-blank' | 'code'
  question: string
  options?: string[]
  correctAnswer: string | string[]
  points: number
  explanation?: string
}

interface QuizQuestionProps {
  question: Question
  answer: any
  onAnswerChange: (answer: any) => void
  questionNumber: number
}

const QuizQuestion: React.FC<QuizQuestionProps> = ({
  question,
  answer,
  onAnswerChange,
  questionNumber
}) => {
  const handleMultipleChoiceChange = (selectedOption: string) => {
    if (Array.isArray(question.correctAnswer)) {
      // Multiple selection
      const currentAnswers = Array.isArray(answer) ? answer : []
      if (currentAnswers.includes(selectedOption)) {
        onAnswerChange(currentAnswers.filter(a => a !== selectedOption))
      } else {
        onAnswerChange([...currentAnswers, selectedOption])
      }
    } else {
      // Single selection
      onAnswerChange(selectedOption)
    }
  }

  const renderQuestionContent = () => {
    switch (question.type) {
      case 'multiple-choice':
        return (
          <div className="multiple-choice-question">
            <div className="options-list">
              {question.options?.map((option, index) => (
                <label key={index} className="option-item">
                  <input
                    type={Array.isArray(question.correctAnswer) ? 'checkbox' : 'radio'}
                    name={`question-${question.id}`}
                    checked={
                      Array.isArray(answer) 
                        ? answer.includes(option)
                        : answer === option
                    }
                    onChange={() => handleMultipleChoiceChange(option)}
                  />
                  <span className="option-text">{option}</span>
                </label>
              ))}
            </div>
          </div>
        )
      
      case 'true-false':
        return (
          <div className="true-false-question">
            <div className="tf-options">
              <label className="tf-option">
                <input
                  type="radio"
                  name={`question-${question.id}`}
                  checked={answer === 'true'}
                  onChange={() => onAnswerChange('true')}
                />
                <span className="tf-text">True</span>
              </label>
              <label className="tf-option">
                <input
                  type="radio"
                  name={`question-${question.id}`}
                  checked={answer === 'false'}
                  onChange={() => onAnswerChange('false')}
                />
                <span className="tf-text">False</span>
              </label>
            </div>
          </div>
        )
      
      case 'fill-blank':
        return (
          <div className="fill-blank-question">
            <input
              type="text"
              value={answer || ''}
              onChange={(e) => onAnswerChange(e.target.value)}
              placeholder="Enter your answer..."
              className="blank-input"
            />
          </div>
        )
      
      case 'code':
        return (
          <div className="code-question">
            <textarea
              value={answer || ''}
              onChange={(e) => onAnswerChange(e.target.value)}
              placeholder="Write your code here..."
              className="code-textarea"
              rows={8}
            />
          </div>
        )
      
      default:
        return <div>Unsupported question type</div>
    }
  }

  return (
    <div className="quiz-question">
      <div className="question-header">
        <div className="question-number">Question {questionNumber}</div>
        <div className="question-points">{question.points} point{question.points !== 1 ? 's' : ''}</div>
      </div>
      
      <div className="question-text">
        {question.question}
      </div>
      
      <div className="question-content">
        {renderQuestionContent()}
      </div>
      
      {Array.isArray(question.correctAnswer) && question.type === 'multiple-choice' && (
        <div className="multiple-select-hint">
          <span className="hint-icon">💡</span>
          <span className="hint-text">Select all that apply</span>
        </div>
      )}
    </div>
  )
}

export default QuizQuestion