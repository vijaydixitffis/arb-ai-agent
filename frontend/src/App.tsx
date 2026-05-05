import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useEffect } from 'react'
import { useAuthStore, initializeSession } from './stores/authStore'
import LoginPage from './pages/LoginPage'
import Dashboard from './pages/Dashboard'
import ARBSubmission from './pages/ARBSubmission'
import EARRSubmission from './pages/EARRSubmission'
import ReviewDashboard from './pages/ReviewDashboard'
import ReviewStatus from './pages/ReviewStatus'
import Layout from './components/layout/Layout'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, isInitializing } = useAuthStore()

  if (isInitializing) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="w-8 h-8 border-4 border-gray-200 border-t-blue-600 rounded-full animate-spin" />
      </div>
    )
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  return <>{children}</>
}

function App() {
  const { user, logout, recordActivity, isSessionTimedOut } = useAuthStore()

  useEffect(() => {
    initializeSession()
  }, [])

  // Global activity tracking and inactivity-based session expiry
  useEffect(() => {
    if (!user) return

    const EVENTS = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'] as const
    let debounceTimer: ReturnType<typeof setTimeout> | null = null

    const handleActivity = () => {
      // Debounce to avoid hammering localStorage on every mousemove
      if (debounceTimer) return
      debounceTimer = setTimeout(() => {
        recordActivity()
        debounceTimer = null
      }, 5_000)
    }

    EVENTS.forEach(e => window.addEventListener(e, handleActivity, { passive: true }))

    // Check session expiry every 30 seconds while the tab is open
    const expiryCheck = setInterval(() => {
      if (isSessionTimedOut()) {
        logout()
      }
    }, 30_000)

    return () => {
      EVENTS.forEach(e => window.removeEventListener(e, handleActivity))
      if (debounceTimer) clearTimeout(debounceTimer)
      clearInterval(expiryCheck)
    }
  }, [user])

  return (
    <BrowserRouter basename="/arb-ai-agent">
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
            <ProtectedRoute>
              <ARBSubmission />
            </ProtectedRoute>
          } />
          <Route path="earr/new" element={
            <ProtectedRoute>
              <EARRSubmission />
            </ProtectedRoute>
          } />
          <Route path="earr/edit/:reviewId" element={
            <ProtectedRoute>
              <EARRSubmission />
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
