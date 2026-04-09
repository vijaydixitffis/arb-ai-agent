import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { Button } from '../components/ui/Button'
import { Input } from '../components/ui/Input'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { api } from '../services/api'

const demoUsers = [
  { email: 'sa@arb.demo', password: 'demo1234', role: 'Solution Architect', label: 'Solution Architect' },
  { email: 'ea@arb.demo', password: 'demo1234', role: 'Enterprise Architect', label: 'Enterprise Architect' },
  { email: 'admin@arb.demo', password: 'demo1234', role: 'ARB Admin', label: 'ARB Admin' },
]

export default function LoginPage() {
  const navigate = useNavigate()
  const setAuth = useAuthStore((state) => state.setAuth)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  const handleDemoLogin = (user: typeof demoUsers[0]) => {
    setEmail(user.email)
    setPassword(user.password)
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    try {
      const data = await api.login(email, password)
      setAuth(data.user, data.access_token)
      navigate('/dashboard')
    } catch (err) {
      setError('Invalid credentials. Please try again.')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="text-center">ARB AI Agent</CardTitle>
          <p className="text-center text-muted-foreground">Architecture Review Board</p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-2">Email</label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter your email"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Password</label>
              <Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                required
              />
            </div>
            {error && (
              <div className="text-sm text-destructive">{error}</div>
            )}
            <Button type="submit" className="w-full">
              Sign In
            </Button>
          </form>

          <div className="mt-6">
            <p className="text-sm text-center text-muted-foreground mb-3">Quick Login (Demo)</p>
            <div className="space-y-2">
              {demoUsers.map((user) => (
                <Button
                  key={user.email}
                  variant="outline"
                  className="w-full"
                  onClick={() => handleDemoLogin(user)}
                >
                  {user.label}
                </Button>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
