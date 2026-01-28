import React from 'react'
import { Link } from 'react-router-dom'
import { LearningContent } from '../types'

interface RecommendationCardProps {
  content: LearningContent
  reason?: string
}

const RecommendationCard: React.FC<RecommendationCardProps> = ({ content, reason }) => {
  const getContentTypeIcon = (type: string) => {
    switch (type) {
      case 'module': return '📚'
      case 'quiz': return '❓'
      case 'lab': return '🧪'
      default: return '📄'
    }
  }

  return (
    <div className="recommendation-card">
      <div className="recommendation-header">
        <span className="content-type-icon">
          {getContentTypeIcon(content.content_type)}
        </span>
        <div className="content-info">
          <h4>{content.title}</h4>
          <div className="content-meta">
            <span className="tool-tag">{content.tool_category}</span>
            <span className="difficulty-tag">{content.difficulty_level}</span>
            <span className="duration-tag">{content.estimated_duration} min</span>
          </div>
        </div>
      </div>
      
      {reason && (
        <div className="recommendation-reason">
          <span className="reason-label">Recommended because:</span>
          <span className="reason-text">{reason}</span>
        </div>
      )}
      
      <div className="recommendation-actions">
        <Link 
          to={`/learning/modules/${content.id}`} 
          className="recommendation-button"
        >
          Start Now
        </Link>
      </div>
    </div>
  )
}

export default RecommendationCard