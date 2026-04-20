-- Role-Based RLS Policies for Reviews Table
-- This creates a SECURITY DEFINER function to check user roles without exposing auth.users table

-- ============================================================================
-- Create SECURITY DEFINER function to check user role
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT raw_user_meta_data->>'role' 
    FROM auth.users 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Drop existing policies
-- ============================================================================
DROP POLICY IF EXISTS "SA can create reviews" ON reviews;
DROP POLICY IF EXISTS "SA can read own reviews" ON reviews;
DROP POLICY IF EXISTS "EA can read all reviews" ON reviews;
DROP POLICY IF EXISTS "EA can update review status" ON reviews;

-- ============================================================================
-- SA Policies: Can create and read own reviews
-- ============================================================================
CREATE POLICY "SA can create reviews" ON reviews 
  FOR INSERT WITH CHECK (
    get_user_role() = 'solution_architect' AND
    auth.uid() = sa_user_id
  );

CREATE POLICY "SA can read own reviews" ON reviews 
  FOR SELECT USING (
    get_user_role() = 'solution_architect' AND
    auth.uid() = sa_user_id
  );

-- ============================================================================
-- EA Policies: Can read all reviews and update review status
-- ============================================================================
CREATE POLICY "EA can read all reviews" ON reviews 
  FOR SELECT USING (
    get_user_role() = 'enterprise_architect'
  );

CREATE POLICY "EA can update reviews" ON reviews 
  FOR UPDATE USING (
    get_user_role() = 'enterprise_architect'
  );

-- ============================================================================
-- ARB Admin Policies: Can do everything (create, read, update, delete)
-- ============================================================================
CREATE POLICY "ARB Admin can create reviews" ON reviews 
  FOR INSERT WITH CHECK (
    get_user_role() = 'arb_admin'
  );

CREATE POLICY "ARB Admin can read reviews" ON reviews 
  FOR SELECT USING (
    get_user_role() = 'arb_admin'
  );

CREATE POLICY "ARB Admin can update reviews" ON reviews 
  FOR UPDATE USING (
    get_user_role() = 'arb_admin'
  );

CREATE POLICY "ARB Admin can delete reviews" ON reviews 
  FOR DELETE USING (
    get_user_role() = 'arb_admin'
  );
