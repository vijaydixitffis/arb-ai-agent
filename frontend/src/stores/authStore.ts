import { create } from 'zustand'
import { supabase } from '../services/supabase'

interface User {
  id: string
  email: string
  name: string
  role: string
}

interface AuthState {
  user: User | null
  token: string | null
  setAuth: (user: User, token: string) => void
  logout: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  setAuth: (user, token) => set({ user, token }),
  logout: async () => {
    await supabase.auth.signOut()
    set({ user: null, token: null })
  },
}))
