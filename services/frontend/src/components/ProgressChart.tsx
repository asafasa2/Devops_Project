import React from 'react'

interface ProgressChartProps {
  data: Record<string, number>
  title: string
}

const ProgressChart: React.FC<ProgressChartProps> = ({ data, title }) => {
  const maxValue = Math.max(...Object.values(data))
  
  return (
    <div className="progress-chart">
      <h4>{title}</h4>
      <div className="chart-container">
        {Object.entries(data).map(([tool, progress]) => (
          <div key={tool} className="chart-bar">
            <div className="bar-container">
              <div 
                className="bar-fill" 
                style={{ 
                  height: `${(progress / maxValue) * 100}%`,
                  backgroundColor: getToolColor(tool)
                }}
              ></div>
            </div>
            <div className="bar-label">{tool}</div>
            <div className="bar-value">{progress}%</div>
          </div>
        ))}
      </div>
    </div>
  )
}

const getToolColor = (tool: string): string => {
  const colors: Record<string, string> = {
    docker: '#2496ed',
    ansible: '#ee0000',
    terraform: '#623ce4',
    jenkins: '#d33833',
    git: '#f05032',
    kubernetes: '#326ce5'
  }
  return colors[tool.toLowerCase()] || '#1976d2'
}

export default ProgressChart