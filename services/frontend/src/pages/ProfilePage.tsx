import React, { useState } from 'react'
import { useAuthContext } from '../contexts/AuthContext'

const ProfilePage: React.FC = () => {
  const { user, updateProfile, error, clearError } = useAuthContext()
  const [isEditing, setIsEditing] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [formData, setFormData] = useState({
    username: user?.username || '',
    email: user?.email || '',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
    if (error) clearError()
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    
    try {
      await updateProfile(formData)
      setIsEditing(false)
    } catch (error) {
      console.error('Profile update failed:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancel = () => {
    setFormData({
      username: user?.username || '',
      email: user?.email || '',
    })
    setIsEditing(false)
    if (error) clearError()
  }

  if (!user) {
    return <div>Loading...</div>
  }

  return (
    <div className="profile-page">
      <div className="profile-container">
        <h2>User Profile</h2>
        
        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        <div className="profile-info">
          <div className="profile-stats">
            <div className="stat-item">
              <span className="stat-label">Current Level:</span>
              <span className="stat-value">{user.current_level}</span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Total Points:</span>
              <span className="stat-value">{user.total_points}</span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Member Since:</span>
              <span className="stat-value">
                {new Date(user.created_at).toLocaleDateString()}
              </span>
            </div>
          </div>

          {isEditing ? (
            <form onSubmit={handleSubmit} className="profile-form">
              <div className="form-group">
                <label htmlFor="username">Username:</label>
                <input
                  type="text"
                  id="username"
                  name="username"
                  value={formData.username}
                  onChange={handleChange}
                  required
                  disabled={isLoading}
                />
              </div>
              
              <div className="form-group">
                <label htmlFor="email">Email:</label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  required
                  disabled={isLoading}
                />
              </div>
              
              <div className="form-actions">
                <button type="submit" className="save-button" disabled={isLoading}>
                  {isLoading ? 'Saving...' : 'Save Changes'}
                </button>
                <button type="button" className="cancel-button" onClick={handleCancel}>
                  Cancel
                </button>
              </div>
            </form>
          ) : (
            <div className="profile-details">
              <div className="detail-item">
                <span className="detail-label">Username:</span>
                <span className="detail-value">{user.username}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Email:</span>
                <span className="detail-value">{user.email}</span>
              </div>
              
              <button 
                className="edit-button" 
                onClick={() => setIsEditing(true)}
              >
                Edit Profile
              </button>
            </div>
          )}
        </div>

        <div className="learning-progress">
          <h3>Learning Progress</h3>
          <div className="progress-overview">
            {Object.keys(user.learning_progress || {}).length > 0 ? (
              <div className="progress-items">
                {Object.entries(user.learning_progress || {}).map(([tool, progress]) => (
                  <div key={tool} className="progress-item">
                    <span className="progress-tool">{tool}</span>
                    <div className="progress-bar">
                      <div 
                        className="progress-fill" 
                        style={{ width: `${(progress as any)?.completion || 0}%` }}
                      ></div>
                    </div>
                    <span className="progress-percentage">
                      {(progress as any)?.completion || 0}%
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p>No learning progress yet. Start your first module!</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default ProfilePage