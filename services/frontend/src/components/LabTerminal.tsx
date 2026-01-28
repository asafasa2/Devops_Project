import React, { useState, useEffect, useRef } from 'react'
import { labService } from '../services/labService'

interface LabTerminalProps {
  sessionId: number
}

interface TerminalLine {
  id: string
  type: 'command' | 'output' | 'error'
  content: string
  timestamp: Date
}

const LabTerminal: React.FC<LabTerminalProps> = ({ sessionId }) => {
  const [lines, setLines] = useState<TerminalLine[]>([])
  const [currentCommand, setCurrentCommand] = useState('')
  const [executing, setExecuting] = useState(false)
  const [commandHistory, setCommandHistory] = useState<string[]>([])
  const [historyIndex, setHistoryIndex] = useState(-1)
  const terminalRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    // Add welcome message
    setLines([
      {
        id: 'welcome',
        type: 'output',
        content: 'Welcome to your DevOps Lab Environment!',
        timestamp: new Date()
      },
      {
        id: 'help',
        type: 'output',
        content: 'Type commands to interact with your lab environment. Use "help" for available commands.',
        timestamp: new Date()
      }
    ])
  }, [])

  useEffect(() => {
    // Auto-scroll to bottom when new lines are added
    if (terminalRef.current) {
      terminalRef.current.scrollTop = terminalRef.current.scrollHeight
    }
  }, [lines])

  const addLine = (type: TerminalLine['type'], content: string) => {
    const newLine: TerminalLine = {
      id: Date.now().toString(),
      type,
      content,
      timestamp: new Date()
    }
    setLines(prev => [...prev, newLine])
  }

  const executeCommand = async (command: string) => {
    if (!command.trim()) return

    setExecuting(true)
    addLine('command', `$ ${command}`)

    // Add to command history
    setCommandHistory(prev => [...prev, command])
    setHistoryIndex(-1)

    try {
      // Handle built-in commands
      if (command.trim() === 'clear') {
        setLines([])
        setExecuting(false)
        return
      }

      if (command.trim() === 'help') {
        addLine('output', 'Available commands:')
        addLine('output', '  clear    - Clear the terminal')
        addLine('output', '  help     - Show this help message')
        addLine('output', '  ls       - List directory contents')
        addLine('output', '  pwd      - Show current directory')
        addLine('output', '  docker   - Docker commands')
        addLine('output', '  ansible  - Ansible commands')
        addLine('output', '  terraform - Terraform commands')
        setExecuting(false)
        return
      }

      // Execute command via API
      const result = await labService.executeCommand(sessionId, command)
      
      if (result.output) {
        // Split output into lines and add each one
        const outputLines = result.output.split('\n')
        outputLines.forEach(line => {
          if (line.trim()) {
            addLine('output', line)
          }
        })
      }
    } catch (error: any) {
      console.error('Command execution failed:', error)
      addLine('error', `Error: ${error.response?.data?.message || 'Command execution failed'}`)
    } finally {
      setExecuting(false)
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (currentCommand.trim() && !executing) {
      executeCommand(currentCommand)
      setCurrentCommand('')
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      if (commandHistory.length > 0) {
        const newIndex = historyIndex === -1 ? commandHistory.length - 1 : Math.max(0, historyIndex - 1)
        setHistoryIndex(newIndex)
        setCurrentCommand(commandHistory[newIndex])
      }
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      if (historyIndex !== -1) {
        const newIndex = historyIndex + 1
        if (newIndex >= commandHistory.length) {
          setHistoryIndex(-1)
          setCurrentCommand('')
        } else {
          setHistoryIndex(newIndex)
          setCurrentCommand(commandHistory[newIndex])
        }
      }
    }
  }

  const formatTimestamp = (timestamp: Date) => {
    return timestamp.toLocaleTimeString()
  }

  return (
    <div className="lab-terminal">
      <div className="terminal-header">
        <div className="terminal-title">
          <span className="terminal-icon">🖥️</span>
          Lab Terminal
        </div>
        <div className="terminal-controls">
          <button
            onClick={() => setLines([])}
            className="clear-button"
            title="Clear terminal"
          >
            🗑️
          </button>
        </div>
      </div>

      <div className="terminal-content" ref={terminalRef}>
        <div className="terminal-lines">
          {lines.map((line) => (
            <div key={line.id} className={`terminal-line ${line.type}`}>
              <span className="line-timestamp">{formatTimestamp(line.timestamp)}</span>
              <span className="line-content">{line.content}</span>
            </div>
          ))}
          {executing && (
            <div className="terminal-line executing">
              <span className="line-content">
                <span className="executing-spinner">⏳</span>
                Executing command...
              </span>
            </div>
          )}
        </div>

        <form onSubmit={handleSubmit} className="terminal-input-form">
          <div className="input-line">
            <span className="prompt">$ </span>
            <input
              ref={inputRef}
              type="text"
              value={currentCommand}
              onChange={(e) => setCurrentCommand(e.target.value)}
              onKeyDown={handleKeyDown}
              className="terminal-input"
              placeholder="Enter command..."
              disabled={executing}
              autoFocus
            />
          </div>
        </form>
      </div>

      <div className="terminal-footer">
        <div className="terminal-info">
          <span>Session ID: {sessionId}</span>
          <span>Use ↑/↓ arrows for command history</span>
        </div>
      </div>
    </div>
  )
}

export default LabTerminal