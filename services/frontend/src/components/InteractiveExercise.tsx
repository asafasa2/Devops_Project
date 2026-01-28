import React, { useState } from 'react'

interface Exercise {
  id: string
  title: string
  description: string
  type: 'code' | 'multiple-choice' | 'fill-blank' | 'command'
  question: string
  options?: string[]
  correctAnswer: string | string[]
  hint?: string
  explanation?: string
}

interface InteractiveExerciseProps {
  exercise: Exercise
  onComplete: () => void
}

const InteractiveExercise: React.FC<InteractiveExerciseProps> = ({
  exercise,
  onComplete
}) => {
  const [userAnswer, setUserAnswer] = useState<string>('')
  const [selectedOptions, setSelectedOptions] = useState<string[]>([])
  const [showHint, setShowHint] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [isCorrect, setIsCorrect] = useState(false)
  const [showExplanation, setShowExplanation] = useState(false)

  const handleSubmit = () => {
    let correct = false
    
    switch (exercise.type) {
      case 'code':
      case 'command':
      case 'fill-blank':
        if (Array.isArray(exercise.correctAnswer)) {
          correct = exercise.correctAnswer.some(answer => 
            userAnswer.trim().toLowerCase() === answer.toLowerCase()
          )
        } else {
          correct = userAnswer.trim().toLowerCase() === exercise.correctAnswer.toLowerCase()
        }
        break
      
      case 'multiple-choice':
        if (Array.isArray(exercise.correctAnswer)) {
          correct = selectedOptions.length === exercise.correctAnswer.length &&
                   selectedOptions.every(option => exercise.correctAnswer.includes(option))
        } else {
          correct = selectedOptions.length === 1 && 
                   selectedOptions[0] === exercise.correctAnswer
        }
        break
    }
    
    setIsCorrect(correct)
    setSubmitted(true)
    setShowExplanation(true)
    
    if (correct) {
      setTimeout(() => {
        onComplete()
      }, 2000)
    }
  }

  const handleReset = () => {
    setUserAnswer('')
    setSelectedOptions([])
    setSubmitted(false)
    setIsCorrect(false)
    setShowExplanation(false)
    setShowHint(false)
  }

  const handleOptionToggle = (option: string) => {
    if (Array.isArray(exercise.correctAnswer)) {
      // Multiple selection
      setSelectedOptions(prev => 
        prev.includes(option) 
          ? prev.filter(o => o !== option)
          : [...prev, option]
      )
    } else {
      // Single selection
      setSelectedOptions([option])
    }
  }

  const renderExerciseInput = () => {
    switch (exercise.type) {
      case 'code':
        return (
          <div className="code-exercise">
            <textarea
              value={userAnswer}
              onChange={(e) => setUserAnswer(e.target.value)}
              placeholder="Write your code here..."
              className="code-input"
              disabled={submitted && isCorrect}
            />
          </div>
        )
      
      case 'command':
        return (
          <div className="command-exercise">
            <div className="terminal-prompt">
              <span className="prompt">$ </span>
              <input
                type="text"
                value={userAnswer}
                onChange={(e) => setUserAnswer(e.target.value)}
                placeholder="Enter command..."
                className="command-input"
                disabled={submitted && isCorrect}
              />
            </div>
          </div>
        )
      
      case 'fill-blank':
        return (
          <div className="fill-blank-exercise">
            <input
              type="text"
              value={userAnswer}
              onChange={(e) => setUserAnswer(e.target.value)}
              placeholder="Fill in the blank..."
              className="blank-input"
              disabled={submitted && isCorrect}
            />
          </div>
        )
      
      case 'multiple-choice':
        return (
          <div className="multiple-choice-exercise">
            {exercise.options?.map((option, index) => (
              <label key={index} className="option-label">
                <input
                  type={Array.isArray(exercise.correctAnswer) ? 'checkbox' : 'radio'}
                  name="exercise-option"
                  checked={selectedOptions.includes(option)}
                  onChange={() => handleOptionToggle(option)}
                  disabled={submitted && isCorrect}
                />
                <span className="option-text">{option}</span>
              </label>
            ))}
          </div>
        )
      
      default:
        return <div>Unsupported exercise type</div>
    }
  }

  return (
    <div className="interactive-exercise">
      <div className="exercise-header">
        <h3>{exercise.title}</h3>
        <div className="exercise-type-badge">
          {exercise.type.replace('-', ' ')}
        </div>
      </div>
      
      <div className="exercise-description">
        {exercise.description}
      </div>
      
      <div className="exercise-question">
        <strong>{exercise.question}</strong>
      </div>
      
      <div className="exercise-input">
        {renderExerciseInput()}
      </div>
      
      <div className="exercise-actions">
        {!submitted ? (
          <>
            <button
              onClick={handleSubmit}
              className="submit-button"
              disabled={
                (exercise.type === 'multiple-choice' && selectedOptions.length === 0) ||
                (exercise.type !== 'multiple-choice' && !userAnswer.trim())
              }
            >
              Submit Answer
            </button>
            {exercise.hint && (
              <button
                onClick={() => setShowHint(!showHint)}
                className="hint-button"
              >
                💡 {showHint ? 'Hide' : 'Show'} Hint
              </button>
            )}
          </>
        ) : (
          <button onClick={handleReset} className="reset-button">
            Try Again
          </button>
        )}
      </div>
      
      {showHint && exercise.hint && (
        <div className="exercise-hint">
          <div className="hint-header">
            <span className="hint-icon">💡</span>
            <span className="hint-title">Hint</span>
          </div>
          <div className="hint-content">{exercise.hint}</div>
        </div>
      )}
      
      {submitted && (
        <div className={`exercise-result ${isCorrect ? 'correct' : 'incorrect'}`}>
          <div className="result-header">
            <span className="result-icon">
              {isCorrect ? '✅' : '❌'}
            </span>
            <span className="result-text">
              {isCorrect ? 'Correct!' : 'Incorrect'}
            </span>
          </div>
          {isCorrect && (
            <div className="success-message">
              Great job! Moving to the next section...
            </div>
          )}
        </div>
      )}
      
      {showExplanation && exercise.explanation && (
        <div className="exercise-explanation">
          <div className="explanation-header">
            <span className="explanation-icon">📚</span>
            <span className="explanation-title">Explanation</span>
          </div>
          <div className="explanation-content">
            {exercise.explanation}
          </div>
        </div>
      )}
    </div>
  )
}

export default InteractiveExercise