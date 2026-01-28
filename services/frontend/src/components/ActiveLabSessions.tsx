import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { labService } from '../services/labService'
import { LabSession } from '../types'

const ActiveLabSessions: React.FC = () => {
  const [sessions, setSessions] = useState<LabSession[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchActiveSessions = async () => {
      try {
        setLoading(true)
        const data = await labService.getActiveLabSessions()
        setSessions(data)
      } catch (error: any) {
        console.error('Failed to fetch active sessions:', error)
        setError('Failed to load active lab sessions')
      } finally {
        setLoading(false)
      }
    }

    fetchActiveSessions()
    
    // Refresh every 30 seconds
    const interval = setInterval(fetchActiveSessions, 30000)
    return () => clearInterval(interval)
  }, [])

  const handleStopSession = async (sessionId: number) => {
    if (!window.confirm('Are you sure you want to stop this lab session?')) {
      return
    }

    try {
      await labService.stopLabSession(sessionId)
      setSessions(sessions.filter(session => session.id !== sessionId))
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
        <div className="loading-spinner">Loading active sessions...</div>
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
    <div className="active-lab-sessions">
      <div className="sessions-header">
        <h2>Active Lab Sessions</h2>
        <p>Manage your currently running lab environments</p>
      </div>

      {sessions.length === 0 ? (
        <div className="no-sessions">
          <div className="no-sessions-icon">🔧</div>
          <h3>No Active Lab Sessions</h3>
          <p>You don't have any running lab environments at the moment.</p>
          <Link to="/labs" className="launch-lab-button">
            Launch a Lab
          </Link>
        </div>
      ) : (
        <div className="sessions-grid">
          {sessions.map((session) => (
            <div key={session.id} className="session-card">
              <div className="session-header">
                <div className="session-info">
                  <h3 className="session-name">{session.lab_type}</h3>
                  <div 
                    className="session-status"
                    style={{ color: getStatusColor(session.status) }}
                  >
                    <span className="status-dot" style={{ backgroundColor: getStatusColor(session.status) }}></span>
                    {session.status}
                  </div>
                </div>
                <div className="session-duration">
                  {formatDuration(session.start_time)}
                </div>
              </div>

              <div className="session-details">
                <div className="detail-item">
                  <span className="detail-label">Started:</span>
                  <span className="detail-value">
                    {new Date(session.start_time).toLocaleString()}
                  </span>
                </div>
                {session.container_id && (
                  <div className="detail-item">
                    <span className="detail-label">Container:</span>
                    <span className="detail-value container-id">
                      {session.container_id.substring(0, 12)}
                    </span>
                  </div>
                )}
              </div>

              <div className="session-actions">
                <Link 
                  to={`/labs/sessions/${session.id}`}
                  className="access-button"
                >
                  <span className="button-icon">🖥️</span>
                  Access Lab
                </Link>
                <button
                  onClick={() => handleStopSession(session.id)}
                  className="stop-button"
                  disabled={session.status !== 'active'}
                >
                  <span className="button-icon">⏹️</span>
                  Stop
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default ActiveLabSessions