import React from 'react'

interface StatsCardProps {
  title: string
  value: string | number
  subtitle?: string
  icon?: string
  color?: string
}

const StatsCard: React.FC<StatsCardProps> = ({ 
  title, 
  value, 
  subtitle, 
  icon, 
  color = '#1976d2' 
}) => {
  return (
    <div className="stats-card" style={{ borderLeftColor: color }}>
      <div className="stats-header">
        {icon && <span className="stats-icon">{icon}</span>}
        <h4 className="stats-title">{title}</h4>
      </div>
      <div className="stats-value" style={{ color }}>
        {value}
      </div>
      {subtitle && (
        <div className="stats-subtitle">
          {subtitle}
        </div>
      )}
    </div>
  )
}

export default StatsCard