import React, { useState, useEffect } from 'react'
import { labService } from '../services/labService'
import { LabSession } from '../types'

interface LabMonitorProps {
  session: LabSession
}

const LabMonitor: React.FC<LabMonitorProps> = ({ session }) => {
  const [logs, setLogs] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [autoRefresh, setAutoRefresh] = useState(true)

  useEffect(() => {
    const fetchLogs = async () => {
      try {
        setLoading(true)
        const result = await labService.getLabLogs(session.id)
        setLogs(result.logs)
        setError(null)
      } catch (error: any) {
        console.error('Failed to fetch logs:', error)
        setError('Failed to load lab logs')
      } finally {
        setLoading(false)
      }
    }

    fetchLogs()

    let interval: NodeJS.Timeout | null = null
    if (autoRefresh && session.status === 'active') {
      interval = setInterval(fetchLogs, 5000) // Refresh every 5 seconds
    }

    return () => {
      if (interval) clearInterval(interval)
    }
  }, [session.id, session.status, autoRefresh])

  const formatDuration = (startTime: string, endTime?: string) => {
    const start = new Date(startTime)
    const end = endTime ? new Date(endTime) : new Date()
    const diffMs = end.getTime() - start.getTime()
    const diffMins = Math.floor(diffMs / (1000 * 60))
    const hours = Math.floor(diffMins / 60)
    const minutes = diffMins % 60
    const seconds = Math.floor((diffMs % (1000 * 60)) / 1000)
    
    if (hours > 0) {
      return `${hours}h ${minutes}m ${seconds}s`
    }
    if (minutes > 0) {
      return `${minutes}m ${seconds}s`
    }
    return `${seconds}s`
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return '🟢'
      case 'starting': return '🟡'
      case 'stopping': return '🔴'
      case 'completed': return '✅'
      case 'failed': return '❌'
      default: return '⚪'
    }
  }

  return (
    <div className="lab-monitor">
      <div className="monitor-header">
        <h3>Lab Session Monitor</h3>
        <div className="monitor-controls">
          <label className="auto-refresh-toggle">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
            />
            Auto-refresh
          </label>
        </div>
      </div>

      <div className="monitor-content">
        <div className="session-overview">
          <div className="overview-grid">
            <div className="overview-item">
              <div className="item-label">Status</div>
              <div className="item-value">
                <span className="status-icon">{getStatusIcon(session.status)}</span>
                {session.status}
              </div>
            </div>
            
            <div className="overview-item">
              <div className="item-label">Lab Type</div>
              <div className="item-value">{session.lab_type}</div>
            </div>
            
            <div className="overview-item">
              <div className="item-label">Duration</div>
              <div className="item-value">
                {formatDuration(session.start_time, session.end_time)}
              </div>
            </div>
            
            <div className="overview-item">
              <div className="item-label">Started</div>
              <div className="item-value">
                {new Date(session.start_time).toLocaleString()}
              </div>
            </div>
            
            {session.container_id && (
              <div className="overview-item">
                <div className="item-label">Container ID</div>
                <div className="item-value container-id">
                  {session.container_id}
                </div>
              </div>
            )}
            
            {session.end_time && (
              <div className="overview-item">
                <div className="item-label">Ended</div>
                <div className="item-value">
                  {new Date(session.end_time).toLocaleString()}
                </div>
              </div>
            )}
          </div>
        </div>

        {session.lab_data && Object.keys(session.lab_data).length > 0 && (
          <div className="session-data">
            <h4>Session Data</h4>
            <div className="data-grid">
              {Object.entries(session.lab_data).map(([key, value]) => (
                <div key={key} className="data-item">
                  <div className="data-key">{key}</div>
                  <div className="data-value">{String(value)}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="lab-logs">
          <div className="logs-header">
            <h4>Container Logs</h4>
            <div className="logs-info">
              {logs.length} log entries
              {autoRefresh && session.status === 'active' && (
                <span className="refresh-indicator">🔄 Auto-refreshing</span>
              )}
            </div>
          </div>
          
          <div className="logs-content">
            {loading && logs.length === 0 ? (
              <div className="logs-loading">Loading logs...</div>
            ) : error ? (
              <div className="logs-error">{error}</div>
            ) : logs.length === 0 ? (
              <div className="logs-empty">No logs available</div>
            ) : (
              <div className="logs-list">
                {logs.map((log, index) => (
                  <div key={index} className="log-entry">
                    <span className="log-line-number">{index + 1}</span>
                    <span className="log-content">{log}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="progress-tracking">
          <h4>Progress Tracking</h4>
          <div className="progress-items">
            <div className="progress-item">
              <div className="progress-label">Lab Environment Setup</div>
              <div className="progress-status completed">✅ Completed</div>
            </div>
            <div className="progress-item">
              <div className="progress-label">Container Initialization</div>
              <div className="progress-status completed">✅ Completed</div>
            </div>
            <div className="progress-item">
              <div className="progress-label">Service Health Check</div>
              <div className={`progress-status ${session.status === 'active' ? 'completed' : 'pending'}`}>
                {session.status === 'active' ? '✅ Completed' : '⏳ Pending'}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default LabMonitor