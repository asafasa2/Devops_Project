import api from './api'
import { LoginRequest, RegisterRequest, AuthResponse, User } from '../types'
import { setAuthToken, setCurrentUser, removeAuthToken, removeCurrentUser } from '../utils/auth'

export const authService = {
  async login(credentials: LoginRequest): Promise<AuthResponse> {
    try {
      const response = await api.post<AuthResponse>('/auth/login', credentials)
      const { user, token } = response.data
      
      setAuthToken(token)
      setCurrentUser(user)
      
      return response.data
    } catch (error) {
      throw error
    }
  },

  async register(userData: RegisterRequest): Promise<AuthResponse> {
    try {
      const response = await api.post<AuthResponse>('/auth/register', userData)
      const { user, token } = response.data
      
      setAuthToken(token)
      setCurrentUser(user)
      
      return response.data
    } catch (error) {
      throw error
    }
  },

  async logout(): Promise<void> {
    try {
      await api.post('/auth/logout')
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      removeAuthToken()
      removeCurrentUser()
    }
  },

  async getCurrentUser(): Promise<User> {
    try {
      const response = await api.get<User>('/auth/me')
      return response.data
    } catch (error) {
      throw error
    }
  },

  async updateProfile(userData: Partial<User>): Promise<User> {
    try {
      const response = await api.put<User>('/auth/profile', userData)
      setCurrentUser(response.data)
      return response.data
    } catch (error) {
      throw error
    }
  },

  async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    try {
      await api.post('/auth/change-password', {
        currentPassword,
        newPassword
      })
    } catch (error) {
      throw error
    }
  },

  async requestPasswordReset(email: string): Promise<void> {
    try {
      await api.post('/auth/forgot-password', { email })
    } catch (error) {
      throw error
    }
  },

  async resetPassword(token: string, newPassword: string): Promise<void> {
    try {
      await api.post('/auth/reset-password', { token, newPassword })
    } catch (error) {
      throw error
    }
  }
}