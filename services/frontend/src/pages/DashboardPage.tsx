import React, { useEffect, useState } from 'react'
import { useAuthContext } from '../contexts/AuthContext'
import { learningService } from '../services/learningService'
import StatsCard from '../components/StatsCard'
import ProgressChart from '../components/ProgressChart'
import LearningPathCard from '../components/LearningPathCard'
import RecommendationCard from '../components/RecommendationCard'
import { LearningContent } from '../types'

interface UserStats {
  totalModulesCompleted: number
  totalTimeSpent: number
  currentStreak: number
  averageScore: number
  toolsProgress: Record<string, number>
}

const DashboardPage: React.FC = () => {
  const { user } = useAuthContext()
  const [stats, setStats] = useState<UserStats | null>(null)
  const [recommendations, setRecommendations] = useState<LearningContent[]>([])
  const [recentModules, setRecentModules] = useState<LearningContent[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true)
        
        // Fetch user stats
        const userStats = await learningService.getUserStats()
        setStats(userStats)
        
        // Fetch recommendations
        const recommendedContent = await learningService.getRecommendations()
        setRecommendations(recommendedContent.slice(0, 3)) // Show top 3
        
        // Fetch recent modules (mock data for now)
        const modules = await learningService.getLearningModules({ limit: 4 })
        setRecentModules(modules.data)
        
      } catch (error: any) {
        console.error('Failed to fetch dashboard data:', error)
        setError('Failed to load dashboard data')
      } finally {
        setLoading(false)
      }
    }

    if (user) {
      fetchDashboardData()
    }
  }, [user])

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner">Loading dashboard...</div>
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
    <div className="dashboard-page">
      <div className="dashboard-header">
        <h1>Welcome back, {user?.username}!</h1>
        <p>Continue your DevOps learning journey</p>
      </div>

      {/* Stats Overview */}
      <div className="stats-grid">
        <StatsCard
          title="Modules Completed"
          value={stats?.totalModulesCompleted || 0}
          icon="📚"
          color="#4caf50"
        />
        <StatsCard
          title="Learning Streak"
          value={`${stats?.currentStreak || 0} days`}
          icon="🔥"
          color="#ff9800"
        />
        <StatsCard
          title="Average Score"
          value={`${stats?.averageScore || 0}%`}
          icon="🎯"
          color="#2196f3"
        />
        <StatsCard
          title="Time Spent"
          value={`${Math.floor((stats?.totalTimeSpent || 0) / 60)}h ${(stats?.totalTimeSpent || 0) % 60}m`}
          icon="⏱️"
          color="#9c27b0"
        />
      </div>

      {/* Progress Chart */}
      {stats?.toolsProgress && Object.keys(stats.toolsProgress).length > 0 && (
        <div className="dashboard-section">
          <h2>Learning Progress by Tool</h2>
          <ProgressChart 
            data={stats.toolsProgress} 
            title="Your Progress Across DevOps Tools"
          />
        </div>
      )}

      {/* Recommendations */}
      {recommendations.length > 0 && (
        <div className="dashboard-section">
          <h2>Recommended for You</h2>
          <div className="recommendations-grid">
            {recommendations.map((content) => (
              <RecommendationCard
                key={content.id}
                content={content}
                reason="Based on your current progress"
              />
            ))}
          </div>
        </div>
      )}

      {/* Continue Learning */}
      <div className="dashboard-section">
        <h2>Continue Learning</h2>
        <div className="learning-paths-grid">
          {recentModules.map((module) => (
            <LearningPathCard
              key={module.id}
              id={module.id}
              title={module.title}
              description={module.content_data?.description || 'Learn essential DevOps concepts'}
              tool={module.tool_category}
              difficulty={module.difficulty_level}
              progress={Math.floor(Math.random() * 100)} // Mock progress
              estimatedTime={module.estimated_duration}
              isCompleted={false}
            />
          ))}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="dashboard-section">
        <h2>Quick Actions</h2>
        <div className="quick-actions">
          <button className="action-card">
            <span className="action-icon">🧪</span>
            <span className="action-title">Start Lab</span>
            <span className="action-description">Practice in hands-on environments</span>
          </button>
          <button className="action-card">
            <span className="action-icon">❓</span>
            <span className="action-title">Take Quiz</span>
            <span className="action-description">Test your knowledge</span>
          </button>
          <button className="action-card">
            <span className="action-icon">📊</span>
            <span className="action-title">View Progress</span>
            <span className="action-description">See detailed analytics</span>
          </button>
        </div>
      </div>
    </div>
  )
}

export default DashboardPage