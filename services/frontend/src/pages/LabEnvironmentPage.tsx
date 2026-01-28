import React, { useState } from 'react'
import LabLauncher from '../components/LabLauncher'
import ActiveLabSessions from '../components/ActiveLabSessions'
import LabHistory from '../components/LabHistory'

const LabEnvironmentPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'launcher' | 'active' | 'history'>('launcher')

  return (
    <div className="lab-environment-page">
      <div className="page-header">
        <h1>Lab Environment</h1>
        <p>Practice DevOps tools in hands-on lab environments</p>
      </div>

      <div className="lab-tabs">
        <button
          onClick={() => setActiveTab('launcher')}
          className={`tab-button ${activeTab === 'launcher' ? 'active' : ''}`}
        >
          🚀 Launch Lab
        </button>
        <button
          onClick={() => setActiveTab('active')}
          className={`tab-button ${activeTab === 'active' ? 'active' : ''}`}
        >
          🔧 Active Sessions
        </button>
        <button
          onClick={() => setActiveTab('history')}
          className={`tab-button ${activeTab === 'history' ? 'active' : ''}`}
        >
          📊 Lab History
        </button>
      </div>

      <div className="tab-content">
        {activeTab === 'launcher' && <LabLauncher />}
        {activeTab === 'active' && <ActiveLabSessions />}
        {activeTab === 'history' && <LabHistory />}
      </div>
    </div>
  )
}

export default LabEnvironmentPage