-- ============================================================================
-- Consolidated RLS Fix Script (Migrations 012-032)
-- ============================================================================
-- This script consolidates all changes from migrations 012-032 into a
-- single clean migration. The final state is:
-- - Users table recreated without foreign key constraint
-- - RLS disabled on reviews and users tables
-- - All triggers and views dropped
-- - Foreign key constraints on reviews table dropped
-- - Permissions granted to authenticated, anon, and public roles
-- ============================================================================

-- ============================================================================
-- DROP EXISTING POLICIES, FUNCTIONS, AND TRIGGERS
-- ============================================================================

-- Drop all existing policies on reviews table
DROP POLICY IF EXISTS "All authenticated users can read reviews" ON reviews;
DROP POLICY IF EXISTS "All authenticated users can insert reviews" ON reviews;
DROP POLICY IF EXISTS "All authenticated users can update reviews" ON reviews;
DROP POLICY IF EXISTS "SA can read own reviews" ON reviews;
DROP POLICY IF EXISTS "SA can read own reviews, EA and ARB Admin can read all reviews" ON reviews;
DROP POLICY IF EXISTS "EA and ARB Admin can read all reviews" ON reviews;
DROP POLICY IF EXISTS "EA and ARB Admin can update reviews" ON reviews;
DROP POLICY IF EXISTS "SA can insert reviews" ON reviews;
DROP POLICY IF EXISTS "SA can update own reviews" ON reviews;

-- Drop all existing policies on users table
DROP POLICY IF EXISTS "Allow authenticated users to read users" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Drop helper functions
DROP FUNCTION IF EXISTS get_user_role(UUID);
DROP FUNCTION IF EXISTS check_user_role(UUID, TEXT);
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS log_review_status_change() CASCADE;

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_review_status_change ON reviews;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- ============================================================================
-- DROP VIEWS AND MATERIALIZED VIEWS
-- ============================================================================

DROP VIEW IF EXISTS reviews_with_users CASCADE;
DROP VIEW IF EXISTS reviews_with_roles CASCADE;
DROP VIEW IF EXISTS reviews_view CASCADE;
DROP MATERIALIZED VIEW IF EXISTS reviews_summary CASCADE;

-- ============================================================================
-- RECREATE USERS TABLE WITHOUT FOREIGN KEY CONSTRAINT
-- ============================================================================

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  user_name TEXT,
  role TEXT NOT NULL DEFAULT 'solution_architect' CHECK (role IN ('solution_architect', 'enterprise_architect', 'arb_admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Disable RLS on users table
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Insert users from auth.users
INSERT INTO users (id, email, user_name, role)
SELECT 
  id,
  email,
  COALESCE(raw_user_meta_data->>'name', split_part(email, '@', 1)),
  COALESCE(
    raw_user_meta_data->>'role',
    CASE 
      WHEN email LIKE '%sa%' THEN 'solution_architect'
      WHEN email LIKE '%ea%' THEN 'enterprise_architect'
      WHEN email LIKE '%admin%' THEN 'arb_admin'
      ELSE 'solution_architect'
    END
  )
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- DISABLE RLS ON REVIEWS TABLE
-- ============================================================================

ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DROP FOREIGN KEY CONSTRAINTS ON REVIEWS TABLE
-- ============================================================================

ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_sa_user_id_fkey;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_ea_user_id_fkey;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant permissions on reviews table
GRANT SELECT, INSERT, UPDATE ON reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE ON reviews TO anon;
GRANT SELECT, INSERT, UPDATE ON reviews TO public;

-- Grant permissions on users table
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON users TO anon;
GRANT SELECT, INSERT, UPDATE ON users TO public;

-- Grant permissions on auth.users table
GRANT SELECT ON auth.users TO authenticated;

-- Grant permissions on related tables
GRANT SELECT ON actions TO authenticated;
GRANT SELECT ON adrs TO authenticated;
GRANT SELECT ON domain_scores TO authenticated;
GRANT SELECT ON findings TO authenticated;
