-- Migration 002: AI Agent Schema
-- This migration creates tables for the AI Agent review system

-- ============================================================================
-- MD FILES TABLE (Knowledge Base Metadata)
-- ============================================================================
CREATE TABLE IF NOT EXISTS md_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filename TEXT NOT NULL UNIQUE,
  storage_path TEXT NOT NULL,
  domain_tags TEXT[] NOT NULL,
  content TEXT NOT NULL,
  token_estimate INT,
  priority INT DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  version INT DEFAULT 1,
  file_size_bytes INT,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_md_files_domains ON md_files USING GIN(domain_tags);
CREATE INDEX IF NOT EXISTS idx_md_files_priority ON md_files(priority);
CREATE INDEX IF NOT EXISTS idx_md_files_active ON md_files(is_active) WHERE is_active = true;

-- ============================================================================
-- REVIEWS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  
  sa_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  solution_name TEXT NOT NULL,
  scope_tags TEXT[] NOT NULL,
  artifact_path TEXT NOT NULL,
  artifact_filename TEXT NOT NULL,
  artifact_file_type TEXT,
  artifact_file_size_bytes INT,
  
  status TEXT NOT NULL DEFAULT 'pending',
  decision TEXT,
  
  llm_model TEXT DEFAULT 'gpt-4o',
  tokens_used INT,
  processing_time_ms INT,
  llm_raw_response TEXT,
  
  ea_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ea_override_notes TEXT,
  ea_overridden_at TIMESTAMPTZ,
  
  report_json JSONB,
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'in_review', 'ea_review', 'approved', 'rejected', 'deferred')),
  CONSTRAINT valid_decision CHECK (decision IS NULL OR decision IN ('approve', 'approve_with_conditions', 'defer', 'reject'))
);

CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);
CREATE INDEX IF NOT EXISTS idx_reviews_sa ON reviews(sa_user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_ea ON reviews(ea_user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_scope ON reviews USING GIN(scope_tags);
CREATE INDEX IF NOT EXISTS idx_reviews_submitted ON reviews(submitted_at DESC);

-- ============================================================================
-- DOMAIN SCORES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS domain_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  domain TEXT NOT NULL,
  score INT NOT NULL CHECK (score >= 1 AND score <= 5),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(review_id, domain)
);

CREATE INDEX IF NOT EXISTS idx_domain_scores_review ON domain_scores(review_id);

-- ============================================================================
-- FINDINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  domain TEXT NOT NULL,
  principle_id TEXT,
  severity TEXT NOT NULL CHECK (severity IN ('critical', 'major', 'minor')),
  finding TEXT NOT NULL,
  recommendation TEXT,
  is_resolved BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_findings_review ON findings(review_id);
CREATE INDEX IF NOT EXISTS idx_findings_severity ON findings(severity);
CREATE INDEX IF NOT EXISTS idx_findings_domain ON findings(domain);

-- ============================================================================
-- ADRS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS adrs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  adr_id TEXT NOT NULL,
  decision TEXT NOT NULL,
  rationale TEXT NOT NULL,
  context TEXT,
  consequences TEXT,
  owner TEXT,
  target_date DATE,
  status TEXT DEFAULT 'proposed' CHECK (status IN ('proposed', 'accepted', 'rejected', 'superseded')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_adrs_review ON adrs(review_id);
CREATE INDEX IF NOT EXISTS idx_adrs_status ON adrs(status);

-- ============================================================================
-- ACTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  action_text TEXT NOT NULL,
  owner_role TEXT NOT NULL,
  due_days INT,
  due_date DATE,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'blocked')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_actions_review ON actions(review_id);
CREATE INDEX IF NOT EXISTS idx_actions_status ON actions(status);
CREATE INDEX IF NOT EXISTS idx_actions_due ON actions(due_date);

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_role TEXT,
  action TEXT NOT NULL,
  old_status TEXT,
  new_status TEXT,
  old_decision TEXT,
  new_decision TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_review ON audit_log(review_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

ALTER TABLE md_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE domain_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE adrs ENABLE ROW LEVEL SECURITY;
ALTER TABLE actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- md_files policies
DROP POLICY IF EXISTS "Public read access for md_files" ON md_files;
CREATE POLICY "Public read access for md_files" ON md_files 
  FOR SELECT USING (true);

-- reviews policies
DROP POLICY IF EXISTS "SA can create reviews" ON reviews;
CREATE POLICY "SA can create reviews" ON reviews 
  FOR INSERT WITH CHECK (auth.uid() = sa_user_id);

DROP POLICY IF EXISTS "SA can read own reviews" ON reviews;
CREATE POLICY "SA can read own reviews" ON reviews 
  FOR SELECT USING (auth.uid() = sa_user_id);

DROP POLICY IF EXISTS "EA can read all reviews" ON reviews;
CREATE POLICY "EA can read all reviews" ON reviews 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'ea'
    )
  );

