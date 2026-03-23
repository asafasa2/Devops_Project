import React, { useEffect, useRef, useState } from 'react'
import { Terminal as XTerm } from 'xterm'
import { FitAddon } from 'xterm-addon-fit'
import 'xterm/css/xterm.css'

interface TerminalProps {
  ttydUrl?: string
  sessionId?: string
  onDisconnect?: () => void
}

const Terminal: React.FC<TerminalProps> = ({ sessionId, onDisconnect }) => {
  const containerRef = useRef<HTMLDivElement>(null)
  const wrapperRef = useRef<HTMLDivElement>(null)
  const termRef = useRef<XTerm | null>(null)
  const wsRef = useRef<WebSocket | null>(null)
  const [isFullscreen, setIsFullscreen] = useState(false)

  useEffect(() => {
    const handleFsChange = () => {
      setIsFullscreen(!!document.fullscreenElement)
    }
    document.addEventListener('fullscreenchange', handleFsChange)
    return () => document.removeEventListener('fullscreenchange', handleFsChange)
  }, [])

  const toggleFullscreen = () => {
    if (!wrapperRef.current) return
    if (document.fullscreenElement) {
      document.exitFullscreen()
    } else {
      wrapperRef.current.requestFullscreen()
    }
  }

  useEffect(() => {
    if (!containerRef.current || !sessionId) return

    const term = new XTerm({
      cursorBlink: true,
      theme: {
        background: '#0f172a',
        foreground: '#e2e8f0',
        cursor: '#06b6d4',
        selectionBackground: '#334155',
      },
      fontFamily: '"JetBrains Mono", "Fira Code", monospace',
      fontSize: 14,
    })
    const fitAddon = new FitAddon()
    term.loadAddon(fitAddon)
    term.open(containerRef.current)
    fitAddon.fit()
    term.focus()
    termRef.current = term

    const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const ws = new WebSocket(`${proto}//${window.location.hostname}:8000/labs/${sessionId}/ws`)
    ws.binaryType = 'arraybuffer'
    wsRef.current = ws

    ws.onmessage = (event: MessageEvent) => {
      term.write(new Uint8Array(event.data as ArrayBuffer))
    }

    ws.onclose = () => {
      term.write('\r\n\x1b[31m[Connection closed]\x1b[0m\r\n')
      onDisconnect?.()
    }

    ws.onerror = () => {
      term.write('\r\n\x1b[31m[Connection error]\x1b[0m\r\n')
    }

    const encoder = new TextEncoder()
    term.onData((data) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(encoder.encode(data))
      }
    })

    term.onResize(({ cols, rows }) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'resize', cols, rows }))
      }
    })

    let resizeTimer: ReturnType<typeof setTimeout>
    const resizeObserver = new ResizeObserver(() => {
      clearTimeout(resizeTimer)
      resizeTimer = setTimeout(() => {
        try { fitAddon.fit() } catch (_) { /* ignore */ }
      }, 100)
    })
    resizeObserver.observe(containerRef.current)

    return () => {
      clearTimeout(resizeTimer)
      resizeObserver.disconnect()
      ws.close()
      term.dispose()
    }
  }, [sessionId])

  return (
    <div ref={wrapperRef} className="relative w-full h-full bg-[#0f172a]">
      <button
        onClick={toggleFullscreen}
        className="absolute top-2 right-2 z-10 text-slate-500 hover:text-slate-300 bg-slate-800/80 hover:bg-slate-700/80 rounded px-2 py-1 text-xs transition-colors"
        title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
      >
        {isFullscreen ? '⊡' : '⊞'}
      </button>
      <div
        ref={containerRef}
        style={{ width: '100%', height: '100%', minHeight: '400px' }}
      />
    </div>
  )
}

export default Terminal
