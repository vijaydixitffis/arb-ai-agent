import { create } from 'zustand'
import { createClient } from '@supabase/supabase-js'

// Initialize Supabase client
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = supabaseUrl && supabaseAnonKey 
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null

interface User {
  id: string
  email: string
  name: string
  role: string
}

interface AuthState {
  user: User | null
  token: string | null
  authMethod: 'demo' | 'supabase' | null
  setAuth: (user: User, token: string, method: 'demo' | 'supabase') => void
  logout: () => void
  loginWithSupabase: (email: string, password: string) => Promise<void>
  initializeSupabaseSession: () => Promise<void>
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
}))
