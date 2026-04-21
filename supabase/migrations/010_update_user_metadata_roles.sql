-- ============================================================================
-- Update User Metadata Role Names
-- ============================================================================
-- This migration updates the role field in user metadata to use consistent
-- role names: 'solution_architect', 'enterprise_architect', 'arb_admin'
-- ============================================================================

-- Update user metadata for SA users
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"solution_architect"'
)
WHERE raw_user_meta_data->>'role' = 'sa';

-- Update user metadata for EA users
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"enterprise_architect"'
)
WHERE raw_user_meta_data->>'role' = 'ea';

-- Update user metadata for Admin users
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"arb_admin"'
)
WHERE raw_user_meta_data->>'role' = 'admin';
