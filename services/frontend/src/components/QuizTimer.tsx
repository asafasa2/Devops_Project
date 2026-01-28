import React, { useState, useEffect } from 'react'

interface QuizTimerProps {
  timeLimit: number // in seconds
  startTime: Date | null
  onTimeUp: () => void
}

const QuizTimer: React.FC<QuizTimerProps> = ({
  timeLimit,
  startTime,
  onTimeUp
}) => {
  const [timeRemaining, setTimeRemaining] = useState(timeLimit)
  const [isWarning, setIsWarning] = useState(false)

  useEffect(() => {
    if (!startTime) return

    const interval = setInterval(() => {
      const now = new Date()
      const elapsed = Math.floor((now.getTime() - startTime.getTime()) / 1000)
      const remaining = Math.max(0, timeLimit - elapsed)
      
      setTimeRemaining(remaining)
      
      // Warning when 5 minutes or less remaining
      setIsWarning(remaining <= 300 && remaining > 0)
      
      if (remaining === 0) {
        clearInterval(interval)
        onTimeUp()
      }
    }, 1000)

    return () => clearInterval(interval)
  }, [startTime, timeLimit, onTimeUp])

  const formatTime = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
  }

  const getProgressPercentage = (): number => {
    return ((timeLimit - timeRemaining) / timeLimit) * 100
  }

  return (
    <div className={`quiz-timer ${isWarning ? 'warning' : ''}`}>
      <div className="timer-label">Time Remaining</div>
      <div className="timer-display">
        {formatTime(timeRemaining)}
      </div>
      <div className="timer-progress">
        <div 
          className="timer-progress-bar"
          style={{ width: `${getProgressPercentage()}%` }}
        />
      </div>
      {isWarning && (
        <div className="timer-warning">
          ⚠️ Less than 5 minutes remaining!
        </div>
      )}
    </div>
  )
}

export default QuizTimer