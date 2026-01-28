import React, { useState } from 'react'
import { Link } from 'react-router-dom'
import { authService } from '../services/authService'

const ForgotPasswordPage: React.FC = () => {
  const [email, setEmail] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError('')
    setMessage('')
    
    try {
      await authService.requestPasswordReset(email)
      setMessage('Password reset instructions have been sent to your email.')
    } catch (error: any) {
      setError(error.response?.data?.message || 'Failed to send reset email')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-container">
        <h2>Forgot Password</h2>
        <p className="auth-description">
          Enter your email address and we'll send you instructions to reset your password.
        </p>
        
        {error && (
          <div className="error-message">
            {error}
          </div>
        )}
        
        {message && (
          <div className="success-message">
            {message}
          </div>
        )}
        
        <form onSubmit={handleSubmit} className="auth-form">
          <div className="form-group">
            <label htmlFor="email">Email:</label>
            <input
              type="email"
              id="email"
              name="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={isLoading}
            />
          </div>
          
          <button type="submit" className="auth-button" disabled={isLoading}>
            {isLoading ? 'Sending...' : 'Send Reset Instructions'}
          </button>
        </form>
        
        <p className="auth-link">
          Remember your password? <Link to="/login">Back to Login</Link>
        </p>
      </div>
    </div>
  )
}

export default ForgotPasswordPage