import React from 'react'

interface ModuleNavigationProps {
  sections: any[]
  currentSection: number
  onSectionChange: (sectionIndex: number) => void
  onComplete: () => void
  isLastSection: boolean
}

const ModuleNavigation: React.FC<ModuleNavigationProps> = ({
  sections,
  currentSection,
  onSectionChange,
  onComplete,
  isLastSection
}) => {
  const handlePrevious = () => {
    if (currentSection > 0) {
      onSectionChange(currentSection - 1)
    }
  }

  const handleNext = () => {
    if (currentSection < sections.length - 1) {
      onSectionChange(currentSection + 1)
    }
  }

  return (
    <div className="module-navigation">
      <div className="nav-buttons">
        <button
          onClick={handlePrevious}
          disabled={currentSection === 0}
          className="nav-button prev-button"
        >
          ← Previous
        </button>
        
        <div className="section-dots">
          {sections.map((_, index) => (
            <button
              key={index}
              onClick={() => onSectionChange(index)}
              className={`section-dot ${index === currentSection ? 'active' : ''} ${index < currentSection ? 'completed' : ''}`}
              title={`Section ${index + 1}`}
            />
          ))}
        </div>
        
        {isLastSection ? (
          <button
            onClick={onComplete}
            className="nav-button complete-button"
          >
            Complete Module ✓
          </button>
        ) : (
          <button
            onClick={handleNext}
            disabled={currentSection === sections.length - 1}
            className="nav-button next-button"
          >
            Next →
          </button>
        )}
      </div>
    </div>
  )
}

export default ModuleNavigation