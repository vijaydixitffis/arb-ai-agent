-- Add draft and submitted statuses to reviews table constraint
-- This enables the new workflow: draft → submitted → ready for review

-- Drop the existing constraint
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS valid_status;

-- Add new constraint with draft and submitted statuses
ALTER TABLE reviews 
  ADD CONSTRAINT valid_status 
  CHECK (status IN ('draft', 'submitted', 'pending', 'in_review', 'ea_review', 'approved', 'rejected', 'deferred'));
