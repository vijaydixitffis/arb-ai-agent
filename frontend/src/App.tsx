import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import LoginPage from './pages/LoginPage'
import Dashboard from './pages/Dashboard'
import ARBSubmission from './pages/ARBSubmission'
import ReviewDashboard from './pages/ReviewDashboard'
import Layout from './components/layout/Layout'

function ProtectedRoute({ children, allowedRoles }: { children: React.ReactNode, allowedRoles?: string[] }) {
  const { user } = useAuthStore()
  
  if (!user) {
    return <Navigate to="/login" replace />
  }
  
  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to="/dashboard" replace />
  }
  
  return <>{children}</>
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="submissions" element={<Dashboard />} />
          <Route path="reviews" element={<Dashboard />} />
          <Route path="settings" element={<div className="p-8"><h1 className="text-2xl font-bold">Settings</h1><p className="text-gray-600 mt-2">Settings page coming soon</p></div>} />
          <Route path="submission/new" element={
            <ProtectedRoute allowedRoles={['solution_architect']}>
              <ARBSubmission />
            </ProtectedRoute>
          } />
          <Route path="review/:submissionId" element={
            <ProtectedRoute allowedRoles={['enterprise_architect', 'arb_admin']}>
              <ReviewDashboard />
            </ProtectedRoute>
          } />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App
