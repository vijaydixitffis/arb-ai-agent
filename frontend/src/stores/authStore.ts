import { create } from 'zustand'
import { pythonServices } from '../services/backendConfig'

const BACKEND_TYPE = import.meta.env.VITE_BACKEND_TYPE || 'supabase'

// Only import and initialize Supabase if backend type is supabase
let supabase: any = null
if (BACKEND_TYPE === 'supabase') {
  const { createClient } = require('@supabase/supabase-js')
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY
  supabase = supabaseUrl && supabaseAnonKey 
    ? createClient(supabaseUrl, supabaseAnonKey)
    : null
}

interface User {
  id: string
  email: string
  name: string
  role: string
}

interface AuthState {
  user: User | null
  token: string | null
  authMethod: 'demo' | 'supabase' | 'python' | null
  setAuth: (user: User, token: string, method: 'demo' | 'supabase' | 'python') => void
  logout: () => void
  loginWithSupabase: (email: string, password: string) => Promise<void>
  loginWithPython: (email: string, password: string) => Promise<void>
  initializeSupabaseSession: () => Promise<void>
  initializePythonSession: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: null,
  authMethod: null,
  setAuth: (user, token, method) => set({ user, token, authMethod: method }),
  logout: async () => {
    // Sign out from Supabase if logged in with Supabase
    if (get().authMethod === 'supabase' && supabase) {
      await supabase.auth.signOut()
    }
    // Clear token for Python backend
    if (get().authMethod === 'python') {
      localStorage.removeItem('token')
    }
    set({ user: null, token: null, authMethod: null })
  },
  loginWithSupabase: async (email: string, password: string) => {
    if (!supabase) {
      throw new Error('Supabase is not configured')
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) throw error

    // Get user role from user metadata
    const role = data.user.user_metadata?.role || 'solution_architect'

    set({
      user: {
        id: data.user.id,
        email: data.user.email || '',
        name: data.user.user_metadata?.name || data.user.email?.split('@')[0] || 'User',
        role,
      },
      token: data.session?.access_token || null,
      authMethod: 'supabase',
    })
  },
  loginWithPython: async (email: string, password: string) => {
    try {
      const data = await pythonServices.api.login(email, password)
      
      set({
        user: {
          id: data.user.id,
          email: data.user.email,
          name: data.user.name,
          role: data.user.role,
        },
        token: data.access_token,
        authMethod: 'python',
      })
      
      // Store token in localStorage for Python backend
      localStorage.setItem('token', data.access_token)
    } catch (error) {
      throw error
    }
  },
  initializeSupabaseSession: async () => {
    if (!supabase) return

    const { data: { session } } = await supabase.auth.getSession()

    if (session?.user) {
      const role = session.user.user_metadata?.role || 'solution_architect'
      set({
        user: {
          id: session.user.id,
          email: session.user.email || '',
          name: session.user.user_metadata?.name || session.user.email?.split('@')[0] || 'User',
          role,
        },
        token: session.access_token || null,
        authMethod: 'supabase',
      })
    }
  },
  initializePythonSession: async () => {
    const token = localStorage.getItem('token')
    if (!token) return

    // For Python backend, we would need to validate the token
    // For now, just set the token
    set({
      user: null, // User info would need to be fetched from backend
      token,
      authMethod: 'python',
    })
  },
}))

// Unified login function that uses the configured backend
export const login = async (email: string, password: string) => {
  const authStore = useAuthStore.getState()
  
  if (BACKEND_TYPE === 'python') {
    return await authStore.loginWithPython(email, password)
  } else {
    return await authStore.loginWithSupabase(email, password)
  }
}

// Unified session initialization
export const initializeSession = async () => {
  const authStore = useAuthStore.getState()
  
  if (BACKEND_TYPE === 'python') {
    return await authStore.initializePythonSession()
  } else {
    return await authStore.initializeSupabaseSession()
  }
}
