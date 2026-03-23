import axios from 'axios'

export const api = axios.create({
  baseURL: '/api',
  timeout: 60000,  // lab start can take up to 30s+
  headers: {
    'Content-Type': 'application/json',
  },
})

export default api
