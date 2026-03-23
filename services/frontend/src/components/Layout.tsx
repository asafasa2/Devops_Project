import React, { useState, useEffect } from 'react'
import { Outlet, Link, useLocation } from 'react-router-dom'
import { api } from '../services/api'

interface LabDef {
  id: string
  title: string
  subject: string
  difficulty: string
  estimated_minutes: number
}

interface LabProg {
  lab_id: string
  completed: boolean
}

const SUBJECTS = [
  { id: 'linux',      label: 'Linux',      icon: '>', color: '#60a5fa' },
  { id: 'networking', label: 'Networking',  icon: '⛓', color: '#a78bfa' },
  { id: 'cicd',       label: 'CI/CD',      icon: '⟳', color: '#f87171' },
  { id: 'terraform',  label: 'Terraform',  icon: '▦', color: '#34d399' },
  { id: 'ansible',    label: 'Ansible',    icon: '⚙', color: '#f9a8d4' },
  { id: 'monitoring', label: 'Monitoring', icon: '◉', color: '#fb923c' },
  { id: 'security',   label: 'Security',   icon: '⛊', color: '#fbbf24' },
]

const Layout: React.FC = () => {
  const location = useLocation()
  const isLabPage = location.pathname.startsWith('/lab/')
  const [collapsed, setCollapsed] = useState(() => {
    try { return localStorage.getItem('sidebar-collapsed') === 'true' } catch { return false }
  })
  const [labs, setLabs] = useState<LabDef[]>([])
  const [progress, setProgress] = useState<Record<string, boolean>>({})
  const [expandedSubject, setExpandedSubject] = useState<string | null>(null)

  useEffect(() => {
    localStorage.setItem('sidebar-collapsed', String(collapsed))
  }, [collapsed])

  useEffect(() => {
    Promise.all([
      api.get<LabDef[]>('/labs/definitions'),
      api.get<LabProg[]>('/progress'),
    ]).then(([labsRes, progRes]) => {
      setLabs(labsRes.data)
      const map: Record<string, boolean> = {}
      for (const p of progRes.data) if (p.completed) map[p.lab_id] = true
      setProgress(map)
    }).catch(() => {})
  }, [])

  const labsBySubject = (subjectId: string) => labs.filter(l => l.subject === subjectId)
  const completedInSubject = (subjectId: string) =>
    labsBySubject(subjectId).filter(l => progress[l.id]).length

  const totalLabs = labs.length
  const totalCompleted = Object.values(progress).filter(Boolean).length

  // Hide sidebar on lab pages to maximize terminal space
  if (isLabPage) {
    return (
      <div className="min-h-screen bg-slate-900 text-slate-100">
        <header className="bg-slate-900/95 backdrop-blur border-b border-slate-700/50 flex items-center justify-between px-4 h-12 shrink-0 z-20">
          <Link to="/" className="gradient-text font-bold text-base no-underline">
            &gt;_ DevOps Lab
          </Link>
          <Link to="/" className="text-slate-400 hover:text-slate-200 text-sm no-underline transition-colors">
            ← Dashboard
          </Link>
        </header>
        <main>
          <Outlet />
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex">
      {/* Sidebar */}
      <aside
        className={`
          ${collapsed ? 'w-16' : 'w-64'}
          bg-slate-950 border-r border-slate-800 flex flex-col shrink-0 transition-all duration-200 h-screen sticky top-0
        `}
      >
        {/* Logo */}
        <div className="h-14 flex items-center px-4 border-b border-slate-800 shrink-0">
          {!collapsed && (
            <Link to="/" className="gradient-text font-bold text-base no-underline truncate">
              &gt;_ DevOps Lab
            </Link>
          )}
          <button
            onClick={() => setCollapsed(!collapsed)}
            className={`${collapsed ? 'mx-auto' : 'ml-auto'} text-slate-500 hover:text-slate-300 transition-colors p-1`}
          >
            {collapsed ? '→' : '←'}
          </button>
        </div>

        {/* Global progress */}
        {!collapsed && totalLabs > 0 && (
          <div className="px-4 py-3 border-b border-slate-800">
            <div className="flex items-center justify-between text-xs text-slate-400 mb-1.5">
              <span>Progress</span>
              <span>{totalCompleted}/{totalLabs}</span>
            </div>
            <div className="h-1.5 bg-slate-800 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-cyan-500 to-blue-500 rounded-full transition-all duration-500"
                style={{ width: `${totalLabs ? (totalCompleted / totalLabs) * 100 : 0}%` }}
              />
            </div>
          </div>
        )}

        {/* Subject list */}
        <nav className="flex-1 overflow-y-auto py-2">
          {SUBJECTS.map(subject => {
            const subjectLabs = labsBySubject(subject.id)
            if (subjectLabs.length === 0 && collapsed) return null
            const completed = completedInSubject(subject.id)
            const total = subjectLabs.length
            const isExpanded = expandedSubject === subject.id

            return (
              <div key={subject.id}>
                <button
                  onClick={() => {
                    if (collapsed) return
                    setExpandedSubject(isExpanded ? null : subject.id)
                  }}
                  className={`
                    w-full flex items-center gap-3 px-4 py-2.5 text-left
                    hover:bg-slate-800/50 transition-colors group
                    ${collapsed ? 'justify-center' : ''}
                  `}
                  title={collapsed ? subject.label : undefined}
                >
                  <span
                    className="text-base shrink-0 w-5 text-center"
                    style={{ color: subject.color }}
                  >
                    {subject.icon}
                  </span>
                  {!collapsed && (
                    <>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm font-medium text-slate-200 truncate">{subject.label}</div>
                        {total > 0 && (
                          <div className="flex items-center gap-2 mt-0.5">
                            <div className="flex-1 h-1 bg-slate-800 rounded-full overflow-hidden">
                              <div
                                className="h-full rounded-full transition-all duration-500"
                                style={{
                                  width: `${total ? (completed / total) * 100 : 0}%`,
                                  backgroundColor: subject.color,
                                }}
                              />
                            </div>
                            <span className="text-[10px] text-slate-500 shrink-0">{completed}/{total}</span>
                          </div>
                        )}
                      </div>
                      <span className={`text-slate-600 text-xs transition-transform ${isExpanded ? 'rotate-90' : ''}`}>
                        ›
                      </span>
                    </>
                  )}
                </button>

                {/* Expanded lab list */}
                {isExpanded && !collapsed && subjectLabs.length > 0 && (
                  <div className="pb-1">
                    {subjectLabs.map(lab => (
                      <Link
                        key={lab.id}
                        to={`/lab/${lab.id}`}
                        className="flex items-center gap-2 pl-12 pr-4 py-1.5 text-xs text-slate-400 hover:text-slate-200 hover:bg-slate-800/30 no-underline transition-colors"
                      >
                        <span className={progress[lab.id] ? 'text-green-400' : 'text-slate-600'}>
                          {progress[lab.id] ? '✓' : '○'}
                        </span>
                        <span className="truncate">{lab.title}</span>
                      </Link>
                    ))}
                  </div>
                )}
              </div>
            )
          })}
        </nav>

        {/* Collapse hint */}
        {!collapsed && (
          <div className="px-4 py-3 border-t border-slate-800 text-[10px] text-slate-600 text-center">
            {totalLabs} labs across {SUBJECTS.filter(s => labsBySubject(s.id).length > 0).length} subjects
          </div>
        )}
      </aside>

      {/* Main content */}
      <div className="flex-1 min-w-0 h-screen overflow-y-auto">
        <main>
          <Outlet />
        </main>
      </div>
    </div>
  )
}

export default Layout
