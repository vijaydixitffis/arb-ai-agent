import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { useEffect } from 'react'
import { useAuthStore } from './stores/authStore'
import LoginPage from './pages/LoginPage'
import Dashboard from './pages/Dashboard'
import ARBSubmission from './pages/ARBSubmission'
import ReviewDashboard from './pages/ReviewDashboard'
import ReviewStatus from './pages/ReviewStatus'
import Layout from './components/layout/Layout'

function LocationLogger() {
  const location = useLocation()
  console.log('Current location:', location.pathname)
  return null
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user } = useAuthStore()
  console.log('ProtectedRoute - user:', user)
  
  if (!user) {
    console.log('ProtectedRoute - redirecting to /login')
    return <Navigate to="/login" replace />
  }
  
  console.log('ProtectedRoute - rendering children')
  return <>{children}</>
}

function App() {
  const initializeSupabaseSession = useAuthStore((state) => state.initializeSupabaseSession)
  
  useEffect(() => {
    // Initialize Supabase session on app load
    initializeSupabaseSession()
  }, [initializeSupabaseSession])

  console.log('App component rendering')
  return (
    <BrowserRouter basename="/arb-ai-agent">
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
            <ProtectedRoute>
              <ARBSubmission />
            </ProtectedRoute>
          } />
          <Route path="review/:submissionId" element={
            <ProtectedRoute>
              <ReviewDashboard />
            </ProtectedRoute>
          } />
          <Route path="review-status/:reviewId" element={<ReviewStatus />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App
