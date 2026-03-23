---
name: ttyd-terminal
description: >
  Building and debugging the xterm.js terminal frontend and its WebSocket connection to ttyd.
  Use this skill whenever working on Terminal.jsx, LabPanel.jsx, xterm.js configuration,
  WebSocket connection handling, terminal resizing, reconnection logic, or the split-pane
  layout (instructions + terminal side by side). Also trigger for frontend Lab.jsx page,
  terminal styling, font/theme settings, or any issue with the browser terminal not connecting.
---

# Terminal Frontend Skill

Covers xterm.js setup, ttyd WebSocket protocol, and the lab UI layout.

## Terminal.jsx Component

```jsx
import { useEffect, useRef } from 'react';
import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';
import { WebLinksAddon } from '@xterm/addon-web-links';
import '@xterm/xterm/css/xterm.css';

export default function TerminalComponent({ wsUrl, onDisconnect }) {
  const termRef = useRef(null);
  const termInstanceRef = useRef(null);

  useEffect(() => {
    if (!wsUrl || termInstanceRef.current) return;

    const term = new Terminal({
      cursorBlink: true,
      fontSize: 14,
      fontFamily: "'JetBrains Mono', 'Fira Code', monospace",
      theme: {
        background: '#1e1e2e',
        foreground: '#cdd6f4',
      },
    });

    const fitAddon = new FitAddon();
    term.loadAddon(fitAddon);
    term.loadAddon(new WebLinksAddon());
    term.open(termRef.current);
    fitAddon.fit();

    // ttyd uses a simple WebSocket text protocol
    const ws = new WebSocket(wsUrl);
    ws.binaryType = 'arraybuffer';

    ws.onopen = () => {
      // ttyd protocol: send '0' + JSON for resize, '1' + data for input
      const resizeMsg = JSON.stringify({ columns: term.cols, rows: term.rows });
      ws.send('0' + resizeMsg);
    };

    ws.onmessage = (event) => {
      // ttyd sends: '0' + output data
      if (typeof event.data === 'string') {
        term.write(event.data.slice(1));
      } else {
        const data = new Uint8Array(event.data);
        if (data[0] === 0) {
          term.write(data.slice(1));
        }
      }
    };

    ws.onclose = () => onDisconnect?.();

    term.onData((data) => ws.send('1' + data));
    term.onResize(({ cols, rows }) => {
      ws.send('0' + JSON.stringify({ columns: cols, rows: rows }));
    });

    // Handle window resize
    const handleResize = () => fitAddon.fit();
    window.addEventListener('resize', handleResize);

    termInstanceRef.current = term;

    return () => {
      window.removeEventListener('resize', handleResize);
      ws.close();
      term.dispose();
      termInstanceRef.current = null;
    };
  }, [wsUrl]);

  return <div ref={termRef} className="h-full w-full" />;
}
```

## ttyd WebSocket Protocol

ttyd uses a simple framing protocol over WebSocket:
- Client→Server: `'0' + JSON` = resize event, `'1' + text` = user input
- Server→Client: `'0' + data` = terminal output

The WebSocket URL from the backend is: `ws://hostname:{port}/ws`

## LabPanel.jsx Layout

Split-pane: instructions (Markdown) on the left, terminal on the right.
Use CSS grid or flexbox — no external splitter library.

```
┌──────────────────────┬──────────────────────┐
│   Instructions (MD)  │    Terminal (xterm)   │
│                      │                       │
│   [Validate] button  │                       │
│   [Hint] button      │                       │
└──────────────────────┴──────────────────────┘
```

## Reconnection Logic

If WebSocket closes unexpectedly:
1. Show a "Disconnected" overlay on the terminal
2. Attempt reconnect every 3 seconds, up to 5 times
3. After 5 failures, show "Lab session expired. Start a new lab."
4. Never auto-start a new lab — user must click explicitly

## NPM Dependencies

```json
{
  "@xterm/xterm": "^5.5.0",
  "@xterm/addon-fit": "^0.10.0",
  "@xterm/addon-web-links": "^0.11.0"
}
```

Bundle these locally — no CDN imports at runtime (offline-first).

## Common Issues

- **Terminal shows nothing:** Check that ttyd is actually running and the port is correct
- **Garbled output:** Ensure `ws.binaryType = 'arraybuffer'` is set
- **Terminal doesn't resize:** FitAddon must be loaded before `term.open()`
- **Fonts look bad:** Bundle JetBrains Mono locally in the frontend assets
