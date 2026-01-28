import React, { useState, useEffect } from 'react'
import { labService } from '../services/labService'
import { LabSession } from '../types'

const LabHistory: React.FC = () => {
  const [sessions, setSessions] = useState<LabSession[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filter, setFilter] = useState<'all' | 'completed' | 'failed'>('all')

  useEffect(() => {
    const fetchLabHistory = async () => {
      try {
        setLoading(true)
        const data = await labService.getLabHistory()
        setSessions(data)
      } catch (error: any) {
        console.error('Failed to fetch lab history:', error)
        setError('Failed to load lab history')
      } finally {
        setLoading(false)
      }
    }

    fetchLabHistory()
  }, [])

  const filteredSessions = sessions.filter(session => {
    if (filter === 'all') return true
    return session.status === filter
  })

  const formatDuration = (startTime: string, endTime?: string) => {
    const start = new Date(startTime)
    const end = endTime ? new Date(endTime) : new Date()
    const diffMs = end.getTime() - start.getTime()
    const diffMins = Math.floor(diffMs / (1000 * 60))
    const hours = Math.floor(diffMins / 60)
    const minutes = diffMins % 60
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`
    }
    return `${minutes}m`
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return '✅'
      case 'failed': return '❌'
      case 'active': return '🟢'
      default: return '⚪'
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return '#4caf50'
      case 'failed': return '#f44336'
      case 'active': return '#ff9800'
      default: return '#666'
    }
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner">Loading lab history...</div>
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
    <div className="lab-history">
      <div className="history-header">
        <h2>Lab History</h2>
        <p>View your past lab sessions and track your progress</p>
      </div>

      <div className="history-filters">
        <div className="filter-group">
          <label>Status:</label>
          <select value={filter} onChange={(e) => setFilter(e.target.value as any)}>
            <option value="all">All Sessions</option>
            <option value="completed">Completed</option>
            <option value="failed">Failed</option>
          </select>
        </div>
      </div>

      {filteredSessions.length === 0 ? (
        <div className="no-history">
          <div className="no-history-icon">📊</div>
          <h3>No Lab History</h3>
          <p>You haven't completed any lab sessions yet.</p>
        </div>
      ) : (
        <div className="history-list">
          {filteredSessions.map((session) => (
            <div key={session.id} className="history-item">
              <div className="history-header-row">
                <div className="session-info">
                  <div className="session-name">{session.lab_type}</div>
                  <div className="session-date">
                    {new Date(session.start_time).toLocaleDateString()}
                  </div>
                </div>
                <div className="session-status-info">
                  <div 
                    className="status-badge"
                    style={{ 
                      backgroundColor: getStatusColor(session.status),
                      color: 'white'
                    }}
                  >
                    <span className="status-icon">{getStatusIcon(session.status)}</span>
                    <span className="status-text">{session.status}</span>
                  </div>
                </div>
              </div>

              <div className="history-details">
                <div className="detail-row">
                  <div className="detail-item">
                    <span className="detail-label">Started:</span>
                    <span className="detail-value">
                      {new Date(session.start_time).toLocaleString()}
                    </span>
                  </div>
                  {session.end_time && (
                    <div className="detail-item">
                      <span className="detail-label">Ended:</span>
                      <span className="detail-value">
                        {new Date(session.end_time).toLocaleString()}
                      </span>
                    </div>
                  )}
                  <div className="detail-item">
                    <span className="detail-label">Duration:</span>
                    <span className="detail-value">
                      {formatDuration(session.start_time, session.end_time)}
                    </span>
                  </div>
                </div>

                {session.lab_data && Object.keys(session.lab_data).length > 0 && (
                  <div className="lab-data">
                    <div className="lab-data-header">Session Data:</div>
                    <div className="lab-data-content">
                      {Object.entries(session.lab_data).map(([key, value]) => (
                        <div key={key} className="data-item">
                          <span className="data-key">{key}:</span>
                          <span className="data-value">{String(value)}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {sessions.length > 0 && (
        <div className="history-stats">
          <h3>Statistics</h3>
          <div className="stats-grid">
            <div className="stat-item">
              <div className="stat-value">{sessions.length}</div>
              <div className="stat-label">Total Sessions</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">
                {sessions.filter(s => s.status === 'completed').length}
              </div>
              <div className="stat-label">Completed</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">
                {Math.round(
                  sessions.reduce((total, session) => {
                    const duration = formatDuration(session.start_time, session.end_time)
                    const minutes = parseInt(duration.replace(/[^\d]/g, '')) || 0
                    return total + minutes
                  }, 0) / sessions.length
                )}m
              </div>
              <div className="stat-label">Avg Duration</div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default LabHistory