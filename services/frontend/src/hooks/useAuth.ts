import { useState, useEffect } from 'react'
import { User } from '../types'
import { getCurrentUser, isAuthenticated } from '../utils/auth'

export const useAuth = () => {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const checkAuth = () => {
      if (isAuthenticated()) {
        const currentUser = getCurrentUser()
        setUser(currentUser)
      }
      setLoading(false)
    }

    checkAuth()
  }, [])

  return {
    user,
    loading,
    isAuthenticated: !!user,
  }
}