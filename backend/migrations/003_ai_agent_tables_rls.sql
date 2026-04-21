-- ============================================================================
-- RLS Policies for AI Agent Tables
-- ============================================================================
-- AI agent populated tables: reviews, actions, adrs, domain_scores, findings
-- Access Rules:
-- - SA can READ their own reviews only
-- - EA and ARB Admin can READ all reviews
-- - EA and ARB Admin can UPDATE all tables
-- - SA cannot UPDATE these tables
-- ============================================================================

-- Enable RLS on AI agent tables
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE adrs ENABLE ROW LEVEL SECURITY;
ALTER TABLE domain_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE findings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- REVIEWS TABLE RLS
-- ============================================================================

-- SA can read own reviews
CREATE POLICY "SA can read own reviews"
ON reviews FOR SELECT
USING (
  sa_user_id = current_setting('app.current_user_id', true)::uuid
);

-- EA and ARB Admin can read all reviews
CREATE POLICY "EA and ARB Admin can read all reviews"
ON reviews FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
);

-- EA and ARB Admin can update reviews
CREATE POLICY "EA and ARB Admin can update reviews"
ON reviews FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
);

-- SA can insert reviews (create new submissions)
CREATE POLICY "SA can insert reviews"
ON reviews FOR INSERT
WITH CHECK (
  sa_user_id = current_setting('app.current_user_id', true)::uuid
);

-- ============================================================================
-- ACTIONS TABLE RLS
-- ============================================================================

-- Read actions via review ownership
CREATE POLICY "Read actions via review"
ON actions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM reviews
    WHERE reviews.id = actions.review_id
    AND (reviews.sa_user_id = current_setting('app.current_user_id', true)::uuid OR
         EXISTS (
           SELECT 1 FROM users
           WHERE users.id = current_setting('app.current_user_id', true)::uuid
           AND users.role IN ('enterprise_architect', 'arb_admin')
         ))
  )
);

-- EA and ARB Admin can update actions
CREATE POLICY "EA and ARB Admin can update actions"
ON actions FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
);

-- ============================================================================
-- ADRS TABLE RLS
-- ============================================================================

-- Read adrs via review ownership
CREATE POLICY "Read adrs via review"
ON adrs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM reviews
    WHERE reviews.id = adrs.review_id
    AND (reviews.sa_user_id = current_setting('app.current_user_id', true)::uuid OR
         EXISTS (
           SELECT 1 FROM users
           WHERE users.id = current_setting('app.current_user_id', true)::uuid
           AND users.role IN ('enterprise_architect', 'arb_admin')
         ))
  )
);

-- EA and ARB Admin can update adrs
CREATE POLICY "EA and ARB Admin can update adrs"
ON adrs FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
);

-- ============================================================================
-- DOMAIN_SCORES TABLE RLS
-- ============================================================================

-- Read domain_scores via review ownership
CREATE POLICY "Read domain_scores via review"
ON domain_scores FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM reviews
    WHERE reviews.id = domain_scores.review_id
    AND (reviews.sa_user_id = current_setting('app.current_user_id', true)::uuid OR
         EXISTS (
           SELECT 1 FROM users
           WHERE users.id = current_setting('app.current_user_id', true)::uuid
           AND users.role IN ('enterprise_architect', 'arb_admin')
         ))
  )
);

-- EA and ARB Admin can update domain_scores
CREATE POLICY "EA and ARB Admin can update domain_scores"
ON domain_scores FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
);

-- ============================================================================
-- FINDINGS TABLE RLS
-- ============================================================================

-- Read findings via review ownership
CREATE POLICY "Read findings via review"
ON findings FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM reviews
    WHERE reviews.id = findings.review_id
    AND (reviews.sa_user_id = current_setting('app.current_user_id', true)::uuid OR
         EXISTS (
           SELECT 1 FROM users
           WHERE users.id = current_setting('app.current_user_id', true)::uuid
           AND users.role IN ('enterprise_architect', 'arb_admin')
         ))
  )
);

-- EA and ARB Admin can update findings
CREATE POLICY "EA and ARB Admin can update findings"
ON findings FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_setting('app.current_user_id', true)::uuid
    AND users.role IN ('enterprise_architect', 'arb_admin')
  )
);
