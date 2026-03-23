import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/api/, ''),
      },
      // WebSocket terminal: /labs/{session_id}/ws → ws://localhost:8000/labs/{session_id}/ws
      '/labs': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        ws: true,
      },
    }
  },
  build: {
    outDir: 'dist'
  }
})