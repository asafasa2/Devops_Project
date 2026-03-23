import React, { useState, useRef, useCallback, useEffect } from 'react'
import Terminal from './Terminal'
import CodeEditor from './CodeEditor'
import { useToast } from '../contexts/ToastContext'

interface ValidationStepResult {
  command: string
  passed: boolean
  exit_code: number
  hint?: string
}

interface ValidationResult {
  session_id: string
  lab_id: string
  all_passed: boolean
  results: ValidationStepResult[]
}

interface LabSession {
  session_id: string
  lab_id: string
  status: string
  ttyd_url: string
  ttyd_port: number
  instructions: string
  objectives: string[]
  title: string
  editor_enabled?: boolean
  editor_default_path?: string
}

interface LabPanelProps {
  session: LabSession
  onLabStop: () => void
  onValidate: () => Promise<ValidationResult>
}

function renderMarkdown(text: string): React.ReactNode[] {
  const lines = text.split('\n')
  const nodes: React.ReactNode[] = []
  let i = 0

  while (i < lines.length) {
    const line = lines[i]

    if (line.startsWith('### ')) {
      nodes.push(<h3 key={i} className="text-blue-300 mt-3 mb-1 text-sm font-semibold">{line.slice(4)}</h3>)
    } else if (line.startsWith('## ')) {
      nodes.push(<h2 key={i} className="text-cyan-300 mt-4 mb-1.5 text-base font-semibold">{line.slice(3)}</h2>)
    } else if (line.startsWith('# ')) {
      nodes.push(<h1 key={i} className="text-cyan-200 mt-5 mb-2 text-lg font-bold">{line.slice(2)}</h1>)
    } else if (line.startsWith('```')) {
      const codeLines: string[] = []
      i++
      while (i < lines.length && !lines[i].startsWith('```')) {
        codeLines.push(lines[i])
        i++
      }
      nodes.push(
        <pre key={`code-${i}`} className="bg-slate-900 text-slate-200 px-3 py-2 rounded overflow-x-auto my-1.5 text-xs">
          <code>{codeLines.join('\n')}</code>
        </pre>
      )
    } else if (/^\s*-\s/.test(line)) {
      nodes.push(
        <li key={i} className="ml-5 mb-0.5 text-slate-300">
          {line.replace(/^\s*-\s/, '')}
        </li>
      )
    } else if (line.trim() === '') {
      nodes.push(<br key={i} />)
    } else {
      const parts = line.split(/(\*\*[^*]+\*\*|`[^`]+`)/g)
      nodes.push(
        <p key={i} className="my-1 text-slate-300">
          {parts.map((part, j) => {
            if (part.startsWith('**') && part.endsWith('**')) {
              return <strong key={j} className="text-slate-100">{part.slice(2, -2)}</strong>
            }
            if (part.startsWith('`') && part.endsWith('`')) {
              return (
                <code key={j} className="bg-slate-700 px-1 py-0.5 rounded text-xs text-slate-200">
                  {part.slice(1, -1)}
                </code>
              )
            }
            return part
          })}
        </p>
      )
    }
    i++
  }
  return nodes
}

// Draggable divider component
function PanelDivider({ onDrag }: { onDrag: (deltaX: number) => void }) {
  const dragging = useRef(false)
  const lastX = useRef(0)

  const onMouseDown = useCallback((e: React.MouseEvent) => {
    dragging.current = true
    lastX.current = e.clientX
    e.preventDefault()

    const onMouseMove = (e: MouseEvent) => {
      if (!dragging.current) return
      const delta = e.clientX - lastX.current
      lastX.current = e.clientX
      onDrag(delta)
    }

    const onMouseUp = () => {
      dragging.current = false
      document.removeEventListener('mousemove', onMouseMove)
      document.removeEventListener('mouseup', onMouseUp)
    }

    document.addEventListener('mousemove', onMouseMove)
    document.addEventListener('mouseup', onMouseUp)
  }, [onDrag])

  return (
    <div
      onMouseDown={onMouseDown}
      className="w-1 bg-slate-700 hover:bg-blue-500/50 cursor-col-resize shrink-0 transition-colors"
    />
  )
}

const LabPanel: React.FC<LabPanelProps> = ({ session, onLabStop, onValidate }) => {
  const { addToast } = useToast()
  const [validating, setValidating] = useState(false)
  const [validationResult, setValidationResult] = useState<ValidationResult | null>(null)
  const containerRef = useRef<HTMLDivElement>(null)

  const hasEditor = session.editor_enabled ?? false

  // Panel widths as percentages
  const [panelWidths, setPanelWidths] = useState(
    hasEditor ? [30, 35, 35] : [40, 0, 60]
  )

  useEffect(() => {
    setPanelWidths(hasEditor ? [30, 35, 35] : [40, 0, 60])
  }, [hasEditor])

  const handleDrag = useCallback((dividerIndex: number, deltaX: number) => {
    if (!containerRef.current) return
    const totalWidth = containerRef.current.clientWidth
    const deltaPct = (deltaX / totalWidth) * 100

    setPanelWidths(prev => {
      const next = [...prev]
      next[dividerIndex] = Math.max(15, next[dividerIndex] + deltaPct)
      next[dividerIndex + 1] = Math.max(15, next[dividerIndex + 1] - deltaPct)
      return next
    })
  }, [])

  const handleValidate = async () => {
    setValidating(true)
    try {
      const result = await onValidate()
      setValidationResult(result)
      if (result.all_passed) {
        addToast('All checks passed!', 'success')
      } else {
        addToast('Some checks failed', 'error')
      }
    } catch (err) {
      console.error('Validation failed:', err)
      addToast('Validation failed', 'error')
    } finally {
      setValidating(false)
    }
  }

  return (
    <div ref={containerRef} className="flex h-[calc(100vh-48px)]">
      {/* Instructions panel */}
      <div className="bg-slate-900 flex flex-col overflow-hidden" style={{ width: `${panelWidths[0]}%` }}>
        <div className="flex-1 overflow-y-auto p-4 text-sm">
          <h2 className="gradient-text font-bold text-base mb-3">{session.title}</h2>

          <div className="glass-card rounded-lg p-3 mb-4">
            <h3 className="text-green-400 font-semibold text-xs uppercase tracking-wide mb-2">Objectives</h3>
            <ol className="list-decimal list-inside space-y-1">
              {session.objectives.map((obj, i) => (
                <li key={i} className="text-slate-300 text-sm">{obj}</li>
              ))}
            </ol>
          </div>

          <div className="leading-relaxed">
            {renderMarkdown(session.instructions)}
          </div>
        </div>

        <div className="shrink-0 p-4 border-t border-slate-700/50">
          <button
            onClick={handleValidate}
            disabled={validating}
            className="w-full py-2.5 bg-emerald-600/80 hover:bg-emerald-500 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg font-medium text-sm transition-all"
          >
            {validating ? 'Validating…' : 'Validate'}
          </button>

          {validationResult && (
            <div className="mt-3 space-y-1.5">
              <div className={`px-3 py-2 rounded-lg font-semibold text-sm ${
                validationResult.all_passed
                  ? 'bg-green-950/60 text-green-300 border border-green-800/50'
                  : 'bg-red-950/60 text-red-300 border border-red-800/50'
              }`}>
                {validationResult.all_passed ? '✓ All checks passed!' : '✗ Some checks failed'}
              </div>
              {validationResult.results.map((r, i) => (
                <div
                  key={i}
                  className={`px-3 py-2 rounded text-xs ${
                    r.passed
                      ? 'border-l-4 border-green-500 bg-green-950/30'
                      : 'border-l-4 border-red-500 bg-red-950/30'
                  }`}
                >
                  <span className="mr-2">{r.passed ? '✓' : '✗'}</span>
                  <code className="text-slate-200">{r.command}</code>
                  {!r.passed && r.hint && (
                    <div className="text-red-300 mt-1">Hint: {r.hint}</div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <PanelDivider onDrag={(dx) => handleDrag(0, dx)} />

      {/* Editor panel (conditional) */}
      {hasEditor && (
        <>
          <div style={{ width: `${panelWidths[1]}%` }} className="overflow-hidden">
            <CodeEditor
              sessionId={session.session_id}
              defaultPath={session.editor_default_path || '/workspace'}
            />
          </div>
          <PanelDivider onDrag={(dx) => handleDrag(1, dx)} />
        </>
      )}

      {/* Terminal panel */}
      <div className="flex flex-col bg-slate-950" style={{ width: `${hasEditor ? panelWidths[2] : panelWidths[2]}%` }}>
        <div className="bg-slate-900 border-b border-slate-700/50 px-4 py-1.5 flex justify-between items-center shrink-0">
          <span className="text-slate-500 text-xs">
            <code className="text-cyan-400 bg-slate-800 px-1.5 py-0.5 rounded font-mono text-[10px]">
              {session.session_id.slice(0, 8)}
            </code>
          </span>
          <button
            onClick={onLabStop}
            className="px-3 py-1 bg-red-600/80 hover:bg-red-500 text-white text-xs rounded font-medium transition-colors"
          >
            Stop Lab
          </button>
        </div>
        <div className="flex-1 overflow-hidden">
          <Terminal sessionId={session.session_id} />
        </div>
      </div>
    </div>
  )
}

export default LabPanel
