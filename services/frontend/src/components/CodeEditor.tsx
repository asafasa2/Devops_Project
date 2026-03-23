import React, { useState, useEffect, useCallback, useRef } from 'react'
import Editor, { loader } from '@monaco-editor/react'
import { api } from '../services/api'
import { useToast } from '../contexts/ToastContext'

// Use bundled Monaco (offline-first)
loader.config({ paths: { vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs' } })

interface FileEntry {
  name: string
  type: 'file' | 'dir'
  size: number
  modified: string
}

interface CodeEditorProps {
  sessionId: string
  defaultPath?: string
}

const LANG_MAP: Record<string, string> = {
  tf: 'hcl',
  hcl: 'hcl',
  yml: 'yaml',
  yaml: 'yaml',
  py: 'python',
  sh: 'shell',
  bash: 'shell',
  groovy: 'groovy',
  json: 'json',
  toml: 'toml',
  ini: 'ini',
  cfg: 'ini',
  conf: 'ini',
  js: 'javascript',
  ts: 'typescript',
  md: 'markdown',
  txt: 'plaintext',
  service: 'ini',
  rules: 'plaintext',
  j2: 'jinja',
}

function getLanguage(filename: string): string {
  const ext = filename.split('.').pop()?.toLowerCase() ?? ''
  return LANG_MAP[ext] || 'plaintext'
}

const CodeEditor: React.FC<CodeEditorProps> = ({ sessionId, defaultPath = '/workspace' }) => {
  const { addToast } = useToast()
  const [files, setFiles] = useState<FileEntry[]>([])
  const [currentPath, setCurrentPath] = useState(defaultPath)
  const [openFile, setOpenFile] = useState<string | null>(null)
  const [content, setContent] = useState('')
  const [originalContent, setOriginalContent] = useState('')
  const [language, setLanguage] = useState('plaintext')
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const editorRef = useRef<any>(null)

  const loadDirectory = useCallback(async (path: string) => {
    try {
      const { data } = await api.get<{ path: string; entries: FileEntry[] }>(`/labs/${sessionId}/files`, {
        params: { path },
      })
      setFiles(data.entries)
      setCurrentPath(path)
    } catch {
      addToast('Failed to load directory', 'error')
    }
  }, [sessionId, addToast])

  useEffect(() => {
    loadDirectory(defaultPath)
  }, [defaultPath, loadDirectory])

  const openFileContent = async (filename: string) => {
    const fullPath = `${currentPath}/${filename}`
    setLoading(true)
    try {
      const { data } = await api.get<{ path: string; content: string; language: string }>(
        `/labs/${sessionId}/files/content`,
        { params: { path: fullPath } },
      )
      setOpenFile(fullPath)
      setContent(data.content)
      setOriginalContent(data.content)
      setLanguage(data.language || getLanguage(filename))
    } catch {
      addToast(`Failed to open ${filename}`, 'error')
    } finally {
      setLoading(false)
    }
  }

  const saveFile = async () => {
    if (!openFile) return
    setSaving(true)
    try {
      await api.put(`/labs/${sessionId}/files/content`, {
        path: openFile,
        content,
      })
      setOriginalContent(content)
      addToast('File saved', 'success')
    } catch {
      addToast('Failed to save file', 'error')
    } finally {
      setSaving(false)
    }
  }

  const handleEditorMount = (editor: any) => {
    editorRef.current = editor
    // Ctrl+S / Cmd+S to save
    editor.addCommand(2048 | 49 /* KeyMod.CtrlCmd | KeyCode.KeyS */, () => {
      saveFile()
    })
  }

  const isModified = content !== originalContent
  const parentPath = currentPath.split('/').slice(0, -1).join('/') || '/'

  return (
    <div className="flex flex-col h-full bg-slate-950">
      {/* File toolbar */}
      <div className="bg-slate-900 border-b border-slate-700/50 px-3 py-1.5 flex items-center gap-2 shrink-0">
        {openFile ? (
          <>
            <span className="text-xs text-slate-400 truncate flex-1">
              {openFile}
              {isModified && <span className="text-yellow-400 ml-1">●</span>}
            </span>
            <button
              onClick={saveFile}
              disabled={saving || !isModified}
              className="px-2.5 py-1 bg-blue-600/80 hover:bg-blue-500 disabled:opacity-40 disabled:cursor-not-allowed text-white text-xs rounded font-medium transition-colors"
            >
              {saving ? 'Saving…' : 'Save'}
            </button>
            <button
              onClick={() => { setOpenFile(null); loadDirectory(currentPath) }}
              className="px-2 py-1 text-slate-400 hover:text-slate-200 text-xs transition-colors"
            >
              Files
            </button>
          </>
        ) : (
          <>
            <span className="text-xs text-slate-400 truncate flex-1">{currentPath}</span>
            {currentPath !== defaultPath && (
              <button
                onClick={() => loadDirectory(parentPath)}
                className="px-2 py-1 text-slate-400 hover:text-slate-200 text-xs transition-colors"
              >
                ↑ Up
              </button>
            )}
            <button
              onClick={() => loadDirectory(currentPath)}
              className="px-2 py-1 text-slate-400 hover:text-slate-200 text-xs transition-colors"
            >
              ↻
            </button>
          </>
        )}
      </div>

      {/* Content area */}
      <div className="flex-1 overflow-hidden">
        {openFile ? (
          loading ? (
            <div className="flex items-center justify-center h-full text-slate-500 text-sm">Loading…</div>
          ) : (
            <Editor
              height="100%"
              language={language}
              value={content}
              onChange={(val) => setContent(val ?? '')}
              onMount={handleEditorMount}
              theme="vs-dark"
              options={{
                minimap: { enabled: false },
                fontSize: 13,
                lineNumbers: 'on',
                scrollBeyondLastLine: false,
                wordWrap: 'on',
                tabSize: 2,
                renderWhitespace: 'selection',
                automaticLayout: true,
              }}
            />
          )
        ) : (
          <div className="overflow-y-auto h-full">
            {files.length === 0 ? (
              <div className="text-slate-500 text-xs text-center py-8">Empty directory</div>
            ) : (
              files.map(f => (
                <button
                  key={f.name}
                  onClick={() => {
                    if (f.type === 'dir') {
                      loadDirectory(`${currentPath}/${f.name}`)
                    } else {
                      openFileContent(f.name)
                    }
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-slate-800/50 transition-colors group"
                >
                  <span className={`text-xs shrink-0 ${f.type === 'dir' ? 'text-blue-400' : 'text-slate-500'}`}>
                    {f.type === 'dir' ? '📁' : '📄'}
                  </span>
                  <span className="text-sm text-slate-300 group-hover:text-white truncate flex-1">
                    {f.name}
                  </span>
                  <span className="text-[10px] text-slate-600">
                    {f.type === 'file' ? `${f.size}B` : ''}
                  </span>
                </button>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  )
}

export default CodeEditor
