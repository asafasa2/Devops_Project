// User types
export interface User {
  id: number
  username: string
  email: string
  learning_progress: Record<string, any>
  current_level: 'beginner' | 'intermediate' | 'advanced'
  total_points: number
  created_at: string
  updated_at: string
}

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  username: string
  email: string
  password: string
}

export interface AuthResponse {
  user: User
  token: string
}

// Learning content types
export interface LearningContent {
  id: number
  title: string
  content_type: 'module' | 'quiz' | 'lab'
  tool_category: 'docker' | 'ansible' | 'terraform' | 'jenkins' | 'git'
  difficulty_level: 'beginner' | 'intermediate' | 'advanced'
  content_data: Record<string, any>
  prerequisites: string[]
  estimated_duration: number
  created_at: string
}

// Assessment types
export interface Assessment {
  id: number
  user_id: number
  content_id: number
  score: number
  max_score: number
  completion_time: number
  answers: Record<string, any>
  completed_at: string
}

// Lab session types
export interface LabSession {
  id: number
  user_id: number
  lab_type: string
  container_id?: string
  status: 'active' | 'completed' | 'failed'
  start_time: string
  end_time?: string
  lab_data: Record<string, any>
}

// API response types
export interface ApiResponse<T> {
  data: T
  message?: string
  success: boolean
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
  totalPages: number
}