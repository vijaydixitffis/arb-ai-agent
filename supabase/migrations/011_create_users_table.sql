-- ============================================================================
-- Create Users Table for Supabase
-- ============================================================================
-- This migration creates a custom users table in the public schema that
-- syncs with auth.users and stores additional user information like role
-- ============================================================================

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  user_name TEXT,
  role TEXT NOT NULL DEFAULT 'solution_architect' CHECK (role IN ('solution_architect', 'enterprise_architect', 'arb_admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read the users table
CREATE POLICY "All authenticated users can read users"
ON users FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id);

-- Allow users to insert their own profile (triggered by auth.users creation)
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Create trigger to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, user_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'solution_architect')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Seed default users for testing (these will only work if auth.users entries exist)
-- Note: In production, users should be created through Supabase Auth
INSERT INTO users (id, email, user_name, role)
SELECT 
  id,
  email,
  split_part(email, '@', 1),
  CASE 
    WHEN email LIKE '%sa%' THEN 'solution_architect'
    WHEN email LIKE '%ea%' THEN 'enterprise_architect'
    WHEN email LIKE '%admin%' THEN 'arb_admin'
    ELSE 'solution_architect'
  END
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  user_name = EXCLUDED.user_name;
