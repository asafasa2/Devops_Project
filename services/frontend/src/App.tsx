import { Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import HomePage from './pages/HomePage'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import DashboardPage from './pages/DashboardPage'
import ProfilePage from './pages/ProfilePage'
import ForgotPasswordPage from './pages/ForgotPasswordPage'
import LearningModulePage from './pages/LearningModulePage'
import QuizPage from './pages/QuizPage'
import AssessmentHistoryPage from './pages/AssessmentHistoryPage'
import LabEnvironmentPage from './pages/LabEnvironmentPage'
import LabSessionPage from './pages/LabSessionPage'
import './styles/App.css'

function App() {
  return (
    <div className="App">
      <AuthProvider>
        <Routes>
          <Route path="/" element={<Layout />}>
            <Route index element={<HomePage />} />
            <Route path="login" element={<LoginPage />} />
            <Route path="register" element={<RegisterPage />} />
            <Route path="forgot-password" element={<ForgotPasswordPage />} />
            <Route 
              path="dashboard" 
              element={
                <ProtectedRoute>
                  <DashboardPage />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="profile" 
              element={
                <ProtectedRoute>
                  <ProfilePage />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="learning/modules/:moduleId" 
              element={
                <ProtectedRoute>
                  <LearningModulePage />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="quiz/:quizId" 
              element={
                <ProtectedRoute>
                  <QuizPage />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="assessments" 
              element={
                <ProtectedRoute>
                  <AssessmentHistoryPage />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="labs" 
              element={
                <ProtectedRoute>
                  <LabEnvironmentPage />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="labs/sessions/:sessionId" 
              element={
                <ProtectedRoute>
                  <LabSessionPage />
                </ProtectedRoute>
              } 
            />
          </Route>
        </Routes>
      </AuthProvider>
    </div>
  )
}

export default App