import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import Lab from './pages/Lab'
import Subject from './pages/Subject'
import './styles/App.css'

function App() {
  return (
    <div className="App">
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="subject/:subjectId" element={<Subject />} />
          <Route path="lab/:labId" element={<Lab />} />
        </Route>
      </Routes>
    </div>
  )
}

export default App