DROP POLICY IF EXISTS "EA can update review status" ON reviews;
CREATE POLICY "EA can update review status" ON reviews 
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'ea'
    )
  );

-- domain_scores policies
DROP POLICY IF EXISTS "Read domain_scores via review" ON domain_scores;
CREATE POLICY "Read domain_scores via review" ON domain_scores 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reviews 
      WHERE reviews.id = domain_scores.review_id 
      AND (reviews.sa_user_id = auth.uid() OR 
           EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'ea'
           ))
    )
  );

-- findings policies
DROP POLICY IF EXISTS "Read findings via review" ON findings;
CREATE POLICY "Read findings via review" ON findings 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reviews 
      WHERE reviews.id = findings.review_id 
      AND (reviews.sa_user_id = auth.uid() OR 
           EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'ea'
           ))
    )
  );

-- adrs policies
DROP POLICY IF EXISTS "Read adrs via review" ON adrs;
CREATE POLICY "Read adrs via review" ON adrs 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reviews 
      WHERE reviews.id = adrs.review_id 
      AND (reviews.sa_user_id = auth.uid() OR 
           EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'ea'
           ))
    )
  );

-- actions policies
DROP POLICY IF EXISTS "Read actions via review" ON actions;
CREATE POLICY "Read actions via review" ON actions 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reviews 
      WHERE reviews.id = actions.review_id 
      AND (reviews.sa_user_id = auth.uid() OR 
           EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'ea'
           ))
    )
  );

DROP POLICY IF EXISTS "Update own actions" ON actions;
CREATE POLICY "Update own actions" ON actions 
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM reviews 
      WHERE reviews.id = actions.review_id 
      AND reviews.sa_user_id = auth.uid()
    )
  );

-- audit_log policies
DROP POLICY IF EXISTS "Read audit_log via review" ON audit_log;
CREATE POLICY "Read audit_log via review" ON audit_log 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reviews 
      WHERE reviews.id = audit_log.review_id 
      AND (reviews.sa_user_id = auth.uid() OR 
           EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'ea'
           ))
    )
  );

-- ============================================================================
-- TRIGGERS FOR AUDIT LOGGING
-- ============================================================================

CREATE OR REPLACE FUNCTION log_review_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO audit_log (review_id, user_id, user_role, action, old_status, new_status)
    VALUES (
      NEW.id,
      auth.uid(),
      COALESCE(
        (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()),
        'system'
      ),
      'status_changed',
      OLD.status,
      NEW.status
    );
  END IF;
  
  IF OLD.decision IS DISTINCT FROM NEW.decision THEN
    INSERT INTO audit_log (review_id, user_id, user_role, action, old_decision, new_decision)
    VALUES (
      NEW.id,
      auth.uid(),
      COALESCE(
        (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()),
        'system'
      ),
      'decision_changed',
      OLD.decision,
      NEW.decision
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_review_status_change ON reviews;
CREATE TRIGGER trigger_review_status_change
  AFTER UPDATE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION log_review_status_change();

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_md_files_updated_at ON md_files;
CREATE TRIGGER trigger_md_files_updated_at
  BEFORE UPDATE ON md_files
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_adrs_updated_at ON adrs;
CREATE TRIGGER trigger_adrs_updated_at
  BEFORE UPDATE ON adrs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
