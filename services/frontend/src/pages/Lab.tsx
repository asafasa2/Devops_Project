import React, { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { api } from '../services/api'
import LabPanel from '../components/LabPanel'

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

interface ValidationResult {
  session_id: string
  lab_id: string
  all_passed: boolean
  results: Array<{
    command: string
    passed: boolean
    exit_code: number
    hint?: string
  }>
}

const STEPS = [
  { id: 'start',     label: 'Start' },
  { id: 'container', label: 'Container' },
  { id: 'systemd',   label: 'Systemd' },
  { id: 'ready',     label: 'Ready' },
]

const STATUS_STEP: Record<string, number> = {
  starting_container: 1,
  booting_systemd:    2,
  running_setup:      3,
  ready:              4,
}

const STATUS_MESSAGES: Record<string, string> = {
  starting_container: 'Starting container…',
  booting_systemd:    'Booting systemd…',
  running_setup:      'Running lab setup…',
  ready:              'Ready!',
}

const Lab: React.FC = () => {
  const { labId } = useParams<{ labId: string }>()
  const navigate = useNavigate()

  const [phase, setPhase] = useState<'idle' | 'starting' | 'ready' | 'error'>('idle')
  const [statusMsg, setStatusMsg] = useState('')
  const [activeStep, setActiveStep] = useState(0)
  const [session, setSession] = useState<LabSession | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const handleBeforeUnload = () => {
      if (session) {
        navigator.sendBeacon(`/api/labs/${session.session_id}/stop`, '')
      }
    }
    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [session])

  const startLab = async () => {
    if (!labId) return
    setPhase('starting')
    setError(null)
    setActiveStep(1)
    setStatusMsg('Requesting lab start…')

    let sessionId: string | null = null

    try {
      const { data } = await api.post<LabSession>('/labs/start', { lab_id: labId })
      sessionId = data.session_id

      let attempts = 0
      while (attempts < 60) {
        const { data: status } = await api.get<{ status: string }>(`/labs/${sessionId}`)
        const step = STATUS_STEP[status.status] ?? activeStep
        setActiveStep(step)
        setStatusMsg(STATUS_MESSAGES[status.status] ?? status.status)
        if (status.status === 'ready') break
        if (status.status === 'error') throw new Error('Lab startup failed')
        await new Promise(r => setTimeout(r, 2000))
        attempts++
      }

      setSession(data)
      setPhase('ready')
    } catch (err: any) {
      setError(err.response?.data?.detail ?? err.message ?? 'Failed to start lab')
      setPhase('error')
    }
  }

  const stopLab = useCallback(async () => {
    if (!session) return
    try {
      await api.delete(`/labs/${session.session_id}`)
    } catch (_) { /* best-effort */ }
    setSession(null)
    setPhase('idle')
    navigate('/')
  }, [session, navigate])

  const validate = useCallback(async (): Promise<ValidationResult> => {
    if (!session) throw new Error('No active session')
    const { data } = await api.post<ValidationResult>(`/labs/${session.session_id}/validate`)
    return data
  }, [session])

  if (phase === 'ready' && session) {
    return (
      <LabPanel
        session={session}
        onLabStop={stopLab}
        onValidate={validate}
      />
    )
  }

  const labTitle = labId?.replace(/_/g, ' ') ?? ''

  return (
    <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] px-4 gap-8">
      <h2 className="text-2xl font-bold text-cyan-400 capitalize">{labTitle}</h2>

      {phase === 'idle' && (
        <div className="bg-slate-800 border border-slate-700 rounded-2xl p-10 flex flex-col items-center gap-5 max-w-sm w-full text-center">
          <div className="text-4xl">🖥️</div>
          <p className="text-slate-400 text-sm">
            A disposable Linux container will spin up just for this session.
          </p>
          <button
            onClick={startLab}
            className="w-full py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold text-base transition-colors"
          >
            Start Lab
          </button>
        </div>
      )}

      {phase === 'starting' && (
        <div className="flex flex-col items-center gap-8 w-full max-w-md">
          {/* Stepper */}
          <div className="flex items-center w-full">
            {STEPS.map((step, idx) => {
              const stepNum = idx
              const isCompleted = activeStep > stepNum
              const isActive = activeStep === stepNum
              return (
                <React.Fragment key={step.id}>
                  <div className="flex flex-col items-center gap-1.5 flex-shrink-0">
                    <div
                      className={[
                        'w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-all',
                        isCompleted
                          ? 'bg-green-500 text-white'
                          : isActive
                          ? 'border-2 border-blue-400 text-blue-400 animate-pulse'
                          : 'bg-slate-700 text-slate-500',
                      ].join(' ')}
                    >
                      {isCompleted ? '✓' : stepNum}
                    </div>
                    <span className={`text-xs whitespace-nowrap ${isActive ? 'text-blue-400' : isCompleted ? 'text-green-400' : 'text-slate-500'}`}>
                      {step.label}
                    </span>
                  </div>
                  {idx < STEPS.length - 1 && (
                    <div className={`flex-1 h-0.5 mx-1 mb-5 ${activeStep > stepNum ? 'bg-green-500' : 'bg-slate-700'}`} />
                  )}
                </React.Fragment>
              )
            })}
          </div>

          {/* Status text */}
          <p className="text-slate-400 text-sm">{statusMsg}</p>
        </div>
      )}

      {phase === 'error' && (
        <div className="max-w-md w-full flex flex-col gap-4">
          <div className="bg-red-950 border border-red-700 text-red-300 rounded-xl p-5">
            <p className="font-semibold text-red-200 mb-1">Lab failed to start</p>
            <p className="text-sm">{error}</p>
          </div>
          <button
            onClick={startLab}
            className="py-2.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold transition-colors"
          >
            Retry
          </button>
        </div>
      )}
    </div>
  )
}

export default Lab
