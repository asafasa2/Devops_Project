import api from './api'
import { LearningContent, Assessment, PaginatedResponse } from '../types'

export const learningService = {
  async getLearningModules(params?: {
    tool_category?: string
    difficulty_level?: string
    page?: number
    limit?: number
  }): Promise<PaginatedResponse<LearningContent>> {
    try {
      const response = await api.get<PaginatedResponse<LearningContent>>('/learning/modules', {
        params
      })
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getLearningModule(id: number): Promise<LearningContent> {
    try {
      const response = await api.get<LearningContent>(`/learning/modules/${id}`)
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getUserProgress(): Promise<Record<string, any>> {
    try {
      const response = await api.get('/learning/progress')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async updateProgress(moduleId: number, progress: any): Promise<void> {
    try {
      await api.post(`/learning/modules/${moduleId}/progress`, progress)
    } catch (error) {
      throw error
    }
  },

  async getRecommendations(): Promise<LearningContent[]> {
    try {
      const response = await api.get<LearningContent[]>('/learning/recommendations')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getUserAssessments(): Promise<Assessment[]> {
    try {
      const response = await api.get<Assessment[]>('/assessments/user')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getLearningPaths(): Promise<any[]> {
    try {
      const response = await api.get('/learning/paths')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async getUserStats(): Promise<{
    totalModulesCompleted: number
    totalTimeSpent: number
    currentStreak: number
    averageScore: number
    toolsProgress: Record<string, number>
  }> {
    try {
      const response = await api.get('/learning/stats')
      return response.data
    } catch (error) {
      throw error
    }
  }
}