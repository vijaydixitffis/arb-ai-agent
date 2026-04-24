-- Create artefacts table for multiple artefact storage
CREATE TABLE artefacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
    domain_slug VARCHAR(50) NOT NULL,
    artefact_name VARCHAR(255) NOT NULL,
    artefact_type VARCHAR(100) NOT NULL,
    filename TEXT NOT NULL,
    file_type TEXT,
    file_size_bytes INTEGER,
    content BYTEA NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN DEFAULT true
);

-- Create artefact_chunks table for chunked content (without vector for now)
CREATE TABLE artefact_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    artefact_id UUID NOT NULL REFERENCES artefacts (id) ON DELETE CASCADE,
    review_id UUID NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
    filename TEXT,
    chunk_index INTEGER NOT NULL,
    chunk_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create knowledge_base table for EA principles and standards (without vector for now)
CREATE TABLE knowledge_base (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100),
    principle_id VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN DEFAULT true
);

-- Create indexes for performance
CREATE INDEX idx_artefacts_review_id ON artefacts(review_id);
CREATE INDEX idx_artefacts_domain_slug ON artefacts(domain_slug);
CREATE INDEX idx_artefact_chunks_review_id ON artefact_chunks(review_id);
CREATE INDEX idx_artefact_chunks_artefact_id ON artefact_chunks(artefact_id);
CREATE INDEX idx_knowledge_base_category ON knowledge_base(category);

-- Add comments for documentation
COMMENT ON TABLE artefacts IS 'Stores uploaded artefacts for ARB reviews';
COMMENT ON TABLE artefact_chunks IS 'Stores chunked text content for similarity search';
COMMENT ON TABLE knowledge_base IS 'Stores EA principles, standards, and reference documents';

-- Note: Vector extension and columns will be added in separate migration after pgvector installation
