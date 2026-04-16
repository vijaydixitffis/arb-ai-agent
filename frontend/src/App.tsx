import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import LoginPage from './pages/LoginPage'
import Dashboard from './pages/Dashboard'
import ARBSubmission from './pages/ARBSubmission'
import ReviewDashboard from './pages/ReviewDashboard'
import Layout from './components/layout/Layout'

function LocationLogger() {
  const location = useLocation()
  console.log('Current location:', location.pathname)
  return null
}

function ProtectedRoute({ children, allowedRoles }: { children: React.ReactNode, allowedRoles?: string[] }) {
  const { user } = useAuthStore()
  console.log('ProtectedRoute - user:', user, 'allowedRoles:', allowedRoles)
  
  if (!user) {
    console.log('ProtectedRoute - redirecting to /login')
    return <Navigate to="/login" replace />
  }
  
  if (allowedRoles && !allowedRoles.includes(user.role)) {
    console.log('ProtectedRoute - redirecting to /dashboard (role not allowed)')
    return <Navigate to="/dashboard" replace />
  }
  
  console.log('ProtectedRoute - rendering children')
  return <>{children}</>
}

function App() {
  console.log('App component rendering')
  return (
    <BrowserRouter>
      <LocationLogger />
      <Routes>
        <Route path="/login" element={
          <>
            {console.log('Rendering /login route')}
            <LoginPage />
          </>
        } />
        <Route path="/" element={
          <>
            {console.log('Rendering / route with ProtectedRoute')}
            <ProtectedRoute>
              <Layout />
            </ProtectedRoute>
          </>
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
