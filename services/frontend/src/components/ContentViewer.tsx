import React from 'react'
import CodeBlock from './CodeBlock'
import InteractiveExercise from './InteractiveExercise'

interface ContentSection {
  id: string
  title: string
  type: 'text' | 'code' | 'exercise' | 'video' | 'image'
  content: any
}

interface ContentViewerProps {
  content: {
    sections?: ContentSection[]
  }
  currentSection: number
  onSectionChange: (sectionIndex: number) => void
}

const ContentViewer: React.FC<ContentViewerProps> = ({
  content,
  currentSection,
  onSectionChange
}) => {
  if (!content?.sections || content.sections.length === 0) {
    return (
      <div className="content-viewer">
        <div className="no-content">
          <p>No content available for this module.</p>
        </div>
      </div>
    )
  }

  const section = content.sections[currentSection]

  const renderSectionContent = (section: ContentSection) => {
    switch (section.type) {
      case 'text':
        return (
          <div className="text-content">
            <h2>{section.title}</h2>
            <div 
              className="content-body"
              dangerouslySetInnerHTML={{ __html: section.content.html || section.content }}
            />
          </div>
        )
      
      case 'code':
        return (
          <div className="code-content">
            <h2>{section.title}</h2>
            <div className="content-description">
              {section.content.description && (
                <p>{section.content.description}</p>
              )}
            </div>
            <CodeBlock
              code={section.content.code}
              language={section.content.language || 'bash'}
              title={section.content.title}
              explanation={section.content.explanation}
              interactive={section.content.interactive}
            />
          </div>
        )
      
      case 'exercise':
        return (
          <div className="exercise-content">
            <h2>{section.title}</h2>
            <InteractiveExercise
              exercise={section.content}
              onComplete={() => {
                // Move to next section when exercise is completed
                if (content.sections && currentSection < content.sections.length - 1) {
                  onSectionChange(currentSection + 1)
                }
              }}
            />
          </div>
        )
      
      case 'video':
        return (
          <div className="video-content">
            <h2>{section.title}</h2>
            <div className="video-container">
              <video 
                controls 
                width="100%" 
                height="400"
                poster={section.content.poster}
              >
                <source src={section.content.url} type="video/mp4" />
                Your browser does not support the video tag.
              </video>
            </div>
            {section.content.description && (
              <div className="video-description">
                <p>{section.content.description}</p>
              </div>
            )}
          </div>
        )
      
      case 'image':
        return (
          <div className="image-content">
            <h2>{section.title}</h2>
            <div className="image-container">
              <img 
                src={section.content.url} 
                alt={section.content.alt || section.title}
                className="content-image"
              />
            </div>
            {section.content.caption && (
              <div className="image-caption">
                <p>{section.content.caption}</p>
              </div>
            )}
          </div>
        )
      
      default:
        return (
          <div className="unknown-content">
            <h2>{section.title}</h2>
            <p>Unsupported content type: {section.type}</p>
          </div>
        )
    }
  }

  return (
    <div className="content-viewer">
      <div className="section-content">
        {renderSectionContent(section)}
      </div>
      
      <div className="section-progress">
        <span className="section-indicator">
          Section {currentSection + 1} of {content.sections.length}
        </span>
      </div>
    </div>
  )
}

export default ContentViewer