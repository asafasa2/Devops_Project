import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { learningService } from '../services/learningService'
import { LearningContent } from '../types'
import ContentViewer from '../components/ContentViewer'
import ModuleNavigation from '../components/ModuleNavigation'
import NotesPanel from '../components/NotesPanel'
import BookmarkButton from '../components/BookmarkButton'

const LearningModulePage: React.FC = () => {
  const { moduleId } = useParams<{ moduleId: string }>()
  const navigate = useNavigate()
  const [module, setModule] = useState<LearningContent | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [currentSection, setCurrentSection] = useState(0)
  const [showNotes, setShowNotes] = useState(false)
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    const fetchModule = async () => {
      if (!moduleId) return
      
      try {
        setLoading(true)
        const moduleData = await learningService.getLearningModule(parseInt(moduleId))
        setModule(moduleData)
        
        // Calculate progress based on current section
        const totalSections = moduleData.content_data?.sections?.length || 1
        setProgress(Math.round((currentSection / totalSections) * 100))
        
      } catch (error: any) {
        console.error('Failed to fetch module:', error)
        setError('Failed to load learning module')
      } finally {
        setLoading(false)
      }
    }

    fetchModule()
  }, [moduleId])

  useEffect(() => {
    if (module) {
      const totalSections = module.content_data?.sections?.length || 1
      const newProgress = Math.round(((currentSection + 1) / totalSections) * 100)
      setProgress(newProgress)
      
      // Update progress on server
      learningService.updateProgress(module.id, {
        currentSection,
        progress: newProgress,
        lastAccessed: new Date().toISOString()
      }).catch(console.error)
    }
  }, [currentSection, module])

  const handleSectionChange = (sectionIndex: number) => {
    setCurrentSection(sectionIndex)
  }

  const handleComplete = () => {
    if (module) {
      learningService.updateProgress(module.id, {
        completed: true,
        progress: 100,
        completedAt: new Date().toISOString()
      }).then(() => {
        navigate('/dashboard')
      }).catch(console.error)
    }
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner">Loading module...</div>
      </div>
    )
  }

  if (error || !module) {
    return (
      <div className="error-container">
        <div className="error-message">{error || 'Module not found'}</div>
        <button onClick={() => navigate('/dashboard')} className="back-button">
          Back to Dashboard
        </button>
      </div>
    )
  }

  return (
    <div className="learning-module-page">
      <div className="module-header">
        <div className="module-info">
          <div className="breadcrumb">
            <span onClick={() => navigate('/dashboard')} className="breadcrumb-link">
              Dashboard
            </span>
            <span className="breadcrumb-separator">›</span>
            <span className="breadcrumb-current">{module.title}</span>
          </div>
          
          <h1>{module.title}</h1>
          
          <div className="module-meta">
            <span className="tool-badge">{module.tool_category}</span>
            <span className="difficulty-badge">{module.difficulty_level}</span>
            <span className="duration-badge">{module.estimated_duration} min</span>
            <BookmarkButton moduleId={module.id} />
          </div>
          
          <div className="progress-container">
            <div className="progress-bar">
              <div 
                className="progress-fill" 
                style={{ width: `${progress}%` }}
              ></div>
            </div>
            <span className="progress-text">{progress}% Complete</span>
          </div>
        </div>
        
        <div className="module-actions">
          <button 
            onClick={() => setShowNotes(!showNotes)}
            className={`notes-toggle ${showNotes ? 'active' : ''}`}
          >
            📝 Notes
          </button>
        </div>
      </div>

      <div className="module-content">
        <div className="content-area">
          <ContentViewer 
            content={module.content_data}
            currentSection={currentSection}
            onSectionChange={handleSectionChange}
          />
          
          <ModuleNavigation
            sections={module.content_data?.sections || []}
            currentSection={currentSection}
            onSectionChange={handleSectionChange}
            onComplete={handleComplete}
            isLastSection={currentSection === (module.content_data?.sections?.length || 1) - 1}
          />
        </div>
        
        {showNotes && (
          <div className="notes-sidebar">
            <NotesPanel moduleId={module.id} />
          </div>
        )}
      </div>
    </div>
  )
}

export default LearningModulePage