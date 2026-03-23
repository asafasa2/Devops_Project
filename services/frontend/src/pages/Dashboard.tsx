import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../services/api'

interface LabDefinition {
  id: string
  title: string
  subject: string
  difficulty: string
  estimated_minutes: number
  editor_enabled?: boolean
}

interface LabProgress {
  lab_id: string
  completed: boolean
}

const SUBJECTS = [
  { id: 'linux',      label: 'Linux',      icon: '>_', color: '#60a5fa', desc: 'systemd, storage, permissions, processes, bash' },
  { id: 'networking', label: 'Networking',  icon: '⛓',  color: '#a78bfa', desc: 'iptables, routing, DNS, TLS/PKI' },
  { id: 'cicd',       label: 'CI/CD',      icon: '⟳',  color: '#f87171', desc: 'pipelines, Jenkins, secrets, artifacts' },
  { id: 'terraform',  label: 'Terraform',  icon: '▦',  color: '#34d399', desc: 'HCL, providers, variables, state' },
  { id: 'ansible',    label: 'Ansible',    icon: '⚙',  color: '#f9a8d4', desc: 'inventory, playbooks, roles' },
  { id: 'monitoring', label: 'Monitoring', icon: '◉',  color: '#fb923c', desc: 'Prometheus, Grafana, alerting' },
  { id: 'security',   label: 'Security',   icon: '⛊',  color: '#fbbf24', desc: 'SSH hardening, firewall, auditd, CIS' },
]

const DIFFICULTY_STARS: Record<string, number> = {
  beginner: 1,
  intermediate: 2,
  advanced: 3,
}

const DIFFICULTY_COLOR: Record<string, string> = {
  beginner: '#4ade80',
  intermediate: '#facc15',
  advanced: '#f87171',
}

function ProgressRing({ progress, size = 48, strokeWidth = 4, color }: {
  progress: number, size?: number, strokeWidth?: number, color: string
}) {
  const radius = (size - strokeWidth) / 2
  const circumference = 2 * Math.PI * radius
  const offset = circumference - progress * circumference

  return (
    <svg width={size} height={size} className="shrink-0">
      <circle
        cx={size / 2} cy={size / 2} r={radius}
        fill="none" stroke="#1e293b" strokeWidth={strokeWidth}
      />
      <circle
        cx={size / 2} cy={size / 2} r={radius}
        fill="none" stroke={color} strokeWidth={strokeWidth}
        strokeDasharray={circumference} strokeDashoffset={offset}
        strokeLinecap="round"
        className="progress-ring-circle"
      />
      <text
        x="50%" y="50%" textAnchor="middle" dy="0.35em"
        fill={color} fontSize="11" fontWeight="bold"
      >
        {Math.round(progress * 100)}%
      </text>
    </svg>
  )
}

