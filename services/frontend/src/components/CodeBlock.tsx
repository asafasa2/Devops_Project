import React, { useState } from 'react'

interface CodeBlockProps {
  code: string
  language: string
  title?: string
  explanation?: string
  interactive?: boolean
}

const CodeBlock: React.FC<CodeBlockProps> = ({
  code,
  language,
  title,
  explanation,
  interactive = false
}) => {
  const [copied, setCopied] = useState(false)
  const [userCode, setUserCode] = useState(code)
  const [isEditing, setIsEditing] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(interactive ? userCode : code)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (error) {
      console.error('Failed to copy code:', error)
    }
  }

  const handleReset = () => {
    setUserCode(code)
    setIsEditing(false)
  }

  const getLanguageIcon = (lang: string) => {
    const icons: Record<string, string> = {
      bash: '🐚',
      javascript: '🟨',
      python: '🐍',
      yaml: '📄',
      dockerfile: '🐳',
      terraform: '🏗️',
      json: '📋'
    }
    return icons[lang.toLowerCase()] || '💻'
  }

  return (
    <div className="code-block">
      {title && (
        <div className="code-header">
          <div className="code-title">
            <span className="language-icon">{getLanguageIcon(language)}</span>
            <span className="title-text">{title}</span>
            <span className="language-badge">{language}</span>
          </div>
          <div className="code-actions">
            {interactive && (
              <>
                <button
                  onClick={() => setIsEditing(!isEditing)}
                  className={`edit-button ${isEditing ? 'active' : ''}`}
                  title="Edit code"
                >
                  ✏️
                </button>
                <button
                  onClick={handleReset}
                  className="reset-button"
                  title="Reset to original"
                >
                  🔄
                </button>
              </>
            )}
            <button
              onClick={handleCopy}
              className="copy-button"
              title="Copy to clipboard"
            >
              {copied ? '✅' : '📋'}
            </button>
          </div>
        </div>
      )}
      
      <div className="code-container">
        {interactive && isEditing ? (
          <textarea
            value={userCode}
            onChange={(e) => setUserCode(e.target.value)}
            className="code-editor"
            spellCheck={false}
          />
        ) : (
          <pre className="code-content">
            <code className={`language-${language}`}>
              {interactive ? userCode : code}
            </code>
          </pre>
        )}
      </div>
      
      {explanation && (
        <div className="code-explanation">
          <div className="explanation-header">
            <span className="explanation-icon">💡</span>
            <span className="explanation-title">Explanation</span>
          </div>
          <div className="explanation-content">
            {explanation}
          </div>
        </div>
      )}
      
      {interactive && (
        <div className="interactive-hint">
          <span className="hint-icon">✨</span>
          <span className="hint-text">
            This is an interactive code block. You can edit and experiment with the code!
          </span>
        </div>
      )}
    </div>
  )
}

export default CodeBlock