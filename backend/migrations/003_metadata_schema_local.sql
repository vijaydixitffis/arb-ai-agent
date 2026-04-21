-- Migration 003: Metadata Schema (Local PostgreSQL Version)
-- This migration creates tables for dynamic UI metadata management

-- ============================================================================
-- DROP TABLES SECTION (Clean Schema)
-- ============================================================================
DROP TABLE IF EXISTS domain_steps CASCADE;
DROP TABLE IF EXISTS principle_domains CASCADE;
DROP TABLE IF EXISTS question_options CASCADE;
DROP TABLE IF EXISTS checklist_questions CASCADE;
DROP TABLE IF EXISTS checklist_subsections CASCADE;
DROP TABLE IF EXISTS artefact_templates CASCADE;
DROP TABLE IF EXISTS artefact_types CASCADE;
DROP TABLE IF EXISTS form_fields CASCADE;
DROP TABLE IF EXISTS ptx_gates CASCADE;
DROP TABLE IF EXISTS architecture_dispositions CASCADE;
DROP TABLE IF EXISTS ea_principles CASCADE;
DROP TABLE IF EXISTS domains CASCADE;
DROP TABLE IF EXISTS submission_steps CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE CREATION
-- ============================================================================

-- 1. Submission Steps (Tabs)
CREATE TABLE submission_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  step_order INT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Domains
CREATE TABLE domains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Domain-Step Mapping (Many-to-Many)
CREATE TABLE domain_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  step_id UUID REFERENCES submission_steps(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(domain_id, step_id)
);

-- 4. Artefact Types
CREATE TABLE artefact_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  value TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Artefact Templates (Domain-wise artefacts list)
CREATE TABLE artefact_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  artefact_type_id UUID REFERENCES artefact_types(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_required BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(domain_id, name)
);

-- 6. Checklist Subsections
CREATE TABLE checklist_subsections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  color_theme TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(domain_id, name)
);

-- 7. Checklist Questions
CREATE TABLE checklist_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subsection_id UUID REFERENCES checklist_subsections(id) ON DELETE CASCADE,
  question_code TEXT NOT NULL UNIQUE,
  question_text TEXT NOT NULL,
  question_type TEXT DEFAULT 'compliance',
  help_text TEXT,
  is_required BOOLEAN DEFAULT false,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Question Options (for dropdowns, radio buttons)
CREATE TABLE question_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID REFERENCES checklist_questions(id) ON DELETE CASCADE,
  option_value TEXT NOT NULL,
  option_label TEXT NOT NULL,
  description TEXT,
  color_code TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. EA Principles (from knowledge base)
CREATE TABLE ea_principles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  principle_code TEXT NOT NULL UNIQUE,
  principle_name TEXT NOT NULL,
  category TEXT NOT NULL,
  statement TEXT NOT NULL,
  rationale TEXT,
  implications TEXT,
  items_to_verify TEXT[],
  arb_weight TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Principle-Domain Mapping
CREATE TABLE principle_domains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  principle_id UUID REFERENCES ea_principles(id) ON DELETE CASCADE,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  relevance_score INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(principle_id, domain_id)
);

-- 11. PTX Gates (Dropdown options)
CREATE TABLE ptx_gates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  value TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  description TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Architecture Dispositions (Dropdown options)
CREATE TABLE architecture_dispositions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  value TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  description TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. Form Fields (for dynamic form generation)
CREATE TABLE form_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  step_id UUID REFERENCES submission_steps(id) ON DELETE CASCADE,
  field_name TEXT NOT NULL,
  field_label TEXT NOT NULL,
  field_type TEXT NOT NULL,
  placeholder TEXT,
  is_required BOOLEAN DEFAULT false,
  validation_rules JSONB,
  options JSONB,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(step_id, field_name)
);

-- Indexes for performance
CREATE INDEX idx_submission_steps_order ON submission_steps(step_order);
CREATE INDEX idx_domains_slug ON domains(slug);
CREATE INDEX idx_artefact_templates_domain ON artefact_templates(domain_id);
CREATE INDEX idx_artefact_templates_type ON artefact_templates(artefact_type_id);
CREATE INDEX idx_checklist_subsections_domain ON checklist_subsections(domain_id);
CREATE INDEX idx_checklist_questions_subsection ON checklist_questions(subsection_id);
CREATE INDEX idx_form_fields_step ON form_fields(step_id);
CREATE INDEX idx_ea_principles_category ON ea_principles(category);
CREATE INDEX idx_domain_steps_step ON domain_steps(step_id);
CREATE INDEX idx_domain_steps_domain ON domain_steps(domain_id);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables with updated_at column
DROP TRIGGER IF EXISTS trigger_submission_steps_updated_at ON submission_steps;
CREATE TRIGGER trigger_submission_steps_updated_at
  BEFORE UPDATE ON submission_steps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_domains_updated_at ON domains;
CREATE TRIGGER trigger_domains_updated_at
  BEFORE UPDATE ON domains
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_artefact_types_updated_at ON artefact_types;
CREATE TRIGGER trigger_artefact_types_updated_at
  BEFORE UPDATE ON artefact_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_artefact_templates_updated_at ON artefact_templates;
CREATE TRIGGER trigger_artefact_templates_updated_at
  BEFORE UPDATE ON artefact_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_checklist_subsections_updated_at ON checklist_subsections;
CREATE TRIGGER trigger_checklist_subsections_updated_at
  BEFORE UPDATE ON checklist_subsections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_checklist_questions_updated_at ON checklist_questions;
CREATE TRIGGER trigger_checklist_questions_updated_at
  BEFORE UPDATE ON checklist_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_ea_principles_updated_at ON ea_principles;
CREATE TRIGGER trigger_ea_principles_updated_at
  BEFORE UPDATE ON ea_principles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_form_fields_updated_at ON form_fields;
CREATE TRIGGER trigger_form_fields_updated_at
  BEFORE UPDATE ON form_fields
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