const Dashboard: React.FC = () => {
  const [labs, setLabs] = useState<LabDefinition[]>([])
  const [progress, setProgress] = useState<Record<string, boolean>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchData = async () => {
    setError(null)
    setLoading(true)
    try {
      const [labsRes, progressRes] = await Promise.all([
        api.get<LabDefinition[]>('/labs/definitions'),
        api.get<LabProgress[]>('/progress'),
      ])
      setLabs(labsRes.data)
      const progressMap: Record<string, boolean> = {}
      for (const p of progressRes.data) {
        if (p.completed) progressMap[p.lab_id] = true
      }
      setProgress(progressMap)
    } catch (err: any) {
      setError(err.message ?? 'Failed to load labs')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchData() }, [])

  const labsBySubject = (subjectId: string) => labs.filter(l => l.subject === subjectId)
  const completedInSubject = (subjectId: string) =>
    labsBySubject(subjectId).filter(l => progress[l.id]).length
  const totalCompleted = Object.values(progress).filter(Boolean).length
  const activeSubjects = SUBJECTS.filter(s => labsBySubject(s.id).length > 0)

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto px-6 py-10">
        <div className="mb-10">
          <div className="h-10 w-72 bg-slate-800 rounded-lg animate-pulse mb-3" />
          <div className="h-4 w-96 bg-slate-800/60 rounded animate-pulse" />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="glass-card rounded-xl p-6 animate-pulse">
              <div className="h-5 w-40 bg-slate-700 rounded mb-4" />
              <div className="h-4 w-full bg-slate-700/50 rounded mb-2" />
              <div className="h-10 w-full bg-slate-700/30 rounded-lg mt-4" />
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="max-w-6xl mx-auto px-6 py-10">
        <div className="bg-red-950/50 border border-red-700/50 text-red-300 rounded-xl p-5 flex items-start gap-3">
          <span className="text-red-400 text-lg mt-0.5">✗</span>
          <div>
            <p className="font-semibold text-red-200 mb-1">Failed to load labs</p>
            <p className="text-sm">{error}</p>
            <button
              onClick={fetchData}
              className="mt-3 px-4 py-1.5 bg-red-700 hover:bg-red-600 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Retry
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-6xl mx-auto px-6 py-10 animate-fade-in">
      {/* Hero */}
      <div className="mb-10">
        <h1 className="text-3xl font-bold mb-2">
          <span className="gradient-text">DevOps Lab Platform</span>
        </h1>
        <p className="text-slate-400 text-base">
          Real Linux environments in your browser. {labs.length} hands-on labs across {activeSubjects.length} subjects.
        </p>
      </div>

      {/* Learning Path Roadmap */}
      <div className="mb-12">
        <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-5">Learning Path</h2>
        <div className="flex items-center gap-1 overflow-x-auto pb-2">
          {activeSubjects.map((subject, idx) => {
            const total = labsBySubject(subject.id).length
            const completed = completedInSubject(subject.id)
            const pct = total > 0 ? completed / total : 0
            const allDone = pct === 1

            return (
              <React.Fragment key={subject.id}>
                <Link
                  to={`/subject/${subject.id}`}
                  className="flex flex-col items-center gap-2 group no-underline shrink-0"
                >
                  <div className={`
                    relative transition-transform duration-200 group-hover:scale-110
                    ${allDone ? 'drop-shadow-[0_0_8px_rgba(74,222,128,0.4)]' : ''}
                  `}>
                    <ProgressRing progress={pct} size={56} strokeWidth={3} color={allDone ? '#4ade80' : subject.color} />
                  </div>
                  <div className="text-center">
                    <div className="text-xs font-semibold text-slate-300 group-hover:text-white transition-colors">
                      {subject.label}
                    </div>
                    <div className="text-[10px] text-slate-500">{completed}/{total}</div>
                  </div>
                </Link>
                {idx < activeSubjects.length - 1 && (
                  <div className={`w-8 h-0.5 shrink-0 mb-6 ${
                    completedInSubject(activeSubjects[idx].id) === labsBySubject(activeSubjects[idx].id).length
                      ? 'bg-green-500/50'
                      : 'bg-slate-700'
                  }`} />
                )}
              </React.Fragment>
            )
          })}
        </div>
      </div>

      {/* Stats bar */}
      <div className="flex gap-3 mb-8">
        <span className="text-xs font-semibold px-3 py-1.5 rounded-full glass-card text-slate-300">
          {labs.length} Labs
        </span>
        <span className="text-xs font-semibold px-3 py-1.5 rounded-full glass-card text-slate-300">
          {totalCompleted} Completed
        </span>
        {totalCompleted > 0 && (
          <span className="text-xs font-semibold px-3 py-1.5 rounded-full glass-card text-green-300">
            {Math.round((totalCompleted / labs.length) * 100)}% Done
          </span>
        )}
      </div>

      {/* Labs grouped by subject */}
      {activeSubjects.map(subject => {
        const subjectLabs = labsBySubject(subject.id)
        const completed = completedInSubject(subject.id)

        return (
          <section key={subject.id} className="mb-10 animate-slide-up">
            {/* Subject header */}
            <div className="flex items-center gap-3 mb-4">
              <span className="text-xl" style={{ color: subject.color }}>{subject.icon}</span>
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <h2 className="text-lg font-bold text-white">{subject.label}</h2>
                  <span className="text-xs text-slate-500">{subject.desc}</span>
                </div>
                <div className="flex items-center gap-2 mt-1">
                  <div className="w-32 h-1 bg-slate-800 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{
                        width: `${subjectLabs.length ? (completed / subjectLabs.length) * 100 : 0}%`,
                        backgroundColor: subject.color,
                      }}
                    />
                  </div>
                  <span className="text-[10px] text-slate-500">{completed}/{subjectLabs.length}</span>
                </div>
              </div>
              <Link
                to={`/subject/${subject.id}`}
                className="text-xs text-slate-500 hover:text-slate-300 no-underline transition-colors"
              >
                View all →
              </Link>
            </div>

            {/* Lab cards */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              {subjectLabs.map((lab) => {
                const done = progress[lab.id]
                const stars = DIFFICULTY_STARS[lab.difficulty] ?? 1
                const diffColor = DIFFICULTY_COLOR[lab.difficulty] ?? '#e2e8f0'

                return (
                  <div
                    key={lab.id}
                    className="glass-card rounded-xl overflow-hidden flex flex-col transition-all duration-200 hover:scale-[1.01] hover:shadow-lg group"
                    style={{ borderLeft: `3px solid ${subject.color}` }}
                  >
                    <div className="p-5 flex flex-col gap-3 flex-1">
                      {/* Top row */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span
                            className="text-[10px] font-bold uppercase px-2 py-0.5 rounded-full"
                            style={{ background: `${subject.color}15`, color: subject.color }}
                          >
                            {lab.subject}
                          </span>
                          {lab.editor_enabled && (
                            <span className="text-[10px] font-medium px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-400">
                              IDE
                            </span>
                          )}
                        </div>
                        {done && (
                          <span className="text-green-400 text-sm font-bold" title="Completed">✓</span>
                        )}
                      </div>

                      {/* Title */}
                      <h3 className="text-white font-semibold text-sm leading-snug m-0 group-hover:text-cyan-200 transition-colors">
                        {lab.title}
                      </h3>

                      {/* Meta */}
                      <div className="flex items-center gap-4 text-xs text-slate-400">
                        <span className="flex items-center gap-1" style={{ color: diffColor }}>
                          {Array.from({ length: stars }).map((_, i) => (
                            <span key={i}>★</span>
                          ))}
                          {Array.from({ length: 3 - stars }).map((_, i) => (
                            <span key={i} className="opacity-20">★</span>
                          ))}
                          <span className="ml-0.5">{lab.difficulty}</span>
                        </span>
                        <span>⏱ {lab.estimated_minutes}m</span>
                      </div>
                    </div>

                    {/* CTA */}
                    <div className="px-5 pb-5">
                      <Link
                        to={`/lab/${lab.id}`}
                        className="block w-full py-2.5 text-center bg-blue-600/80 hover:bg-blue-500 text-white rounded-lg text-sm font-medium no-underline transition-all duration-200"
                      >
                        {done ? 'Redo Lab' : 'Start Lab →'}
                      </Link>
                    </div>
                  </div>
                )
              })}
            </div>
          </section>
        )
      })}
    </div>
  )
}

export default Dashboard
