-- ============================================================================
-- Update SA Update Policy to Include Submitted Status
-- ============================================================================
-- This migration updates the existing policies to allow Solution Architects
-- to update their own reviews when in draft, pending, or submitted status.

-- Drop existing policies
DROP POLICY IF EXISTS "Users can update reviews based on role and status" ON reviews;
DROP POLICY IF EXISTS "Users can update reviews based on role and status (check)" ON reviews;

-- Create comprehensive update policy that includes SA draft, pending, and submitted updates
CREATE POLICY "Users can update reviews based on role and status"
ON reviews FOR UPDATE
USING (
  -- EA and ARB Admin can update any review
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
  OR
  -- SA can update their own reviews only when in draft, pending, or submitted status
  (
    sa_user_id = current_setting('app.current_user_id', true)::uuid
    AND status IN ('draft', 'pending', 'submitted')
    AND EXISTS (
      SELECT 1 FROM users
      WHERE users.id = current_setting('app.current_user_id', true)::uuid
      AND users.role = 'solution_architect'
    )
  )
);

-- Also add WITH CHECK to ensure the same rules apply during update
CREATE POLICY "Users can update reviews based on role and status (check)"
ON reviews FOR UPDATE
WITH CHECK (
  -- EA and ARB Admin can update any review
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
  OR
  -- SA can update their own reviews only when in draft, pending, or submitted status
  (
    sa_user_id = current_setting('app.current_user_id', true)::uuid
    AND status IN ('draft', 'pending', 'submitted')
    AND EXISTS (
      SELECT 1 FROM users
      WHERE users.id = current_setting('app.current_user_id', true)::uuid
      AND users.role = 'solution_architect'
    )
  )
);
