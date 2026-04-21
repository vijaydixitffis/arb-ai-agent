-- ============================================================================
-- Fix Reviews Table Read Policy for PostgreSQL
-- ============================================================================
-- This migration updates the read policy to restrict SA users to only read
-- their own reviews, while EA and ARB Admin can read all reviews
-- ============================================================================

-- Drop the incorrect "All authenticated users can read reviews" policy
DROP POLICY IF EXISTS "All authenticated users can read reviews" ON reviews;

-- Drop existing policy if it exists (from 003_ai_agent_tables_rls.sql)
DROP POLICY IF EXISTS "SA can read own reviews" ON reviews;
DROP POLICY IF EXISTS "EA and ARB Admin can read all reviews" ON reviews;
DROP POLICY IF EXISTS "SA can read own reviews, EA and ARB Admin can read all reviews" ON reviews;

-- Create new policy: SA can read own reviews, EA and ARB Admin can read all reviews
CREATE POLICY "SA can read own reviews, EA and ARB Admin can read all reviews"
ON reviews FOR SELECT
USING (
  -- EA and ARB Admin can read all reviews
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
  OR
  -- SA can only read their own reviews
  current_setting('app.current_user_id', true)::uuid = sa_user_id
);
