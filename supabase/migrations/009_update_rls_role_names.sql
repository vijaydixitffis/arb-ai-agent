-- ============================================================================
-- Update RLS Policies to use consistent role names
-- ============================================================================
-- This migration drops existing RLS policies and recreates them with
-- consistent role names: 'solution_architect', 'enterprise_architect', 'arb_admin'
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "All authenticated users can read reviews" ON reviews;
DROP POLICY IF EXISTS "EA and ARB Admin can update reviews" ON reviews;
DROP POLICY IF EXISTS "SA can insert reviews" ON reviews;

DROP POLICY IF EXISTS "All authenticated users can read actions" ON actions;
DROP POLICY IF EXISTS "EA and ARB Admin can update actions" ON actions;

DROP POLICY IF EXISTS "All authenticated users can read adrs" ON adrs;
DROP POLICY IF EXISTS "EA and ARB Admin can update adrs" ON adrs;

DROP POLICY IF EXISTS "All authenticated users can read domain_scores" ON domain_scores;
DROP POLICY IF EXISTS "EA and ARB Admin can update domain_scores" ON domain_scores;

DROP POLICY IF EXISTS "All authenticated users can read findings" ON findings;
DROP POLICY IF EXISTS "EA and ARB Admin can update findings" ON findings;

-- ============================================================================
-- REVIEWS TABLE RLS
-- ============================================================================

-- Allow all authenticated users to read reviews
CREATE POLICY "All authenticated users can read reviews"
ON reviews FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Allow EA and ARB Admin to update reviews
CREATE POLICY "EA and ARB Admin can update reviews"
ON reviews FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' IN ('enterprise_architect', 'arb_admin')
  )
);

-- Allow SA to insert reviews (create new submissions)
CREATE POLICY "SA can insert reviews"
ON reviews FOR INSERT
WITH CHECK (
  auth.uid() = sa_user_id
);

-- ============================================================================
-- ACTIONS TABLE RLS
-- ============================================================================

-- Allow all authenticated users to read actions
CREATE POLICY "All authenticated users can read actions"
ON actions FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Allow EA and ARB Admin to update actions
CREATE POLICY "EA and ARB Admin can update actions"
ON actions FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' IN ('enterprise_architect', 'arb_admin')
  )
);

-- ============================================================================
-- ADRS TABLE RLS
-- ============================================================================

-- Allow all authenticated users to read adrs
CREATE POLICY "All authenticated users can read adrs"
ON adrs FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Allow EA and ARB Admin to update adrs
CREATE POLICY "EA and ARB Admin can update adrs"
ON adrs FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' IN ('enterprise_architect', 'arb_admin')
  )
);

-- ============================================================================
-- DOMAIN_SCORES TABLE RLS
-- ============================================================================

-- Allow all authenticated users to read domain_scores
CREATE POLICY "All authenticated users can read domain_scores"
ON domain_scores FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Allow EA and ARB Admin to update domain_scores
CREATE POLICY "EA and ARB Admin can update domain_scores"
ON domain_scores FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' IN ('enterprise_architect', 'arb_admin')
  )
);

-- ============================================================================
-- FINDINGS TABLE RLS
-- ============================================================================

-- Allow all authenticated users to read findings
CREATE POLICY "All authenticated users can read findings"
ON findings FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Allow EA and ARB Admin to update findings
CREATE POLICY "EA and ARB Admin can update findings"
ON findings FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' IN ('enterprise_architect', 'arb_admin')
  )
);
