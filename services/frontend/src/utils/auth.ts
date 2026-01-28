import { User } from '../types'

export const getAuthToken = (): string | null => {
  return localStorage.getItem('authToken')
}

export const setAuthToken = (token: string): void => {
  localStorage.setItem('authToken', token)
}

export const removeAuthToken = (): void => {
  localStorage.removeItem('authToken')
}

export const getCurrentUser = (): User | null => {
  const userStr = localStorage.getItem('currentUser')
  if (userStr) {
    try {
      return JSON.parse(userStr)
    } catch (error) {
      console.error('Error parsing user data:', error)
      return null
    }
  }
  return null
}

export const setCurrentUser = (user: User): void => {
  localStorage.setItem('currentUser', JSON.stringify(user))
}

export const removeCurrentUser = (): void => {
  localStorage.removeItem('currentUser')
}

export const isAuthenticated = (): boolean => {
  return !!getAuthToken() && !!getCurrentUser()
}

export const logout = (): void => {
  removeAuthToken()
  removeCurrentUser()
  window.location.href = '/login'
}