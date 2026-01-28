import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { labService, LabTemplate } from '../services/labService'

interface LabTemplateCardProps {
  template: LabTemplate
}

const LabTemplateCard: React.FC<LabTemplateCardProps> = ({ template }) => {
  const navigate = useNavigate()
  const [launching, setLaunching] = useState(false)

  const handleLaunchLab = async () => {
    try {
      setLaunching(true)
      const session = await labService.createLabSession({
        templateId: template.id,
        name: `${template.name} - ${new Date().toLocaleString()}`
      })
      
      // Navigate to the lab session
      navigate(`/labs/sessions/${session.id}`)
    } catch (error: any) {
      console.error('Failed to launch lab:', error)
      alert('Failed to launch lab. Please try again.')
    } finally {
      setLaunching(false)
    }
  }

  const getDifficultyColor = (level: string) => {
    switch (level) {
      case 'beginner': return '#4caf50'
      case 'intermediate': return '#ff9800'
      case 'advanced': return '#f44336'
      default: return '#1976d2'
    }
  }

  const getToolIcon = (tool: string) => {
    const icons: Record<string, string> = {
      docker: '🐳',
      ansible: '🔧',
      terraform: '🏗️',
      jenkins: '🚀',
      kubernetes: '☸️',
      git: '📚'
    }
    return icons[tool.toLowerCase()] || '💻'
  }

  return (
    <div className="lab-template-card">
      <div className="card-header">
        <div className="tool-info">
          <span className="tool-icon">{getToolIcon(template.tool)}</span>
          <span className="tool-name">{template.tool}</span>
        </div>
        <div 
          className="difficulty-badge"
          style={{ backgroundColor: getDifficultyColor(template.difficulty) }}
        >
          {template.difficulty}
        </div>
      </div>

      <div className="card-content">
        <h3 className="template-name">{template.name}</h3>
        <p className="template-description">{template.description}</p>

        <div className="template-meta">
          <div className="meta-item">
            <span className="meta-icon">⏱️</span>
            <span className="meta-text">{template.estimatedTime} min</span>
          </div>
          <div className="meta-item">
            <span className="meta-icon">🔌</span>
            <span className="meta-text">{template.ports.length} ports</span>
          </div>
        </div>

        <div className="template-features">
          <h4>What you'll practice:</h4>
          <div className="features-list">
            {template.instructions.split('\n').slice(0, 3).map((instruction, index) => (
              <div key={index} className="feature-item">
                <span className="feature-bullet">•</span>
                <span className="feature-text">{instruction.replace(/^\d+\.\s*/, '')}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="card-actions">
        <button
          onClick={handleLaunchLab}
          disabled={launching}
          className="launch-button"
        >
          {launching ? (
            <>
              <span className="loading-spinner-small">⏳</span>
              Launching...
            </>
          ) : (
            <>
              <span className="launch-icon">🚀</span>
              Launch Lab
            </>
          )}
        </button>
      </div>
    </div>
  )
}

export default LabTemplateCard