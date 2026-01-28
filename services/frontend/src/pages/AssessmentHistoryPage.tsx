import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { learningService } from '../services/learningService'
import { Assessment } from '../types'

const AssessmentHistoryPage: React.FC = () => {
  const [assessments, setAssessments] = useState<Assessment[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filter, setFilter] = useState<'all' | 'passed' | 'failed'>('all')
  const [sortBy, setSortBy] = useState<'date' | 'score'>('date')

  useEffect(() => {
    const fetchAssessments = async () => {
      try {
        setLoading(true)
        const data = await learningService.getUserAssessments()
        setAssessments(data)
      } catch (error: any) {
        console.error('Failed to fetch assessments:', error)
        setError('Failed to load assessment history')
      } finally {
        setLoading(false)
      }
    }

    fetchAssessments()
  }, [])

  const filteredAssessments = assessments
    .filter(assessment => {
      if (filter === 'all') return true
      const percentage = (assessment.score / assessment.max_score) * 100
      return filter === 'passed' ? percentage >= 70 : percentage < 70
    })
    .sort((a, b) => {
      if (sortBy === 'date') {
        return new Date(b.completed_at).getTime() - new Date(a.completed_at).getTime()
      }
      return (b.score / b.max_score) - (a.score / a.max_score)
    })

  const getOverallStats = () => {
    const totalAssessments = assessments.length
    const passedAssessments = assessments.filter(a => (a.score / a.max_score) >= 0.7).length
    const averageScore = assessments.length > 0 
      ? assessments.reduce((sum, a) => sum + (a.score / a.max_score), 0) / assessments.length * 100
      : 0

    return {
      total: totalAssessments,
      passed: passedAssessments,
      failed: totalAssessments - passedAssessments,
      average: Math.round(averageScore)
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const formatTime = (seconds: number) => {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes}m ${remainingSeconds}s`
  }

  const getGradeColor = (percentage: number) => {
    if (percentage >= 90) return '#4caf50'
    if (percentage >= 80) return '#8bc34a'
    if (percentage >= 70) return '#ff9800'
    if (percentage >= 60) return '#ff5722'
    return '#f44336'
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner">Loading assessment history...</div>
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

  const stats = getOverallStats()

  return (
    <div className="assessment-history-page">
      <div className="page-header">
        <h1>Assessment History</h1>
        <p>Track your quiz performance and progress over time</p>
      </div>

      <div className="stats-overview">
        <div className="stat-card">
          <div className="stat-value">{stats.total}</div>
          <div className="stat-label">Total Quizzes</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{stats.passed}</div>
          <div className="stat-label">Passed</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{stats.failed}</div>
          <div className="stat-label">Failed</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{stats.average}%</div>
          <div className="stat-label">Average Score</div>
        </div>
      </div>

      <div className="filters-section">
        <div className="filter-group">
          <label>Filter by result:</label>
          <select value={filter} onChange={(e) => setFilter(e.target.value as any)}>
            <option value="all">All Assessments</option>
            <option value="passed">Passed Only</option>
            <option value="failed">Failed Only</option>
          </select>
        </div>
        
        <div className="filter-group">
          <label>Sort by:</label>
          <select value={sortBy} onChange={(e) => setSortBy(e.target.value as any)}>
            <option value="date">Date (Newest First)</option>
            <option value="score">Score (Highest First)</option>
          </select>
        </div>
      </div>

      <div className="assessments-list">
        {filteredAssessments.length === 0 ? (
          <div className="no-assessments">
            <p>No assessments found matching your criteria.</p>
            <Link to="/dashboard" className="start-learning-button">
              Start Learning
            </Link>
          </div>
        ) : (
          filteredAssessments.map((assessment) => {
            const percentage = Math.round((assessment.score / assessment.max_score) * 100)
            const passed = percentage >= 70
            
            return (
              <div key={assessment.id} className={`assessment-item ${passed ? 'passed' : 'failed'}`}>
                <div className="assessment-header">
                  <div className="assessment-title">
                    Quiz Assessment #{assessment.id}
                  </div>
                  <div className="assessment-date">
                    {formatDate(assessment.completed_at)}
                  </div>
                </div>
                
                <div className="assessment-details">
                  <div className="score-section">
                    <div className="score-display">
                      <span 
                        className="score-percentage"
                        style={{ color: getGradeColor(percentage) }}
                      >
                        {percentage}%
                      </span>
                      <span className="score-fraction">
                        ({assessment.score}/{assessment.max_score})
                      </span>
                    </div>
                    <div className={`pass-status ${passed ? 'passed' : 'failed'}`}>
                      {passed ? '✅ Passed' : '❌ Failed'}
                    </div>
                  </div>
                  
                  <div className="assessment-meta">
                    <div className="meta-item">
                      <span className="meta-label">Time:</span>
                      <span className="meta-value">
                        {formatTime(assessment.completion_time)}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="assessment-actions">
                  <Link 
                    to={`/quiz/${assessment.content_id}`}
                    className="retake-button"
                  >
                    Retake Quiz
                  </Link>
                </div>
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}

export default AssessmentHistoryPage