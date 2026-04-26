-- Migration 013: Remove Single Artefact Columns from Reviews Table
-- This migration removes the single artefact columns from the reviews table
-- to support multiple artefacts per review

-- ============================================================================
-- ENABLE VECTOR EXTENSION
-- ============================================================================

-- Enable vector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- REMOVE SINGLE ARTEFACT COLUMNS FROM REVIEWS TABLE
-- ============================================================================

-- Drop single artefact columns from reviews table
ALTER TABLE reviews 
DROP COLUMN IF EXISTS artifact_path,
DROP COLUMN IF EXISTS artifact_filename,
DROP COLUMN IF EXISTS artifact_file_type,
DROP COLUMN IF EXISTS artifact_file_size_bytes;

-- ============================================================================
-- CREATE ARTEFACTS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS artefacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  domain_slug TEXT NOT NULL,
  artefact_name TEXT NOT NULL,
  artefact_type TEXT NOT NULL,
  filename TEXT NOT NULL,
  file_type TEXT,
  file_size_bytes INT,
  storage_url TEXT,
  storage_path TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_artefacts_review ON artefacts(review_id);
CREATE INDEX IF NOT EXISTS idx_artefacts_domain ON artefacts(domain_slug);
CREATE INDEX IF NOT EXISTS idx_artefacts_active ON artefacts(is_active) WHERE is_active = true;

-- ============================================================================
-- CREATE ARTEFACT_CHUNKS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS artefact_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artefact_id UUID NOT NULL REFERENCES artefacts(id) ON DELETE CASCADE,
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  domain_slug TEXT NOT NULL,
  filename TEXT NOT NULL,
  chunk_index INT NOT NULL,
  chunk_text TEXT NOT NULL,
  embedding VECTOR(1536),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_artefact_chunks_artefact ON artefact_chunks(artefact_id);
CREATE INDEX IF NOT EXISTS idx_artefact_chunks_review ON artefact_chunks(review_id);
CREATE INDEX IF NOT EXISTS idx_artefact_chunks_domain ON artefact_chunks(domain_slug);
CREATE INDEX IF NOT EXISTS idx_artefact_chunks_embedding ON artefact_chunks USING ivfflat (embedding vector_cosine_ops);

-- ============================================================================
-- CREATE KNOWLEDGE_BASE TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS knowledge_base (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  principle_id TEXT,
  embedding VECTOR(1536),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_knowledge_base_category ON knowledge_base(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_active ON knowledge_base(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_knowledge_base_embedding ON knowledge_base USING ivfflat (embedding vector_cosine_ops);

-- ============================================================================
-- ENABLE RLS POLICIES FOR NEW TABLES
-- ============================================================================

-- Enable RLS on artefacts table
ALTER TABLE artefacts ENABLE ROW LEVEL SECURITY;

-- Enable RLS on artefact_chunks table  
ALTER TABLE artefact_chunks ENABLE ROW LEVEL SECURITY;

-- Enable RLS on knowledge_base table
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES FOR ARTEFACTS TABLE
-- ============================================================================

-- Users can read artefacts for their own reviews
CREATE POLICY "Users can view artefacts for their reviews" ON artefacts
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM reviews 
    WHERE reviews.id = artefacts.review_id 
    AND reviews.sa_user_id = auth.uid()
  )
);

-- Users can insert artefacts for their own reviews
CREATE POLICY "Users can insert artefacts for their reviews" ON artefacts
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM reviews 
    WHERE reviews.id = artefacts.review_id 
    AND reviews.sa_user_id = auth.uid()
  )
);

-- ============================================================================
-- RLS POLICIES FOR ARTEFACT_CHUNKS TABLE
-- ============================================================================

-- Users can read artefact chunks for their own reviews
CREATE POLICY "Users can view artefact chunks for their reviews" ON artefact_chunks
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM reviews 
    WHERE reviews.id = artefact_chunks.review_id 
    AND reviews.sa_user_id = auth.uid()
  )
);

-- Users can insert artefact chunks for their own reviews
CREATE POLICY "Users can insert artefact chunks for their reviews" ON artefact_chunks
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM reviews 
    WHERE reviews.id = artefact_chunks.review_id 
    AND reviews.sa_user_id = auth.uid()
  )
);

-- ============================================================================
-- RLS POLICIES FOR KNOWLEDGE_BASE TABLE
-- ============================================================================

-- All authenticated users can read knowledge base
CREATE POLICY "Authenticated users can view knowledge base" ON knowledge_base
FOR SELECT USING (auth.role() = 'authenticated');

-- Service role can manage knowledge base
CREATE POLICY "Service role can manage knowledge base" ON knowledge_base
FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

-- Create updated_at trigger function if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_artefacts_updated_at BEFORE UPDATE ON artefacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_base_updated_at BEFORE UPDATE ON knowledge_base
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
