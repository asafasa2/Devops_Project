import React from 'react'

const HomePage: React.FC = () => {
  return (
    <div className="home-page">
      <h1>Welcome to DevOps Learning Platform</h1>
      <p>
        Master DevOps tools and practices through interactive learning modules, 
        hands-on labs, and comprehensive assessments.
      </p>
      
      <div className="features">
        <div className="feature-card">
          <h3>Interactive Learning</h3>
          <p>Learn Docker, Ansible, Terraform, and Jenkins through guided tutorials</p>
        </div>
        
        <div className="feature-card">
          <h3>Hands-on Labs</h3>
          <p>Practice in real environments with containerized lab sessions</p>
        </div>
        
        <div className="feature-card">
          <h3>Progress Tracking</h3>
          <p>Monitor your learning progress and earn certifications</p>
        </div>
      </div>
    </div>
  )
}

export default HomePage