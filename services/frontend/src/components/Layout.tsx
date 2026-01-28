import React from 'react'
import { Outlet, Link, useNavigate } from 'react-router-dom'
import { useAuthContext } from '../contexts/AuthContext'

const Layout: React.FC = () => {
  const { user, logout } = useAuthContext()
  const navigate = useNavigate()

  const handleLogout = async () => {
    try {
      await logout()
      navigate('/login')
    } catch (error) {
      console.error('Logout failed:', error)
    }
  }

  return (
    <div className="layout">
      <header className="header">
        <h1>DevOps Learning Platform</h1>
        <nav className="nav">
          <Link to="/">Home</Link>
          {user ? (
            <>
              <Link to="/dashboard">Dashboard</Link>
              <Link to="/labs">Labs</Link>
              <Link to="/assessments">Assessments</Link>
              <Link to="/profile">Profile</Link>
              <button onClick={handleLogout} className="nav-button">
                Logout ({user.username})
              </button>
            </>
          ) : (
            <>
              <Link to="/login">Login</Link>
              <Link to="/register">Register</Link>
            </>
          )}
        </nav>
      </header>
      
      <main className="main">
        <Outlet />
      </main>
      
      <footer className="footer">
        <p>&copy; 2024 DevOps Learning Platform. All rights reserved.</p>
      </footer>
    </div>
  )
}

export default Layout