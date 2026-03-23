import React, { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
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

const SUBJECT_META: Record<string, { label: string; icon: string; color: string; description: string }> = {
  linux:      { label: 'Linux',      icon: '>_', color: '#60a5fa', description: 'Master systemd services, storage management, file permissions, process control, bash scripting, cron scheduling, and user administration.' },
  networking: { label: 'Networking',  icon: '⛓',  color: '#a78bfa', description: 'Configure iptables firewalls, fix routing tables, manage DNS resolution, and set up TLS certificates with OpenSSL.' },
  cicd:       { label: 'CI/CD',      icon: '⟳',  color: '#f87171', description: 'Build and fix CI/CD pipelines, write Jenkinsfiles, manage secrets securely, and handle build artifacts.' },
  terraform:  { label: 'Terraform',  icon: '▦',  color: '#34d399', description: 'Write HCL configurations, use the Docker provider, manage variables/outputs, and understand Terraform state.' },
  ansible:    { label: 'Ansible',    icon: '⚙',  color: '#f9a8d4', description: 'Create inventories, write playbooks, build reusable roles with handlers and templates.' },
  monitoring: { label: 'Monitoring', icon: '◉',  color: '#fb923c', description: 'Configure Prometheus scraping, write alerting rules, and build Grafana dashboards.' },
  security:   { label: 'Security',   icon: '⛊',  color: '#fbbf24', description: 'Harden SSH, configure nftables firewalls, set up auditd monitoring, and apply CIS benchmarks.' },
}

const DIFFICULTY_COLOR: Record<string, string> = {
  beginner: '#4ade80',
  intermediate: '#facc15',
  advanced: '#f87171',
}

const DIFFICULTY_STARS: Record<string, number> = {
  beginner: 1,
  intermediate: 2,
  advanced: 3,
}

const Subject: React.FC = () => {
  const { subjectId } = useParams<{ subjectId: string }>()
  const [labs, setLabs] = useState<LabDefinition[]>([])
  const [progress, setProgress] = useState<Record<string, boolean>>({})
  const [loading, setLoading] = useState(true)

  const meta = SUBJECT_META[subjectId ?? '']

  useEffect(() => {
    Promise.all([
      api.get<LabDefinition[]>('/labs/definitions'),
      api.get<LabProgress[]>('/progress'),
    ]).then(([labsRes, progRes]) => {
      setLabs(labsRes.data.filter(l => l.subject === subjectId))
      const map: Record<string, boolean> = {}
      for (const p of progRes.data) if (p.completed) map[p.lab_id] = true
      setProgress(map)
    }).catch(() => {}).finally(() => setLoading(false))
  }, [subjectId])

  if (!meta) {
    return (
      <div className="max-w-4xl mx-auto px-6 py-10">
        <p className="text-slate-400">Subject not found.</p>
        <Link to="/" className="text-blue-400 hover:text-blue-300 text-sm no-underline mt-4 inline-block">
          ← Back to Dashboard
        </Link>
      </div>
    )
  }

  const completed = labs.filter(l => progress[l.id]).length
  const pct = labs.length > 0 ? (completed / labs.length) * 100 : 0

  return (
    <div className="max-w-4xl mx-auto px-6 py-10 animate-fade-in">
      {/* Breadcrumb */}
      <Link to="/" className="text-slate-500 hover:text-slate-300 text-xs no-underline transition-colors mb-6 inline-block">
        ← Dashboard
      </Link>

      {/* Subject header */}
      <div className="glass-card rounded-2xl p-8 mb-8" style={{ borderLeft: `4px solid ${meta.color}` }}>
        <div className="flex items-start gap-4">
          <span className="text-3xl" style={{ color: meta.color }}>{meta.icon}</span>
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-white mb-2">{meta.label}</h1>
            <p className="text-slate-400 text-sm mb-4">{meta.description}</p>
            <div className="flex items-center gap-3">
              <div className="w-40 h-2 bg-slate-800 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{ width: `${pct}%`, backgroundColor: meta.color }}
                />
              </div>
              <span className="text-sm text-slate-400">{completed}/{labs.length} completed</span>
              {pct === 100 && <span className="text-green-400 text-sm font-bold">Complete!</span>}
            </div>
          </div>
        </div>
      </div>

      {/* Lab list */}
      {loading ? (
        <div className="space-y-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="glass-card rounded-xl p-6 animate-pulse">
              <div className="h-4 w-60 bg-slate-700 rounded mb-3" />
              <div className="h-3 w-32 bg-slate-700/50 rounded" />
            </div>
          ))}
        </div>
      ) : (
        <div className="space-y-3">
          {labs.map((lab, idx) => {
            const done = progress[lab.id]
            const stars = DIFFICULTY_STARS[lab.difficulty] ?? 1
            const diffColor = DIFFICULTY_COLOR[lab.difficulty] ?? '#e2e8f0'

            return (
              <Link
                key={lab.id}
                to={`/lab/${lab.id}`}
                className="glass-card rounded-xl p-5 flex items-center gap-4 no-underline group transition-all duration-200 hover:scale-[1.005] hover:shadow-lg"
                style={{ borderLeft: `3px solid ${done ? '#4ade80' : meta.color}` }}
              >
                {/* Step number */}
                <div className={`
                  w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold shrink-0
                  ${done ? 'bg-green-500/20 text-green-400' : 'bg-slate-800 text-slate-400'}
                `}>
                  {done ? '✓' : idx + 1}
                </div>

                {/* Lab info */}
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-semibold text-white group-hover:text-cyan-200 transition-colors truncate">
                    {lab.title}
                  </h3>
                  <div className="flex items-center gap-3 mt-1 text-xs text-slate-400">
                    <span style={{ color: diffColor }}>
                      {Array.from({ length: stars }).map((_, i) => <span key={i}>★</span>)}
                      {Array.from({ length: 3 - stars }).map((_, i) => <span key={i} className="opacity-20">★</span>)}
                    </span>
                    <span>⏱ {lab.estimated_minutes}m</span>
                    {lab.editor_enabled && (
                      <span className="text-blue-400 bg-blue-500/10 px-1.5 py-0.5 rounded text-[10px]">IDE</span>
                    )}
                  </div>
                </div>

                {/* Arrow */}
                <span className="text-slate-600 group-hover:text-slate-300 transition-colors text-lg shrink-0">→</span>
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}

export default Subject
