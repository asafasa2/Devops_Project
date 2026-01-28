import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { labService } from '../services/labService'
import { LabSession } from '../types'
import LabTerminal from '../components/LabTerminal'
import LabMonitor from '../components/LabMonitor'

const LabSessionPage: React.FC = () => {
  const { sessionId } = useParams<{ sessionId: string }>()
  const navigate = useNavigate()
  const [session, setSession] = useState<LabSession | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<'terminal' | 'monitor'>('terminal')

  useEffect(() => {
    const fetchSession = async () => {
      if (!sessionId) return
      
      try {
        setLoading(true)
        const sessionData = await labService.getLabSession(parseInt(sessionId))
        setSession(sessionData)
      } catch (error: any) {
        console.error('Failed to fetch lab session:', error)
        setError('Failed to load lab session')
      } finally {
        setLoading(false)
      }
    }

    fetchSession()
    
    // Refresh session status every 10 seconds
    const interval = setInterval(fetchSession, 10000)
    return () => clearInterval(interval)
  }, [sessionId])

  const handleStopSession = async () => {
    if (!session || !window.confirm('Are you sure you want to stop this lab session?')) {
      return
    }

    try {
      await labService.stopLabSession(session.id)
      navigate('/labs')
    } catch (error: any) {
      console.error('Failed to stop session:', error)
      alert('Failed to stop lab session. Please try again.')
    }
  }

  const formatDuration = (startTime: string) => {
    const start = new Date(startTime)
    const now = new Date()
    const diffMs = now.getTime() - start.getTime()
    const diffMins = Math.floor(diffMs / (1000 * 60))
    const hours = Math.floor(diffMins / 60)
    const minutes = diffMins % 60
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`
    }
    return `${minutes}m`
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return '#4caf50'
      case 'starting': return '#ff9800'
      case 'stopping': return '#f44336'
      default: return '#666'
    }
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner">Loading lab session...</div>
      </div>
    )
  }

  if (error || !session) {
    return (
      <div className="error-container">
        <div className="error-message">{error || 'Lab session not found'}</div>
        <button onClick={() => navigate('/labs')} className="back-button">
          Back to Labs
        </button>
      </div>
    )
  }

  return (
    <div className="lab-session-page">
      <div className="session-header">
        <div className="session-info">
          <div className="breadcrumb">
            <span onClick={() => navigate('/labs')} className="breadcrumb-link">
              Lab Environment
            </span>
            <span className="breadcrumb-separator">›</span>
            <span className="breadcrumb-current">{session.lab_type}</span>
          </div>
          
          <h1>{session.lab_type}</h1>
          
          <div className="session-meta">
            <div className="meta-item">
              <span className="meta-label">Status:</span>
              <span 
                className="meta-value status"
                style={{ color: getStatusColor(session.status) }}
              >
                <span className="status-dot" style={{ backgroundColor: getStatusColor(session.status) }}></span>
                {session.status}
              </span>
            </div>
            <div className="meta-item">
              <span className="meta-label">Duration:</span>
              <span className="meta-value">{formatDuration(session.start_time)}</span>
            </div>
            {session.container_id && (
              <div className="meta-item">
                <span className="meta-label">Container:</span>
                <span className="meta-value container-id">
                  {session.container_id.substring(0, 12)}
                </span>
              </div>
            )}
          </div>
        </div>
        
        <div className="session-actions">
          <button
            onClick={handleStopSession}
            className="stop-session-button"
            disabled={session.status !== 'active'}
          >
            <span className="button-icon">⏹️</span>
            Stop Session
          </button>
        </div>
      </div>

      <div className="session-tabs">
        <button
          onClick={() => setActiveTab('terminal')}
          className={`tab-button ${activeTab === 'terminal' ? 'active' : ''}`}
        >
          🖥️ Terminal
        </button>
        <button
          onClick={() => setActiveTab('monitor')}
          className={`tab-button ${activeTab === 'monitor' ? 'active' : ''}`}
        >
          📊 Monitor
        </button>
      </div>

      <div className="session-content">
        {activeTab === 'terminal' && (
          <LabTerminal sessionId={session.id} />
        )}
        {activeTab === 'monitor' && (
          <LabMonitor session={session} />
        )}
      </div>
    </div>
  )
}

export default LabSessionPage