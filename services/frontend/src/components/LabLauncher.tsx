import React, { useState, useEffect } from 'react'
import { labService, LabTemplate } from '../services/labService'
import LabTemplateCard from './LabTemplateCard'

const LabLauncher: React.FC = () => {
  const [templates, setTemplates] = useState<LabTemplate[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filter, setFilter] = useState<'all' | 'docker' | 'ansible' | 'terraform' | 'jenkins'>('all')
  const [difficulty, setDifficulty] = useState<'all' | 'beginner' | 'intermediate' | 'advanced'>('all')

  useEffect(() => {
    const fetchTemplates = async () => {
      try {
        setLoading(true)
        const data = await labService.getLabTemplates()
        setTemplates(data)
      } catch (error: any) {
        console.error('Failed to fetch lab templates:', error)
        setError('Failed to load lab templates')
      } finally {
        setLoading(false)
      }
    }

    fetchTemplates()
  }, [])

  const filteredTemplates = templates.filter(template => {
    const toolMatch = filter === 'all' || template.tool.toLowerCase() === filter
    const difficultyMatch = difficulty === 'all' || template.difficulty === difficulty
    return toolMatch && difficultyMatch
  })

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner">Loading lab templates...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="error-container">
        <div className="error-message">{error}</div>
      </div>
    )
  }

  return (
    <div className="lab-launcher">
      <div className="launcher-header">
        <h2>Choose a Lab Environment</h2>
        <p>Select from our collection of hands-on DevOps lab environments</p>
      </div>

      <div className="lab-filters">
        <div className="filter-group">
          <label>Tool:</label>
          <select value={filter} onChange={(e) => setFilter(e.target.value as any)}>
            <option value="all">All Tools</option>
            <option value="docker">Docker</option>
            <option value="ansible">Ansible</option>
            <option value="terraform">Terraform</option>
            <option value="jenkins">Jenkins</option>
          </select>
        </div>
        
        <div className="filter-group">
          <label>Difficulty:</label>
          <select value={difficulty} onChange={(e) => setDifficulty(e.target.value as any)}>
            <option value="all">All Levels</option>
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
          </select>
        </div>
      </div>

      <div className="templates-grid">
        {filteredTemplates.length === 0 ? (
          <div className="no-templates">
            <p>No lab templates found matching your criteria.</p>
          </div>
        ) : (
          filteredTemplates.map((template) => (
            <LabTemplateCard
              key={template.id}
              template={template}
            />
          ))
        )}
      </div>
    </div>
  )
}

export default LabLauncher