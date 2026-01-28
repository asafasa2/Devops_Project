import api from './api'
import { LabSession } from '../types'

export interface LabTemplate {
  id: string
  name: string
  description: string
  tool: string
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  estimatedTime: number
  image: string
  ports: number[]
  environment: Record<string, string>
  instructions: string
}

export interface CreateLabRequest {
  templateId: string
  name?: string
}

export const labService = {
  async getLabTemplates(): Promise<LabTemplate[]> {
    try {
      const response = await api.get<LabTemplate[]>('/labs/templates')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async createLabSession(request: CreateLabRequest): Promise<LabSession> {
    try {
      const response = await api.post<LabSession>('/labs/sessions', request)
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getActiveLabSessions(): Promise<LabSession[]> {
    try {
      const response = await api.get<LabSession[]>('/labs/sessions/active')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getLabSession(sessionId: number): Promise<LabSession> {
    try {
      const response = await api.get<LabSession>(`/labs/sessions/${sessionId}`)
      return response.data
    } catch (error) {
      throw error
    }
  },

  async stopLabSession(sessionId: number): Promise<void> {
    try {
      await api.post(`/labs/sessions/${sessionId}/stop`)
    } catch (error) {
      throw error
    }
  },

  async getLabHistory(): Promise<LabSession[]> {
    try {
      const response = await api.get<LabSession[]>('/labs/sessions/history')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async executeCommand(sessionId: number, command: string): Promise<{ output: string }> {
    try {
      const response = await api.post(`/labs/sessions/${sessionId}/execute`, { command })
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getLabLogs(sessionId: number): Promise<{ logs: string[] }> {
    try {
      const response = await api.get(`/labs/sessions/${sessionId}/logs`)
      return response.data
    } catch (error) {
      throw error
    }
  }
}