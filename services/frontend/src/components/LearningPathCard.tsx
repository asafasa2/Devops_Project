import React from 'react'
import { Link } from 'react-router-dom'

interface LearningPathCardProps {
  id: number
  title: string
  description: string
  tool: string
  difficulty: string
  progress: number
  estimatedTime: number
  isCompleted: boolean
}

const LearningPathCard: React.FC<LearningPathCardProps> = ({
  id,
  title,
  description,
  tool,
  difficulty,
  progress,
  estimatedTime,
  isCompleted
}) => {
  const getDifficultyColor = (level: string) => {
    switch (level.toLowerCase()) {
      case 'beginner': return '#4caf50'
      case 'intermediate': return '#ff9800'
      case 'advanced': return '#f44336'
      default: return '#1976d2'
    }
  }

  return (
    <div className={`learning-path-card ${isCompleted ? 'completed' : ''}`}>
      <div className="card-header">
        <div className="tool-badge" style={{ backgroundColor: getDifficultyColor(difficulty) }}>
          {tool.toUpperCase()}
        </div>
        <div className="difficulty-badge">
          {difficulty}
        </div>
      </div>
      
      <div className="card-content">
        <h3 className="card-title">{title}</h3>
        <p className="card-description">{description}</p>
        
        <div className="card-meta">
          <span className="estimated-time">
            ⏱️ {estimatedTime} min
          </span>
          {isCompleted && (
            <span className="completion-badge">
              ✅ Completed
            </span>
          )}
        </div>
        
        <div className="progress-section">
          <div className="progress-bar">
            <div 
              className="progress-fill" 
              style={{ width: `${progress}%` }}
            ></div>
          </div>
          <span className="progress-text">{progress}% Complete</span>
        </div>
      </div>
      
      <div className="card-actions">
        <Link 
          to={`/learning/modules/${id}`} 
          className={`action-button ${progress > 0 ? 'continue' : 'start'}`}
        >
          {progress > 0 ? 'Continue' : 'Start Learning'}
        </Link>
      </div>
    </div>
  )
}

export default LearningPathCard