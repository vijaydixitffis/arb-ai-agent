-- Initial Migration: ARB Metadata Schema
-- This migration creates all tables for dynamic UI metadata management

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

-- Row Level Security (RLS) Policies
ALTER TABLE submission_steps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for submission_steps" ON submission_steps FOR SELECT USING (true);

ALTER TABLE domains ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for domains" ON domains FOR SELECT USING (true);

ALTER TABLE domain_steps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for domain_steps" ON domain_steps FOR SELECT USING (true);

ALTER TABLE artefact_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for artefact_types" ON artefact_types FOR SELECT USING (true);

ALTER TABLE artefact_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for artefact_templates" ON artefact_templates FOR SELECT USING (true);

ALTER TABLE checklist_subsections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for checklist_subsections" ON checklist_subsections FOR SELECT USING (true);

ALTER TABLE checklist_questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for checklist_questions" ON checklist_questions FOR SELECT USING (true);

ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for question_options" ON question_options FOR SELECT USING (true);

ALTER TABLE ea_principles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for ea_principles" ON ea_principles FOR SELECT USING (true);

ALTER TABLE principle_domains ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for principle_domains" ON principle_domains FOR SELECT USING (true);

ALTER TABLE ptx_gates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for ptx_gates" ON ptx_gates FOR SELECT USING (true);

ALTER TABLE architecture_dispositions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for architecture_dispositions" ON architecture_dispositions FOR SELECT USING (true);

ALTER TABLE form_fields ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access for form_fields" ON form_fields FOR SELECT USING (true);

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Insert Submission Steps
INSERT INTO submission_steps (step_order, title, description, icon) VALUES
  (1, 'Solution Context', 'Project overview and stakeholders', 'project'),
  (2, 'General', 'Generic metrics and cross-cutting concerns', 'globe'),
  (3, 'Business', 'Business capabilities and processes', 'briefcase'),
  (4, 'Application', 'Tech stack and patterns', 'cpu'),
  (5, 'Integration', 'APIs and integration catalogue', 'link'),
  (6, 'Data', 'Classification and lifecycle', 'database'),
  (7, 'Infra-Technology', 'Environments and platform', 'server'),
  (8, 'Engineering & DevSecOps', 'CI/CD and quality gates', 'shield'),
  (9, 'NFRs (Quality of Service)', 'Performance and reliability', 'zap');

-- Insert Domains
INSERT INTO domains (slug, name, description, color, icon) VALUES
  ('general', 'General', 'Generic metrics and cross-cutting concerns', '#3B82F6', 'globe'),
  ('business', 'Business', 'Business capabilities and processes', '#10B981', 'briefcase'),
  ('application', 'Application', 'Tech stack and patterns', '#8B5CF6', 'cpu'),
  ('integration', 'Integration', 'APIs and integration catalogue', '#F59E0B', 'link'),
  ('data', 'Data', 'Classification and lifecycle', '#EF4444', 'database'),
  ('infrastructure', 'Infrastructure', 'Environments and platform', '#6366F1', 'server'),
  ('devsecops', 'DevSecOps', 'CI/CD and quality gates', '#EC4899', 'shield'),
  ('nfr', 'NFR', 'Performance and reliability', '#14B8A6', 'zap');

-- Insert Artefact Types
INSERT INTO artefact_types (value, label, description, icon) VALUES
  ('t-doc', 'Doc', 'Document / Report', '📄'),
  ('t-diag', 'Diagram', 'Architecture diagram', '🗺️'),
  ('t-xls', 'Sheet', 'Spreadsheet / Register', '📊'),
  ('t-deck', 'Deck', 'Presentation', '🗺️'),
  ('t-log', 'Log', 'Log / Tracker', '📋');

-- Map domains to steps (excluding step 1 which is Solution Context)
-- Map steps to domains (one-to-one mapping)
INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  (SELECT id FROM submission_steps WHERE step_order = 2),
  true
ON CONFLICT DO NOTHING;

INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  (SELECT id FROM submission_steps WHERE step_order = 3),
  true
ON CONFLICT DO NOTHING;

INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  (SELECT id FROM submission_steps WHERE step_order = 4),
  true
ON CONFLICT DO NOTHING;

INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'integration'),
  (SELECT id FROM submission_steps WHERE step_order = 5),
  true
ON CONFLICT DO NOTHING;

INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'data'),
  (SELECT id FROM submission_steps WHERE step_order = 6),
  true
ON CONFLICT DO NOTHING;

INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  (SELECT id FROM submission_steps WHERE step_order = 7),
  true
ON CONFLICT DO NOTHING;

INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  (SELECT id FROM submission_steps WHERE step_order = 8),
  true
ON CONFLICT DO NOTHING;

-- Map NFR to step 9
INSERT INTO domain_steps (domain_id, step_id, is_active)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  (SELECT id FROM submission_steps WHERE step_order = 9),
  true
ON CONFLICT DO NOTHING;

-- General Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Architecture Principles Doc',
  'Enterprise architecture principles documentation',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  (SELECT id FROM artefact_types WHERE value = 't-log'),
  'RAID Log',
  'Risks, Assumptions, Issues, Dependencies log',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'TCO / Budget Sheet',
  'Total Cost of Ownership and budget spreadsheet',
  true,
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  (SELECT id FROM artefact_types WHERE value = 't-deck'),
  'Roadmap Deck',
  'Architecture and implementation roadmap presentation',
  false,
  3
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Standards & Policies Doc',
  'Enterprise standards and policies documentation',
  true,
  4
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'End User Feedback Report',
  'Analysis of end user feedback and support tickets',
  false,
  5
ON CONFLICT (domain_id, name) DO NOTHING;

-- Business Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Business Case / Problem Statement',
  'Business case document with problem statement',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Business Requirements Doc (BRD)',
  'Business Requirements Document',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  (SELECT id FROM artefact_types WHERE value = 't-diag'),
  'Domain Model Diagram',
  'Business domain model diagram',
  true,
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'Business NFRs Register',
  'Business Non-Functional Requirements register',
  true,
  3
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Operating Model Doc',
  'Target operating model documentation',
  false,
  4
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Business Continuity Plan',
  'Business continuity and disaster recovery plan',
  true,
  5
ON CONFLICT (domain_id, name) DO NOTHING;

-- Application Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  (SELECT id FROM artefact_types WHERE value = 't-diag'),
  'High Level Design (HLD)',
  'High Level Design document/diagram',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  (SELECT id FROM artefact_types WHERE value = 't-diag'),
  'App Architecture Diagram',
  'Application architecture diagram',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Architecture Decision Records (ADRs)',
  'Collection of Architecture Decision Records',
  true,
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'Tech Debt Register',
  'Technical debt tracking register',
  true,
  3
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Runbooks & Ops Docs',
  'Operational runbooks and documentation',
  true,
  4
ON CONFLICT (domain_id, name) DO NOTHING;

-- Integration Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'integration'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'Integration Catalogue (Sheet)',
  'Integration catalogue spreadsheet',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'integration'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'API / Interface Catalog',
  'API and interface catalog documentation',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

-- Data Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'data'),
  (SELECT id FROM artefact_types WHERE value = 't-diag'),
  'Data Architecture Diagram',
  'Data architecture diagram',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'data'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'Data Classification Register',
  'Data classification and ownership register',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'data'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Data Governance Doc',
  'Data governance documentation',
  true,
  2
ON CONFLICT (domain_id, name) DO NOTHING;

-- Infrastructure Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  (SELECT id FROM artefact_types WHERE value = 't-diag'),
  'Infra Architecture Diagram',
  'Infrastructure architecture diagram',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'Capacity Plan (Sheet)',
  'Capacity planning spreadsheet',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'Platform Lifecycle Register',
  'Platform lifecycle and EoS tracking register',
  true,
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Infra Security Controls Doc',
  'Infrastructure security controls documentation',
  true,
  3
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Automation & IaaC Runbook',
  'Automation and Infrastructure as Code runbook',
  false,
  4
ON CONFLICT (domain_id, name) DO NOTHING;

-- DevSecOps Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  (SELECT id FROM artefact_types WHERE value = 't-diag'),
  'CI-CD Pipeline Diagram',
  'CI/CD pipeline architecture diagram',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'DevOps Metrics Dashboard / Sheet',
  'DevOps metrics and KPIs spreadsheet',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Threat Model Document',
  'Threat modeling documentation',
  true,
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'SW Quality Metrics Report',
  'Software quality metrics report',
  true,
  3
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Secure Code Review Report',
  'Secure code review report',
  true,
  4
ON CONFLICT (domain_id, name) DO NOTHING;

-- NFR Domain Artefacts
INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'NFR Requirements Sheet',
  'Non-Functional Requirements spreadsheet',
  true,
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'HA & DR Plan',
  'High Availability and Disaster Recovery plan',
  true,
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  (SELECT id FROM artefact_types WHERE value = 't-xls'),
  'Security Controls Register',
  'Security controls register',
  true,
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO artefact_templates (domain_id, artefact_type_id, name, description, is_required, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  (SELECT id FROM artefact_types WHERE value = 't-doc'),
  'Performance Baseline Report',
  'Performance baseline and testing report',
  true,
  3
ON CONFLICT (domain_id, name) DO NOTHING;

-- Insert PTX Gates
INSERT INTO ptx_gates (value, label, description, sort_order) VALUES
  ('Permit to Evaluate', 'Permit to Evaluate', 'Initial evaluation phase', 1),
  ('Permit to Purchase', 'Permit to Purchase', 'Procurement approval phase', 2),
  ('Permit to Design', 'Permit to Design', 'Design approval phase', 3),
  ('Permit to Build', 'Permit to Build', 'Build authorization phase', 4),
  ('Permit to Operate', 'Permit to Operate', 'Operations authorization phase', 5),
  ('Permit to Retire', 'Permit to Retire', 'Decommissioning approval phase', 6);

-- Insert Architecture Dispositions
INSERT INTO architecture_dispositions (value, label, description, sort_order) VALUES
  ('Architecture Pattern Review', 'Architecture Pattern Review', 'Review of architectural patterns', 1),
  ('High Bar Review', 'High Bar Review', 'High-level architecture review', 2),
  ('Architecture Review Board', 'Architecture Review Board', 'Full ARB review', 3),
  ('Change Acceptance Board', 'Change Acceptance Board', 'CAB review for changes', 4),
  ('FastPath', 'FastPath', 'Expedited review process', 5);

-- Insert Form Fields for Step 1 (Solution Context)
INSERT INTO form_fields (step_id, field_name, field_label, field_type, placeholder, is_required, sort_order)
SELECT 
  (SELECT id FROM submission_steps WHERE step_order = 1),
  'project_name',
  'Project Name',
  'text',
  'Enter project name',
  true,
  0
ON CONFLICT (step_id, field_name) DO NOTHING;

INSERT INTO form_fields (step_id, field_name, field_label, field_type, placeholder, is_required, sort_order)
SELECT 
  (SELECT id FROM submission_steps WHERE step_order = 1),
  'problem_statement',
  'Problem Statement',
  'textarea',
  'Describe the problem this solution addresses',
  true,
  1
ON CONFLICT (step_id, field_name) DO NOTHING;

INSERT INTO form_fields (step_id, field_name, field_label, field_type, placeholder, is_required, sort_order)
SELECT 
  (SELECT id FROM submission_steps WHERE step_order = 1),
  'stakeholders',
  'Stakeholders',
  'textarea',
  'List key stakeholders (one per line)',
  true,
  2
ON CONFLICT (step_id, field_name) DO NOTHING;

INSERT INTO form_fields (step_id, field_name, field_label, field_type, placeholder, is_required, sort_order)
SELECT 
  (SELECT id FROM submission_steps WHERE step_order = 1),
  'business_drivers',
  'Business Drivers',
  'textarea',
  'List business drivers (one per line)',
  true,
  3
ON CONFLICT (step_id, field_name) DO NOTHING;

INSERT INTO form_fields (step_id, field_name, field_label, field_type, placeholder, is_required, sort_order)
SELECT 
  (SELECT id FROM submission_steps WHERE step_order = 1),
  'growth_plans',
  'Growth Plans',
  'textarea',
  'Describe growth plans and scalability requirements',
  false,
  4
ON CONFLICT (step_id, field_name) DO NOTHING;

-- ============================================================================
-- CHECKLIST SUBSECTIONS AND QUESTIONS
-- ============================================================================

-- General Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  'End User Voices',
  'End user feedback and stakeholder analysis',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  'Strategy Impact',
  'Strategy alignment and impact assessment',
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  'Documentation',
  'Documentation standards and compliance',
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  'Process Adherence',
  'Process compliance and adherence',
  3
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'general'),
  'Economics',
  'Cost analysis and budget considerations',
  4
ON CONFLICT (domain_id, name) DO NOTHING;

-- Business Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  'What',
  'Business capabilities and use cases',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  'Business NFRs',
  'Business non-functional requirements',
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  'Why',
  'Business justification and alignment',
  2
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  'Who',
  'Users and stakeholders analysis',
  3
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'business'),
  'Others',
  'Other business considerations',
  4
ON CONFLICT (domain_id, name) DO NOTHING;

-- Application Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  'Metadata & Lifecycle',
  'Application metadata and lifecycle management',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  'Software Architecture',
  'Software architecture and design patterns',
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'application'),
  'Others (Application)',
  'Additional application considerations',
  2
ON CONFLICT (domain_id, name) DO NOTHING;

-- Integration Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'integration'),
  'Interface Catalog',
  'Interface documentation and catalog',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'integration'),
  'Interface Checks',
  'Interface validation and compliance',
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'integration'),
  'NFRs',
  'Integration non-functional requirements',
  2
ON CONFLICT (domain_id, name) DO NOTHING;

-- Data Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'data'),
  'Metadata & Lifecycle',
  'Data metadata and lifecycle management',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

-- Infrastructure Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  'Metadata & Lifecycle',
  'Infrastructure metadata and lifecycle',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  'Security',
  'Infrastructure security controls',
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'infrastructure'),
  'Others',
  'Additional infrastructure considerations',
  2
ON CONFLICT (domain_id, name) DO NOTHING;

-- DevSecOps Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  'DevOps',
  'DevOps practices and automation',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  'SecOps',
  'Security operations and practices',
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'devsecops'),
  'Engineering Excellence & SW Quality',
  'Software quality and engineering practices',
  2
ON CONFLICT (domain_id, name) DO NOTHING;

-- NFR Domain Subsections
INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  'Scalability & Performance',
  'Scalability and performance requirements',
  0
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  'HA & Resilience',
  'High availability and resilience',
  1
ON CONFLICT (domain_id, name) DO NOTHING;

INSERT INTO checklist_subsections (domain_id, name, description, sort_order)
SELECT 
  (SELECT id FROM domains WHERE slug = 'nfr'),
  'Security',
  'Security requirements',
  2
ON CONFLICT (domain_id, name) DO NOTHING;

-- ============================================================================
-- CHECKLIST QUESTIONS
-- ============================================================================

-- General Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'End User Voices' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-euv-1',
  'Top 10 concerns/issues impacting end users identified?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'End User Voices' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-euv-2',
  'End user wish list aspirations documented?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'End User Voices' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-euv-3',
  'Support tickets and incidents analyzed?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Strategy Impact' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-strat-1',
  'Change in business priority assessed?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Strategy Impact' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-strat-2',
  'Change in business model considered?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Strategy Impact' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-strat-3',
  'Change in target operating model evaluated?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Strategy Impact' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-strat-4',
  'Alignment to target architecture/roadmap verified?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Documentation' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-doc-1',
  'Adherence to architecture principles (Business, App, Data, Tech)?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Documentation' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-doc-2',
  'Adherence to patterns, standards, policies?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Documentation' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-doc-3',
  'Level of documentation adequate?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Process Adherence' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-proc-1',
  'Adherence to PtX process?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Process Adherence' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-proc-2',
  'RAID logs and decision logs maintained?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Process Adherence' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-proc-3',
  'Roadmap alignment verified?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Process Adherence' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-proc-4',
  'Consolidation, Federation, Standardization considered?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Economics' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-eco-1',
  'Total cost of ownership calculated (Development, Maintenance, Operations)?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Economics' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-eco-2',
  'Budget alignment verified?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Economics' AND domain_id = (SELECT id FROM domains WHERE slug = 'general')),
  'gen-eco-3',
  'Opportunities for cost optimization identified?',
  2
ON CONFLICT (question_code) DO NOTHING;

-- Business Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'What' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-what-1',
  'Business use cases, capabilities impacted documented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'What' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-what-2',
  'Growth/change plans defined?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'What' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-what-3',
  'Domain model established?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'What' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-what-4',
  'Service/Contract/Functions documented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Business NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-nfr-1',
  'Security - User password specs/expiry/resets/locks defined?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Business NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-nfr-2',
  'Performance & Scalability - Business functions/transaction metrics defined?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Business NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-nfr-3',
  'Business continuity plan established?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Business NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-nfr-4',
  'Analytics/Monetization considered?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Why' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-why-1',
  'Why this capability, app or service justified?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Why' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-why-2',
  'Entry-exit criteria for business functions/metrics defined?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Why' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-why-3',
  'Business case relevance or updates documented?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Why' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-why-4',
  'Business level product lifecycle and roadmap alignment verified?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Who' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-who-1',
  'Actors, Users, Systems and entities involved/impacted identified?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Who' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-who-2',
  'Roles, User groups involved/impacted documented?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Who' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-who-3',
  'User geo/regions - Multi-time zones considered?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Who' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-who-4',
  'Multilingual support required?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Who' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-who-5',
  'Multi-currency support required?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-oth-1',
  'Operation Time - 24/7, Weekdays etc. defined?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-oth-2',
  'Business change management plan established?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-oth-3',
  'Target operating model defined?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-oth-4',
  'Continuity plan documented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'business')),
  'bus-oth-5',
  'Reporting and monetization strategy defined?',
  4
ON CONFLICT (question_code) DO NOTHING;

-- Application Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-meta-1',
  'COTS/Bespoke/Legacy classification documented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-meta-2',
  'Monolith/Microservices architecture defined?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-meta-3',
  'Technology stack documented?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-meta-4',
  'Technology debt identified?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-meta-5',
  'Planned SW upgrade, platforms upgrade documented?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-meta-6',
  'Dependent Library EOS tracked?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-meta-7',
  'End of life, End of Support, License expiry documented?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Software Architecture' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-soft-1',
  'Technology choices align to standards; upgrade path and SBOM?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Software Architecture' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-soft-2',
  'Versioning and backward compatibility; ADRs?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Software Architecture' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-soft-3',
  'Resilience patterns: timeouts, retries, circuit breakers, idempotency?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Software Architecture' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-soft-4',
  'Documentation currency: diagrams, ADRs, runbooks, ownership established?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-1',
  'Usability metrics defined?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-2',
  'Audits/Logging implemented?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-3',
  'Monitoring, Alerts configured?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-4',
  'TCO – 3yrs, 5yrs calculated?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-5',
  'Integrations – QoS defined?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-6',
  'Distributed Cache required?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-7',
  'Notifications/Events implemented?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others (Application)' AND domain_id = (SELECT id FROM domains WHERE slug = 'application')),
  'app-oth-8',
  'Scheduled Jobs/Batches documented?',
  7
ON CONFLICT (question_code) DO NOTHING;

-- Integration Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Catalog' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-cat-1',
  'Interface Catalog documented (SR, Provider, Consumer)?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Catalog' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-cat-2',
  'Pattern, Type, Method defined (API, File, MSG, Event)?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Catalog' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-cat-3',
  'Interaction style specified (Async/Batch/Sync/Real-time)?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Catalog' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-cat-4',
  'Frequency documented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Catalog' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-cat-5',
  'Data flows described?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Checks' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-check-1',
  'Interface Catalog, Events, SLAs, Versioning (API, Files, MSGs)?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Checks' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-check-2',
  'Consistent API design: resource modeling, errors, pagination, filtering; security scopes?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Checks' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-check-3',
  'Event schemas, registry, compatibility rules; ordering/replay requirements?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Interface Checks' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-check-4',
  'Reliability: idempotency, throttling & rate limiting?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-nfr-1',
  'Scalability requirements defined?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-nfr-2',
  'Security requirements specified?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-nfr-3',
  'Performance metrics defined?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-nfr-4',
  'Bandwidth requirements documented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-nfr-5',
  'HA and Redundancy considered?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'NFRs' AND domain_id = (SELECT id FROM domains WHERE slug = 'integration')),
  'int-nfr-6',
  'DR requirements specified?',
  5
ON CONFLICT (question_code) DO NOTHING;

-- Data Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'data')),
  'data-meta-1',
  'Data classification and ownerships documented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'data')),
  'data-meta-2',
  'Data usage/management RnR defined?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'data')),
  'data-meta-3',
  'Data lifecycle established?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'data')),
  'data-meta-4',
  'Data sources and data model documentation maintained?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'data')),
  'data-meta-5',
  'Technology stack documented?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'data')),
  'data-meta-6',
  'EoS, EoL, Version upgrades, Platform upgrades tracked?',
  5
ON CONFLICT (question_code) DO NOTHING;

-- Infrastructure Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-meta-1',
  'Adequacy of environments, platforms and runtimes assessed?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-meta-2',
  'Platform upgrades, EoS, EoL tracked?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-meta-3',
  'Demand, capacity requirements, YoY Growth documented?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Metadata & Lifecycle' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-meta-4',
  'Adequacy of bandwidths for compute, storage and network verified?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-1',
  'Authentication, AuthZ implemented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-2',
  'RBAC configured?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-3',
  'Key Vault used?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-4',
  'PKI, Encryption implemented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-5',
  'Certs managed?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-6',
  'VAPT, End point protection in place?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-7',
  'Standards and Legal compliance verified?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-sec-8',
  'Integration security implemented?',
  7
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-1',
  'Automation, IaaC implemented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-2',
  'Audits/Logging configured?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-3',
  'Monitoring, Alerts set up?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-4',
  'TCO – 3yrs, 5yrs calculated?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-5',
  'Integrations – QoS defined?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-6',
  'Distributed Cache required?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-7',
  'Notifications/Events implemented?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Others' AND domain_id = (SELECT id FROM domains WHERE slug = 'infrastructure')),
  'infra-oth-8',
  'Scheduled Jobs/Batches documented?',
  7
ON CONFLICT (question_code) DO NOTHING;

-- DevSecOps Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-1',
  '12 Factor compliance verified?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-2',
  'Version control and branching strategy defined?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-3',
  'CI-CD pipeline, toolset established?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-4',
  'Identity access mgmt. configured?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-5',
  'Secrets & Config mgmt. implemented?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-6',
  'Build and packaging automated?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-7',
  'Deployment strategy & release mgmt. defined?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'DevOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'devops-8',
  'Templatization, IaaC implemented?',
  7
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-1',
  'Threat models and mitigations documented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-2',
  'Secure code reviews conducted?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-3',
  'Static code analysis – SAST integrated?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-4',
  'DAST implemented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-5',
  'VAPT completed?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-6',
  'Environments hardening applied?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-7',
  'SW Hardening implemented?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'SecOps' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'secops-8',
  'Metrics reporting in place?',
  7
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-1',
  'Static code analysis implemented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-2',
  'LLD reviews conducted?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-3',
  'Code reviews mandatory?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-4',
  'Test plans reviews done?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-5',
  'Defect tracking metrics defined?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-6',
  'Automation testing implemented?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-7',
  'API Testing conducted?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-8',
  'Performance testing done?',
  7
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Engineering Excellence & SW Quality' AND domain_id = (SELECT id FROM domains WHERE slug = 'devsecops')),
  'engex-9',
  'SW Quality metrics reporting in place?',
  8
ON CONFLICT (question_code) DO NOTHING;

-- NFR Domain Questions
INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Scalability & Performance' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-scalar-1',
  'Number of users, YoY growth documented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Scalability & Performance' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-scalar-2',
  'Number of concurrent users defined?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Scalability & Performance' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-scalar-3',
  'TPS / API calls per unit specified?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Scalability & Performance' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-scalar-4',
  'Response time (< 3 Sec)?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Scalability & Performance' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-scalar-5',
  'Long running use cases identified?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Scalability & Performance' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-scalar-6',
  'Batch / Scheduled jobs – peak-off peak considered?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-1',
  'Any Single point of Failures?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-2',
  'HA – Four 9s, Five 9s?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-3',
  'Failover mechanism defined?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-4',
  'DR, RPO, RTO documented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-5',
  'Error handling implemented?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-6',
  'Self healing?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-7',
  'Cache – Sync configured?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'HA & Resilience' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-ha-8',
  'Reliability, Extensibility, Maintainability considered?',
  7
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-1',
  'Authentication, Authorization implemented?',
  0
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-2',
  'RBAC, IAM configured?',
  1
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-3',
  'Key Vault used?',
  2
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-4',
  'PKI, Encryption implemented?',
  3
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-5',
  'Certs managed?',
  4
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-6',
  'VAPT, End point protection in place?',
  5
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-7',
  'Standards and Legal compliance verified?',
  6
ON CONFLICT (question_code) DO NOTHING;

INSERT INTO checklist_questions (subsection_id, question_code, question_text, sort_order)
SELECT 
  (SELECT id FROM checklist_subsections WHERE name = 'Security' AND domain_id = (SELECT id FROM domains WHERE slug = 'nfr')),
  'nfr-sec-8',
  'Integration security implemented?',
  7
ON CONFLICT (question_code) DO NOTHING;

-- ============================================================================
-- QUESTION OPTIONS (Default options for checklist questions)
-- ============================================================================

INSERT INTO question_options (option_value, option_label, description, sort_order, color_code)
VALUES 
  ('compliant', 'Yes', 'Fully compliant with the requirement', 0, '#22c55e'),
  ('non_compliant', 'No', 'Not compliant with the requirement', 1, '#ef4444'),
  ('partial', 'Partial', 'Partially compliant with the requirement', 2, '#f59e0b'),
  ('na', 'NA', 'Not applicable to this context', 3, '#6b7280')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- EA PRINCIPLES (Enterprise Architecture Principles)
-- ============================================================================

-- General Principles (G-01 to G-10)
INSERT INTO ea_principles (principle_code, principle_name, category, statement, rationale, implications, items_to_verify, arb_weight, is_active)
VALUES 
  ('G-01', 'Focus On Customer', 'General', 
   'All architecture decisions must ultimately serve the end customer. Systems, platforms, and solutions should be designed with measurable customer outcomes as the primary success criterion.',
   'Technology exists to enable business value. Without a customer-centric lens, architecture risks becoming internally optimised but externally irrelevant. Aligning all design choices to customer needs ensures investment translates to tangible outcomes.',
   'Solution architects must articulate how the proposed change improves customer experience, reduces friction, or enables new customer capabilities. Trade-offs between internal efficiency and customer-facing quality should favour the customer unless a compelling case is made. KPIs and success metrics must include at least one customer-facing measurement (e.g. response time, availability, usability score). UX and accessibility requirements must be addressed during design, not as afterthoughts.',
   ARRAY['Is there a documented customer problem statement or business use case driving this initiative?', 'Are success metrics defined, including at least one customer-facing KPI?', 'Has customer or end-user impact been assessed for any breaking changes or service degradation?', 'Is the solution''s end-user experience (UX) considered in the architecture?', 'Have support ticket trends or incident insights been reviewed to validate the problem being solved?'],
   'Medium', true),
  ('G-02', 'Bias For Action', 'General',
   'Architecture should enable rapid, reversible decisions and iterative delivery. Prefer done-and-improvable over perfect-but-delayed, while maintaining safeguards for irreversible choices.',
   'Over-engineering and analysis paralysis slow delivery and reduce business agility. Architectures that support incremental delivery allow faster value realisation and course correction based on real feedback.',
   'Solutions should be decomposed into deliverable increments with clear transition states toward the target architecture. "Big bang" architecture changes must be justified; phased approaches are preferred. Reversible decisions (e.g. feature flags, blue-green deployments) should be preferred over irreversible ones. Teams must demonstrate a working architecture through prototypes or proofs-of-concept before full investment.',
   ARRAY['Is a phased delivery plan with intermediate milestones documented?', 'Are irreversible architectural decisions explicitly called out with documented rationale?', 'Are there mechanisms for rollback or course correction (feature flags, versioned APIs, blue-green deployments)?', 'Has the team validated key architectural assumptions through spikes or proofs-of-concept?', 'Is the architecture roadmap aligned with the business delivery timeline?'],
   'Medium', true),
  ('G-03', 'Think Globally, Act Locally', 'General',
   'Solutions must be designed in the context of the broader enterprise architecture landscape, while being implemented in a way that is practical for the local domain or platform.',
   'Local optimisations without global awareness lead to duplication, fragmentation, and integration debt. Conversely, global mandates without local pragmatism stall delivery. Balance is essential.',
   'All solutions must be reviewed against the enterprise platform map and integration catalogue to identify overlaps, redundancies, or reuse opportunities. Local deviations from enterprise standards must be explicitly justified and time-bound. Shared services and platforms must be preferred over bespoke local implementations where equivalent capability exists. Cross-platform impact must always be assessed.',
   ARRAY['Has the solution been reviewed against the enterprise capability map for duplication or reuse?', 'Are any deviations from enterprise standards documented with rationale and a remediation timeline?', 'Has cross-platform and downstream consumer impact been assessed?', 'Does the solution contribute to or consume from shared platforms appropriately?', 'Is the solution aligned with the enterprise north star / target architecture?'],
   'High', true),
  ('G-04', 'Design For Reliability', 'General',
   'Every system must be designed with reliability as a first-class concern. Reliability includes availability, recoverability, fault tolerance, and predictable performance under normal and adverse conditions.',
   'Unreliable systems erode customer trust, generate operational overhead, and create financial and reputational risk. Reliability must be engineered in, not bolted on.',
   'All solutions must define and evidence HA targets (e.g. 99.9%, 99.99%), DR objectives (RPO, RTO), and failure mode analysis. Single points of failure must be identified and eliminated or mitigated. Circuit breakers, retries with backoff, timeouts, and graceful degradation patterns must be applied. Chaos engineering or fault injection testing must be considered for critical platforms.',
   ARRAY['Are HA targets (Four Nines / Five Nines) defined and evidenced?', 'Are RPO and RTO objectives documented and tested?', 'Has a single point of failure (SPOF) analysis been conducted?', 'Are resilience patterns (circuit breakers, retries, timeouts, bulkheads) implemented?', 'Is there a DR test plan and evidence of recent DR test execution?', 'Are SLOs and error budgets defined and monitored?'],
   'Critical', true),
  ('G-05', 'Treat Data As An Asset', 'General',
   'Data is a strategic enterprise asset that must be governed, protected, and made accessible in a controlled manner. Every solution must demonstrate responsible stewardship of the data it creates, consumes, or transforms.',
   'Ungoverned data leads to inconsistency, regulatory risk, and inability to derive business insight. Treating data as an asset requires deliberate lifecycle management, quality standards, and clear ownership.',
   'All data entities must have documented ownership, classification, and lifecycle policies. Data sharing must be managed through approved interfaces (APIs, events, data products) — never direct database access across domain boundaries. Data quality standards must be defined and monitored. Data lineage must be traceable from source to consumption.',
   ARRAY['Are data entities classified (Public, Internal, Confidential, Restricted)?', 'Are data owners and stewards identified?', 'Is data shared only via approved interfaces (API, event, data product)?', 'Is data lineage documented and traceable?', 'Are data retention and disposal policies defined and applied?', 'Is master data management (MDM) strategy addressed where applicable?'],
   'High', true),
  ('G-06', 'Secure From Start', 'General',
   'Security must be embedded into the architecture from the earliest design stage, not added after delivery. Every solution must adopt a "shift-left" security posture across all architecture domains.',
   'Retrofitting security is exponentially more expensive and risky than designing it in. Security vulnerabilities discovered post-deployment cause regulatory penalties, data breaches, and loss of customer trust.',
   'Threat modelling must be performed during design. All solutions must comply with enterprise security standards (AuthN/AuthZ, encryption, key management, VAPT). Security gates must be embedded in the CI/CD pipeline (SAST, DAST, SCA). Security is a blocking criterion for ARB approval — a Red security score cannot be waived.',
   ARRAY['Has a threat model been documented and reviewed?', 'Are authentication and authorisation mechanisms compliant with enterprise standards (OAuth 2.0, RBAC, OIDC)?', 'Is data encrypted in transit (TLS 1.2+) and at rest?', 'Are secrets managed via approved vaults (no hardcoded credentials)?', 'Are SAST/DAST/SCA gates integrated into the CI/CD pipeline with passing results?', 'Is VAPT evidence available and current (within 12 months)?', 'Are regulatory and legal compliance requirements (GDPR, SOX, etc.) addressed?'],
   'Critical', true),
  ('G-07', 'Reuse, Buy Needed, Build For Competition', 'General',
   'Before building custom solutions, teams must evaluate reuse of existing enterprise capabilities, then procurement of commercial products, and only build bespoke when neither option meets the need or when building delivers strategic differentiation.',
   'Custom build is expensive to develop and maintain. Reuse and buy strategies reduce time-to-market, lower total cost of ownership, and leverage enterprise investment. Bespoke build should be reserved for capabilities that differentiate BNY in the market.',
   'A documented build-vs-buy-vs-reuse analysis must accompany all significant new capability proposals. Platform and shared service catalogues must be consulted before any new capability is funded. Third-party products must be evaluated for vendor health, EoS/EoL roadmap, licensing, and integration fit. Custom builds must have a clear strategic justification linking to competitive advantage.',
   ARRAY['Is a build-vs-buy-vs-reuse analysis documented?', 'Has the enterprise capability catalogue been reviewed for existing solutions?', 'If buying, has vendor assessment (EoS, licensing, support, integration) been conducted?', 'If building, is the strategic differentiation rationale documented?', 'Are all third-party dependencies listed in the SBOM with version, license, and EoS dates?'],
   'High', true),
  ('G-08', 'Drive For Ease of Use', 'General',
   'Systems must be designed for ease of use for all consumers — end users, developers, and operations teams. Complexity must be hidden behind simple, well-designed interfaces.',
   'Difficult-to-use systems are adopted reluctantly, used incorrectly, and generate support overhead. Ease of use drives adoption, reduces errors, and lowers operational cost.',
   'APIs must be designed following consumer-centric design principles (resource-oriented, consistent naming, versioned, well-documented). Developer experience (DX) must be considered for platform APIs — onboarding docs and conformance tests are mandatory. Operational runbooks and self-service tooling must be provided. Usability metrics must be defined and monitored.',
   ARRAY['Are APIs designed following enterprise API design standards (resource-oriented, versioned, consistent)?', 'Is API documentation complete, accurate, and published to the enterprise catalogue?', 'Are onboarding guides and conformance tests available for consuming teams?', 'Are operational runbooks and self-service tooling provided?', 'Are usability and developer experience metrics defined?'],
   'Medium', true),
  ('G-09', 'Engineer Solution With Strong Design Foundations', 'General',
   'All solutions must be built on proven architectural patterns, sound engineering principles, and documented design decisions. Ad-hoc or undocumented architectural choices are not acceptable.',
   'Poor foundations lead to technical debt, fragility, and high cost of change. Strong design foundations reduce long-term maintenance burden and enable future evolution.',
   'Architecture Decision Records (ADRs) must be created for all significant decisions. Approved patterns from the enterprise pattern library must be applied wherever applicable. Documentation currency (diagrams, ADRs, runbooks) must be maintained and kept up to date. Technical debt must be explicitly identified, tracked, and have a remediation plan.',
   ARRAY['Are ADRs created for all significant architectural decisions?', 'Are enterprise-approved patterns applied and referenced?', 'Are architecture diagrams (context, component, sequence, data flow) current and accurate?', 'Is technical debt explicitly inventoried with a remediation plan and target dates?', 'Is documentation ownership established and a refresh cadence defined?'],
   'High', true),
  ('G-10', 'Anticipate And Plan For Change', 'General',
   'Architecture must accommodate future change. Systems should be designed with extensibility, configurability, and evolvability as core qualities so that future business and technology changes do not require wholesale rearchitecting.',
   'Business requirements, technology choices, and regulatory landscapes change continuously. Brittle architectures that cannot absorb change become liabilities.',
   'Systems must support versioning and backward compatibility for all interfaces. Configuration must be externalised and environment-agnostic. Dependency on specific infrastructure or vendor technology must be minimised through abstraction layers. A technology roadmap including EoS/EoL dates for all components must be maintained.',
   ARRAY['Are all interfaces versioned with backward compatibility policies documented?', 'Is configuration externalised (no hardcoded environment values)?', 'Are EoS/EoL dates tracked for all platform dependencies, libraries, and infrastructure?', 'Is there a technology refresh roadmap?', 'Is the solution designed to absorb regulatory or business model changes without full rearchitecting?'],
   'High', true)
ON CONFLICT (principle_code) DO NOTHING;

-- Business Principles (B-01 to B-10)
INSERT INTO ea_principles (principle_code, principle_name, category, statement, rationale, implications, items_to_verify, arb_weight, is_active)
VALUES 
  ('B-01', 'Customer-Centricity', 'Business',
   'Business architecture must be driven by deep understanding of customer needs, journeys, and outcomes. Every capability, process, and system must be traceable back to customer value.',
   'Customer-centric organisations outperform competitors on retention, satisfaction, and revenue growth. Architecture that is not rooted in customer insight risks misallocating investment.',
   'Customer journey maps must inform capability design. Business use cases must be validated against real customer needs or market research. End-user voices (support tickets, usability feedback, NPS) must be considered as inputs to architecture decisions. Metrics must include customer satisfaction and business outcome measures.',
   ARRAY['Is the customer journey and impacted user population documented?', 'Are customer feedback channels (support, NPS, usability testing) referenced in the business case?', 'Are business use cases validated against actual customer needs?', 'Do success metrics include customer-facing KPIs?'],
   'High', true),
  ('B-02', 'Regulatory Compliance', 'Business',
   'All business processes, data handling, and technology solutions must comply with applicable regulatory, legal, and internal policy requirements by design, not by exception.',
   'Non-compliance exposes the organisation to financial penalties, reputational damage, and operational restrictions. Compliance must be proactively engineered, not reactively applied.',
   'Regulatory requirements (GDPR, SOX, MiFID II, Basel III, etc.) must be identified and mapped to architecture controls at design time. Compliance evidence must be continuously generated and audit-ready. Legal and compliance teams must be engaged for any capability handling regulated data or processes. Regulatory change management must be a defined part of the architecture lifecycle.',
   ARRAY['Are applicable regulatory frameworks identified and documented?', 'Are regulatory controls mapped to architecture components?', 'Is compliance evidence (audit logs, access controls, data handling records) generated and accessible?', 'Has legal and compliance sign-off been obtained where required?', 'Is there a process for incorporating regulatory changes into the architecture?'],
   'Critical', true),
  ('B-03', 'Operational Efficiency', 'Business',
   'Architecture must reduce operational overhead, automate manual processes, and optimise total cost of ownership (TCO). Efficiency gains must be measurable.',
   'Inefficient operations increase cost, introduce errors, and divert resources from innovation. Architecture plays a key role in enabling operational excellence through automation, standardisation, and self-service.',
   'Automation must be applied to repetitive operational tasks (deployment, testing, monitoring, scaling). TCO analysis (development, operations, support, licensing) must accompany significant investment decisions. Shared services and platform investments must demonstrate economies of scale. Operational runbooks must exist and be kept current.',
   ARRAY['Is a TCO analysis (3-year or 5-year) documented?', 'Are manual operational processes identified and automation plans defined?', 'Are monitoring, alerting, and self-healing capabilities in place?', 'Is the solution aligned with shared platform services to avoid duplication of operational overhead?', 'Are operational runbooks available and maintained?'],
   'Medium', true),
  ('B-04', 'Agility and Flexibility', 'Business',
   'Business and technology architecture must be flexible enough to support rapid changes in business strategy, operating model, and market conditions without requiring full system replacement.',
   'Markets and business priorities change rapidly. Rigid architectures cannot adapt without significant cost and delay. Agility is a structural property that must be designed in.',
   'Loosely coupled, modular architectures are preferred over tightly integrated monoliths. Business rules and configuration must be externalised to allow change without code deployment. Interfaces must be stable and versioned to allow independent evolution of components. Teams must be empowered to deploy independently without coordinating with other teams.',
   ARRAY['Is the architecture sufficiently decoupled to allow independent component evolution?', 'Are business rules and configuration externalised?', 'Are interfaces stable and versioned to support independent deployment?', 'Can teams deploy components independently?', 'Is there evidence of architecture adaptability (e.g., how a past business change was absorbed)?'],
   'High', true),
  ('B-05', 'Risk Management', 'Business',
   'Architecture must identify, assess, and mitigate risks across all dimensions — technology, security, operational, regulatory, and vendor. Risk must be a first-class concern, not an afterthought.',
   'Unmanaged architectural risk becomes operational incidents, regulatory failures, or strategic misalignment. Proactive risk identification and mitigation is cheaper than reactive remediation.',
   'A RAID log (Risks, Assumptions, Issues, Dependencies) must be maintained for all significant initiatives. Risk decisions must be documented in ADRs with accepted risk, mitigations, and owners. High-severity risks (security, DR, regulatory) require documented mitigation and sign-off before approval. Risk appetite must be explicitly stated for decisions involving trade-offs.',
   ARRAY['Is a RAID log maintained and current?', 'Are significant risks documented in ADRs with mitigations and owners?', 'Are high-severity risks (security, DR, regulatory) explicitly signed off?', 'Is risk appetite documented for key architectural trade-offs?', 'Are vendor and third-party risks assessed (concentration risk, EoS, support SLAs)?'],
   'Critical', true),
  ('B-06', 'Data-Driven Decision Making', 'Business',
   'Architectural and business decisions must be supported by data and evidence. Anecdote, assumption, and intuition are insufficient justification for significant investment or change.',
   'Evidence-based decisions reduce the likelihood of costly mistakes and improve accountability. Data-driven architectures also enable continuous learning and improvement.',
   'Business cases must be supported by quantitative evidence (usage data, cost data, performance benchmarks). Architecture reviews must be evidence-based — promises of future compliance are insufficient. Observability must be built into solutions to generate the data needed for future decisions. A/B testing and experimentation capabilities should be considered for customer-facing features.',
   ARRAY['Is the business case supported by quantitative data?', 'Is NFR evidence based on actual measurements, not estimates?', 'Are observability capabilities (metrics, logs, traces) built into the solution?', 'Is there a defined mechanism for collecting post-deployment performance data?', 'Are decisions made in the review based on evidence, not promises?'],
   'High', true),
  ('B-07', 'Innovation', 'Business',
   'Architecture must enable and accelerate innovation by providing a stable platform foundation on which new capabilities can be rapidly built, tested, and deployed.',
   'Innovation drives competitive advantage. Architectures that are too rigid, complex, or costly to change inhibit innovation. The platform must be an enabler, not a barrier.',
   'Platform teams must publish stable, well-documented APIs and event streams that enable consuming teams to innovate independently. Sandbox and non-production environments must be available for experimentation. Proof-of-concept and innovation governance must be lightweight and time-boxed. Emerging technology adoption must be governed through the enterprise technology radar.',
   ARRAY['Does the solution expose stable interfaces enabling downstream innovation?', 'Are sandbox/experimentation environments available?', 'Is the technology choice aligned with the enterprise technology radar?', 'Is the solution designed to accommodate future capability extensions without rearchitecting?'],
   'Medium', true),
  ('B-08', 'Collaboration and Integration', 'Business',
   'Architecture must promote collaboration across business domains, technology teams, and external partners through well-defined integration patterns and shared platforms.',
   'Siloed architectures create duplication, integration debt, and poor cross-domain experience. Collaboration architectures enable ecosystem thinking and shared value creation.',
   'All inter-domain integrations must be catalogued and use approved integration patterns. Shared data and event platforms must be preferred over point-to-point integrations. Consumer teams must be engaged during platform design (shift-left consumer involvement). Cross-team architectural decisions must follow the governance process with documented outcomes.',
   ARRAY['Are all integrations catalogued with provider, consumer, pattern, frequency, and data flows documented?', 'Are approved integration patterns (API, event, file, message) applied?', 'Have consuming teams been engaged in the design process?', 'Are shared platforms used in preference to point-to-point integrations?', 'Is there a cross-team governance process for shared interface changes?'],
   'High', true),
  ('B-09', 'Customer Privacy', 'Business',
   'Customer personal data must be handled with the highest standards of privacy, consent, and transparency. Privacy must be designed into every system that collects, stores, processes, or transmits personal data.',
   'Privacy is both a regulatory requirement and a competitive differentiator. Customers expect organisations to handle their data responsibly. Privacy failures erode trust and attract regulatory action.',
   'Privacy Impact Assessments (PIAs) must be conducted for any system handling personal data. Data minimisation principles must be applied — collect only what is needed, retain only as long as required. Consent mechanisms must be implemented where required by regulation. Data subject rights (access, correction, deletion) must be supported by the architecture.',
   ARRAY['Has a Privacy Impact Assessment (PIA) been conducted?', 'Is personal data minimised (collect only what is necessary)?', 'Are retention and disposal policies defined and enforced?', 'Are data subject rights (DSAR, right to erasure) supported?', 'Are consent mechanisms implemented where required?', 'Is personal data isolated from non-personal data where possible?'],
   'Critical', true),
  ('B-10', 'Sustainability', 'Business',
   'Architecture must consider environmental sustainability by optimising resource consumption, minimising waste, and preferring energy-efficient technology choices.',
   'Sustainable architecture reduces environmental impact, lowers operational cost, and meets growing regulatory and investor expectations around ESG (Environmental, Social, Governance).',
   'Cloud resource utilisation must be optimised (right-sizing, auto-scaling, spot instances). Redundant or idle resources must be decommissioned. Technology choices must consider energy efficiency (e.g., serverless, managed services). Sustainability metrics (carbon footprint, energy usage) should be tracked for significant platforms.',
   ARRAY['Is cloud resource utilisation optimised (right-sizing, auto-scaling)?', 'Are idle or redundant resources identified for decommission?', 'Is energy efficiency considered in technology and hosting choices?', 'Are sustainability metrics tracked for the platform?'],
   'Low', true)
ON CONFLICT (principle_code) DO NOTHING;

-- Security Principles (S-01 to S-10)
INSERT INTO ea_principles (principle_code, principle_name, category, statement, rationale, implications, items_to_verify, arb_weight, is_active)
VALUES 
  ('S-01', 'Defense in Depth', 'Security',
   'Security must be implemented in multiple independent layers so that the failure of any single control does not result in a security breach. No single point of security failure is acceptable.',
   'No security control is infallible. Layered defences ensure that an attacker who bypasses one control is stopped by another. This reduces blast radius and attack surface.',
   'Security controls must exist at network, application, data, and identity layers. Network segmentation, firewalls, WAFs, and DDoS protection must be implemented. Encryption must be applied at transit and at rest, independently. Monitoring and anomaly detection must operate across all layers.',
   ARRAY['Are security controls implemented at multiple layers (network, application, data, identity)?', 'Is network segmentation applied (VNets, NSGs, private endpoints)?', 'Are WAF and DDoS protections in place for internet-facing components?', 'Is encryption applied independently at transit (TLS 1.2+) and at rest (AES-256)?', 'Is anomaly detection and alerting active across all security layers?'],
   'Critical', true),
  ('S-02', 'Least Privilege', 'Security',
   'All identities (users, services, applications) must be granted the minimum permissions necessary to perform their required functions, for the minimum required duration.',
   'Excessive privileges increase the impact of a compromise. Least privilege limits the blast radius of a security incident and reduces the risk of accidental or malicious misuse.',
   'RBAC must be implemented with granular, role-specific permissions. Service accounts must have scoped permissions and must not use shared credentials. Just-in-time (JIT) access must be used for privileged operations. Permission reviews must be conducted regularly.',
   ARRAY['Is RBAC implemented with granular, role-appropriate permissions?', 'Are service accounts scoped to minimum required permissions?', 'Is just-in-time (JIT) access used for privileged operations?', 'Are there no shared credentials or overly broad permissions?', 'Is there a regular access review process?', 'Are privileged identity management (PIM) controls in place?'],
   'Critical', true),
  ('S-03', 'Data Encryption', 'Security',
   'All sensitive data must be encrypted both in transit and at rest using approved, current encryption standards. Encryption key management must follow enterprise key vault standards.',
   'Unencrypted data is vulnerable to interception, exfiltration, and regulatory non-compliance. Encryption is a non-negotiable baseline control for all systems handling sensitive or regulated data.',
   'TLS 1.2 or higher is mandatory for all data in transit. AES-256 or equivalent is required for data at rest. Encryption keys must be managed via an approved key management service (e.g., Azure Key Vault). Key rotation policies must be defined and automated.',
   ARRAY['Is TLS 1.2+ enforced for all data in transit?', 'Is data at rest encrypted using AES-256 or equivalent?', 'Are encryption keys managed via Azure Key Vault (or approved equivalent)?', 'Is key rotation automated and documented?', 'Are database encryption (TDE) and backup encryption enabled?', 'Is there no use of deprecated or weak encryption algorithms (MD5, SHA-1, DES)?'],
   'Critical', true),
  ('S-04', 'Identity and Access Management', 'Security',
   'All access to systems, data, and APIs must be authenticated and authorised through a centralised, enterprise-approved identity and access management platform.',
   'Fragmented identity management creates security gaps, audit failures, and operational complexity. Centralised IAM enables consistent policy enforcement, auditability, and rapid response to identity-related threats.',
   'Azure Active Directory (AAD) must be used as the identity provider for all enterprise systems. Multi-factor authentication (MFA) must be enforced for all human users. Service-to-service authentication must use managed identities or certificates, never shared secrets. All access must be logged and available for audit.',
   ARRAY['Is Azure AD (or enterprise-approved IdP) used for all authentication?', 'Is MFA enforced for all human user access?', 'Are managed identities or certificates used for service-to-service authentication?', 'Is all access logged and audit-ready?', 'Are conditional access policies applied based on risk?', 'Is SSO implemented to avoid credential sprawl?'],
   'Critical', true),
  ('S-05', 'Security by Design', 'Security',
   'Security requirements must be defined, designed, and validated during architecture and design phases — not discovered during testing or post-production deployment.',
   'Security defects are 30x more expensive to fix in production than in design. Embedding security in the design process reduces cost, risk, and time to remediation.',
   'Threat modelling (STRIDE or equivalent) must be completed during design. Security user stories and acceptance criteria must be defined in the backlog. Security architecture must be reviewed before development begins. Secure coding standards must be documented and enforced through tooling.',
   ARRAY['Has a threat model (STRIDE or equivalent) been completed?', 'Are security requirements documented as user stories with acceptance criteria?', 'Has the security architecture been reviewed before development started?', 'Are secure coding standards applied and enforced (OWASP Top 10)?', 'Are SAST results clean (no critical or high findings)?'],
   'Critical', true),
  ('S-06', 'Continuous Monitoring', 'Security',
   'All systems must be continuously monitored for security threats, anomalies, and policy violations. Security monitoring must be real-time, automated, and integrated with incident response.',
   'Threats evolve continuously. Static, periodic monitoring is insufficient. Real-time monitoring enables rapid detection and response, minimising the window of exposure.',
   'Security Information and Event Management (SIEM) must be connected to all system components. Alerting thresholds must be defined for all critical security events. Security monitoring dashboards must be available to the security operations team. Log retention must meet regulatory requirements (minimum 12 months online, 7 years archived).',
   ARRAY['Is SIEM integration implemented for all system components?', 'Are security alerting thresholds defined and tested?', 'Is log retention policy meeting regulatory requirements?', 'Are security dashboards available to SecOps?', 'Are there automated responses to known threat patterns?', 'Is user and entity behaviour analytics (UEBA) applied for privileged access?'],
   'High', true),
  ('S-07', 'Incident Response', 'Security',
   'All systems must have a documented, tested incident response plan that enables rapid detection, containment, eradication, and recovery from security incidents.',
   'Security incidents are inevitable. The speed and effectiveness of response determines the business impact. Untested incident response plans fail when they are needed most.',
   'An incident response playbook must exist and be maintained for each system. Runbooks for common security scenarios (data breach, ransomware, DDoS) must be available. Incident response must be tested through tabletop exercises at minimum annually. Recovery time objectives (RTO) must be defined and validated for security incident scenarios.',
   ARRAY['Is an incident response playbook documented and accessible?', 'Are runbooks available for common security scenarios?', 'Has incident response been tested within the last 12 months?', 'Are RTO objectives defined for security incident recovery?', 'Are contact escalation paths documented and current?'],
   'High', true),
  ('S-08', 'Security Awareness Training', 'Security',
   'All personnel with access to enterprise systems must complete regular security awareness training. Security responsibilities must be understood by all team members, not just security specialists.',
   'Human error is the leading cause of security incidents. A security-aware culture reduces susceptibility to phishing, social engineering, and accidental data exposure.',
   'Security awareness training must be mandatory and tracked for all team members. Developers must complete secure development training (OWASP, secure coding) annually. Phishing simulation exercises must be conducted regularly. Security champions must be embedded in development teams.',
   ARRAY['Has the team completed mandatory security awareness training?', 'Have developers completed secure development training?', 'Is a security champion identified in the team?', 'Are there processes for reporting suspicious activity?'],
   'Medium', true),
  ('S-09', 'Compliance (Security)', 'Security',
   'All systems must comply with applicable security standards and frameworks (ISO 27001, SOC 2, NIST, PCI-DSS, DORA, etc.) and internal security policies. Compliance must be demonstrable through evidence, not assertion.',
   'Security compliance frameworks provide proven control frameworks that, when implemented, significantly reduce security risk. Regulatory compliance is also a legal obligation for many system types.',
   'Applicable compliance frameworks must be identified and controls mapped at design time. Compliance evidence must be continuously generated and maintained in an audit-ready state. Non-compliant controls must have documented risk acceptance and remediation timelines. Third-party and vendor compliance must be assessed and contractually required.',
   ARRAY['Are applicable security compliance frameworks identified?', 'Are controls mapped to framework requirements?', 'Is compliance evidence audit-ready and current?', 'Are vendor/third-party compliance certifications reviewed?', 'Are non-compliant areas documented with risk acceptance and remediation plans?'],
   'Critical', true),
  ('S-10', 'Regular Audits and Assessments', 'Security',
   'Security controls, configurations, and architectures must be regularly audited and assessed to identify drift, new vulnerabilities, and gaps relative to evolving threat landscapes.',
   'Technology landscapes change continuously. Security controls that were effective 12 months ago may be insufficient today. Regular assessment is essential to maintaining security posture.',
   'Vulnerability assessments must be conducted at minimum quarterly, or on every significant change. Penetration testing (VAPT) must be conducted at minimum annually for externally facing systems. Configuration management and drift detection must be automated. Audit findings must be tracked to closure with defined SLAs by severity.',
   ARRAY['Is VAPT evidence available and dated within 12 months?', 'Are vulnerability assessments conducted regularly and findings tracked?', 'Is configuration drift detection automated?', 'Are audit findings tracked with severity-based remediation SLAs?', 'Are penetration test findings from previous cycles closed or formally accepted?'],
   'High', true)
ON CONFLICT (principle_code) DO NOTHING;

-- Application Principles (A-01 to A-10)
INSERT INTO ea_principles (principle_code, principle_name, category, statement, rationale, implications, items_to_verify, arb_weight, is_active)
VALUES 
  ('A-01', 'Interoperability', 'Application',
   'Applications must be designed to work seamlessly with other systems through open, standard interfaces and protocols. Proprietary integration mechanisms that create vendor lock-in must be avoided.',
   'Interoperability enables ecosystem integration, reduces integration cost, and protects the organisation from vendor lock-in. Standards-based interfaces outlast proprietary ones.',
   'REST APIs, event-driven interfaces, and standard messaging protocols must be preferred. Open standards (OpenAPI, AsyncAPI, JSON Schema, FHIR, ISO 20022) must be used. Proprietary protocols must be justified with a migration path to standards. Integration catalogue must document all interfaces with standard metadata.',
   ARRAY['Are interfaces designed using open standards (OpenAPI, AsyncAPI, JSON Schema)?', 'Are proprietary protocols avoided or justified with migration plans?', 'Is the integration catalogue complete and up to date?', 'Are all interfaces discoverable through the enterprise API catalogue?', 'Is there a versioning strategy preventing breaking changes?'],
   'High', true),
  ('A-02', 'Scalability (Application)', 'Application',
   'Applications must be designed to scale horizontally and vertically to meet demand growth without requiring architectural changes. Scalability must be validated with evidence, not assumed.',
   'Applications that cannot scale become bottlenecks under growth. Over-provisioning to compensate for poor scalability design is wasteful. Proven scalability requires testing.',
   'Applications must support horizontal scaling (stateless design, shared-nothing architecture). Autoscaling policies must be defined and tested. Performance testing (load, stress, soak) must be conducted and results evidenced. Scalability targets must be defined in terms of TPS, concurrent users, and data volumes.',
   ARRAY['Is the application designed for horizontal scaling (stateless where possible)?', 'Are autoscaling policies defined and tested?', 'Is performance/load testing evidence available?', 'Are scalability targets (TPS, concurrent users, response time) defined and met?', 'Is there a capacity plan for YoY growth?'],
   'High', true),
  ('A-03', 'Modularity', 'Application',
   'Applications must be composed of loosely coupled, independently deployable modules or services with well-defined responsibilities and interfaces.',
   'Modular applications are easier to maintain, test, scale, and evolve. Monolithic tight coupling creates change risk, deployment dependencies, and testing complexity.',
   'Domain-driven design (DDD) bounded contexts must guide service decomposition. Each module must have a single, clear responsibility. Inter-module communication must be through defined, versioned interfaces. Teams must be able to deploy modules independently.',
   ARRAY['Are services/modules decomposed along domain boundaries?', 'Does each module have a clearly defined, single responsibility?', 'Is inter-module communication via versioned, well-documented interfaces?', 'Can modules be deployed independently?', 'Is there a defined ownership model for each module?'],
   'High', true),
  ('A-04', 'User-Centric Design', 'Application',
   'Application interfaces must be designed around the needs, capabilities, and context of the end user. Usability must be validated with real users, not assumed by developers.',
   'Applications designed without user input are frequently misaligned with actual workflows, causing adoption failure, errors, and support overhead.',
   'User research and journey mapping must inform UI/UX design. Accessibility standards (WCAG 2.1 AA minimum) must be met. Usability testing with representative users must be conducted before launch. User feedback loops must be embedded in the operating model post-launch.',
   ARRAY['Is user research or journey mapping documented?', 'Do interfaces meet WCAG 2.1 AA accessibility standards?', 'Has usability testing been conducted with representative users?', 'Are feedback mechanisms embedded for post-launch user input?'],
   'Medium', true),
  ('A-05', 'Cloud Enabled and Native', 'Application',
   'Applications must be designed to leverage cloud platform capabilities (managed services, autoscaling, serverless, global distribution) rather than replicating on-premises patterns in the cloud.',
   'Cloud-native patterns unlock elasticity, resilience, and velocity advantages of cloud platforms. "Lift and shift" of on-premises patterns fails to realise cloud value and often introduces new risks.',
   'Managed cloud services (PaaS, SaaS) must be preferred over IaaS where equivalent capability exists. Applications must be containerised or serverless for portability and scaling. 12-Factor Application principles must be applied. Multi-region and availability zone design must be applied for critical applications.',
   ARRAY['Are cloud-native managed services used in preference to IaaS?', 'Are applications containerised (Docker/Kubernetes) or serverless?', 'Are 12-Factor Application principles applied?', 'Is the application designed for multi-AZ or multi-region where required by availability targets?', 'Are cloud provider lock-in risks assessed and managed?'],
   'High', true),
  ('A-06', 'APIs and Microservices', 'Application',
   'Applications must expose capabilities through well-designed APIs and, where appropriate, adopt a microservices architecture to enable independent deployment, scaling, and evolution of capabilities.',
   'API-first design enables ecosystem integration and product thinking. Microservices enable organisational agility by aligning technical boundaries with team boundaries (Conway''s Law).',
   'APIs must follow enterprise API design standards (RESTful, resource-oriented, versioned, documented). Microservices must be sized to the team that owns them (two-pizza team principle). API gateways must be used for external-facing APIs. Service meshes must be considered for complex microservice communication.',
   ARRAY['Do APIs follow enterprise design standards (OpenAPI, versioned, resource-oriented)?', 'Are microservices appropriately sized and team-aligned?', 'Is an API gateway in use for external-facing APIs?', 'Is inter-service communication secure and observable?', 'Are APIs published to the enterprise API catalogue?'],
   'High', true),
  ('A-07', 'Data Integrity', 'Application',
   'Applications must ensure data remains accurate, consistent, and uncorrupted throughout its lifecycle, including during transactions, integrations, and failures.',
   'Data integrity failures result in incorrect business decisions, financial errors, regulatory non-compliance, and customer harm. Integrity must be enforced at the application and infrastructure levels.',
   'ACID transaction properties must be maintained for financial and critical data operations. Idempotency must be designed into all API and event processing to prevent duplicate processing. Input validation must be enforced at all system boundaries. Data checksums or hash validation must be used for file and message transfers.',
   ARRAY['Are ACID properties applied for transactional data operations?', 'Is idempotency implemented in APIs and event consumers?', 'Is input validation enforced at all system entry points?', 'Are data checksums or hash validation applied for transfers?', 'Are data consistency strategies documented for distributed scenarios?'],
   'Critical', true),
  ('A-08', 'Compliance (Application)', 'Application',
   'Applications must comply with applicable regulatory, industry, and internal standards. Compliance must be evidenced through controls, testing, and audit mechanisms built into the application.',
   'Application-level non-compliance is a direct regulatory and reputational risk. Controls must be embedded in the application, not reliant solely on perimeter defences.',
   'Applicable compliance frameworks must be mapped to application-level controls. Audit logging must capture all significant business events and user actions. Data residency requirements must be respected in hosting and replication decisions. Third-party components must be assessed for compliance implications (licensing, export controls).',
   ARRAY['Are applicable compliance frameworks mapped to application controls?', 'Is audit logging capturing all significant business and user events?', 'Are data residency requirements documented and enforced?', 'Are third-party components assessed for licensing and compliance?'],
   'Critical', true),
  ('A-09', 'High Availability', 'Application',
   'Applications must be designed to meet defined availability targets through redundancy, failover, health monitoring, and graceful degradation. Availability targets must be evidenced, not assumed.',
   'Application downtime has direct financial and reputational consequences. High availability must be an architectural property, not a feature added post-deployment.',
   'All single points of failure must be eliminated or mitigated. Automated health checks and self-healing must be implemented. Failover must be automated and tested. Degraded mode operation (reduced functionality under partial failure) must be designed.',
   ARRAY['Are availability targets (SLA/SLO) defined and evidenced?', 'Is SPOF analysis documented with mitigations?', 'Is automated failover implemented and tested?', 'Is graceful degradation designed for partial failure scenarios?', 'Are health check endpoints implemented and monitored?'],
   'Critical', true),
  ('A-10', 'Performance Optimization', 'Application',
   'Applications must meet defined performance targets under normal and peak load conditions. Performance must be measured, optimised, and continuously monitored.',
   'Poor performance degrades customer experience, increases infrastructure cost, and signals architectural problems. Performance must be treated as a feature, not a non-functional afterthought.',
   'Response time SLOs must be defined (e.g., P95 < 500ms, P99 < 2s). Caching strategies must be applied at appropriate layers. Database query optimisation and indexing must be reviewed. Performance profiling must be conducted as part of the development process.',
   ARRAY['Are response time SLOs defined (P95, P99 targets)?', 'Is performance test evidence (load, stress, soak) available?', 'Is a caching strategy defined and implemented?', 'Have database queries been profiled and optimised?', 'Is performance monitoring in place with alerting on SLO breach?'],
   'High', true)
ON CONFLICT (principle_code) DO NOTHING;

-- Software Principles (SW-01 to SW-10)
INSERT INTO ea_principles (principle_code, principle_name, category, statement, rationale, implications, items_to_verify, arb_weight, is_active)
VALUES 
  ('SW-01', 'Separation of Concerns', 'Software',
   'Software must be structured so that distinct concerns (presentation, business logic, data access, integration) are handled by separate, well-defined components with minimal overlap.',
   'Mixing concerns creates tight coupling, reduces testability, and makes change risky. Clear separation enables independent evolution, testing, and understanding of each component.',
   'Layered architecture (presentation, application, domain, infrastructure) must be applied. Business logic must not be embedded in UI components or database procedures. Cross-cutting concerns (logging, security, caching) must be handled through consistent patterns (e.g., middleware, decorators).',
   ARRAY['Is the architecture structured with clear layer separation?', 'Is business logic separated from presentation and data access?', 'Are cross-cutting concerns handled through consistent, reusable patterns?', 'Can each layer be tested independently?'],
   'High', true),
  ('SW-02', 'Single Responsibility Principle', 'Software',
   'Each software component, module, service, or class must have a single, well-defined responsibility. A component should have only one reason to change.',
   'Components with multiple responsibilities are harder to understand, test, maintain, and evolve. Single responsibility drives cleaner design and reduces the blast radius of changes.',
   'Services must be scoped to a single domain capability. Classes and modules must have narrow, focused interfaces. When a component begins accumulating unrelated responsibilities, refactoring must be planned.',
   ARRAY['Does each service/component have a single, documented responsibility?', 'Are interfaces narrow and focused?', 'Is there evidence of regular refactoring to maintain clean boundaries?'],
   'High', true),
  ('SW-03', 'Encapsulation', 'Software',
   'Internal implementation details of a component must be hidden from consumers. Components must expose only what is necessary through well-defined interfaces.',
   'Exposing internals creates implicit dependencies that make components brittle and difficult to change independently. Encapsulation enables safe internal evolution without breaking consumers.',
   'Internal data structures, database schemas, and implementation details must not be exposed. Public interfaces must be deliberately designed, minimised, and versioned. Domain events rather than direct data access must be used for cross-domain communication.',
   ARRAY['Are internal implementation details hidden from consumers?', 'Are public interfaces deliberately designed and documented?', 'Is cross-domain data access via APIs/events rather than direct database access?'],
   'Medium', true),
  ('SW-04', 'Abstraction', 'Software',
   'Software must use abstraction to hide complexity, isolate dependencies on external systems, and enable interchangeability of implementations without impacting consumers.',
   'Direct dependencies on infrastructure, third-party services, or implementation details make software brittle and untestable. Abstraction enables decoupling and independent evolution.',
   'Repository pattern must be used for data access abstraction. Adaptor/port pattern must be used for external service integration. Infrastructure abstractions must enable switching between cloud providers or services with minimal change. Interfaces must be defined in terms of domain concepts, not implementation details.',
   ARRAY['Are data access and external service integrations abstracted?', 'Can infrastructure dependencies be swapped without impacting business logic?', 'Are interfaces defined in domain terms, not implementation terms?', 'Are abstractions testable with mocks or stubs?'],
   'Medium', true),
  ('SW-05', 'Design for Change', 'Software',
   'Software must be designed with the expectation that requirements will change. Extensibility, configurability, and maintainability must be built-in properties.',
   'The only certainty in software is that requirements will change. Software that is expensive or risky to change accumulates technical debt and inhibits business agility.',
   'Open/Closed Principle: software must be open for extension, closed for modification. Feature flags and configuration-driven behaviour must be preferred over hard-coded logic. Plugin or extension points must be designed for anticipated variation. Test coverage must be sufficient to enable confident change.',
   ARRAY['Are extension points designed for anticipated variation?', 'Is behaviour driven by configuration rather than hard-coded logic where appropriate?', 'Is test coverage sufficient to enable safe refactoring?', 'Is the Open/Closed Principle applied in component design?'],
   'High', true),
  ('SW-06', 'Portability', 'Software',
   'Software must be designed to run across different environments (development, test, production, cloud regions) without requiring environment-specific code changes.',
   'Non-portable software is expensive to deploy, difficult to test, and creates environment-specific defects. Portability is foundational to CI/CD and cloud-native operation.',
   '12-Factor App: all configuration must be externalised via environment variables or configuration services. Containerisation (Docker) must be used to ensure environmental consistency. Infrastructure as Code must be used for environment provisioning. No hardcoded environment values (IP addresses, URLs, credentials) are acceptable.',
   ARRAY['Is all configuration externalised (no hardcoded environment values)?', 'Is the application containerised for environment consistency?', 'Is IaC used for environment provisioning?', 'Can the application be deployed to a new environment without code changes?'],
   'High', true),
  ('SW-07', 'Loose Coupling', 'Software',
   'Software components must have minimal dependencies on each other''s internal implementation. Dependencies must be on stable interfaces, not concrete implementations.',
   'Tightly coupled systems cannot be changed, scaled, or tested independently. Loose coupling is the foundation of maintainable, evolvable systems.',
   'Dependency injection must be used to invert dependencies. Asynchronous messaging must be preferred over synchronous calls for non-time-critical integrations. Event-driven architecture must be considered for decoupling producers from consumers. Consumer-driven contract testing must be used to validate interface compatibility.',
   ARRAY['Is dependency injection used to invert and externalise dependencies?', 'Is asynchronous messaging used where synchronous coupling is unnecessary?', 'Are consumer-driven contract tests in place for critical interfaces?', 'Can components be deployed and scaled independently?'],
   'High', true),
  ('SW-08', 'Code Readability', 'Software',
   'Code must be written to be read by humans first and executed by machines second. Clarity, consistency, and self-documentation are required properties of all production code.',
   'Code is read 10x more than it is written. Unreadable code is a maintenance liability, onboarding barrier, and source of defects.',
   'Enterprise coding standards must be documented and enforced through linting tools. Meaningful naming conventions must be applied to variables, functions, classes, and services. Code review must include readability as an explicit evaluation criterion. Comments must explain ''why'', not ''what'' — the code should explain itself.',
   ARRAY['Are enterprise coding standards documented and enforced through tooling?', 'Are naming conventions consistent and meaningful?', 'Is code review including readability as an explicit criterion?', 'Is cyclomatic complexity within acceptable thresholds?', 'Are static code analysis results (complexity, duplication) within acceptable limits?'],
   'Medium', true),
  ('SW-09', 'Testability', 'Software',
   'All software must be designed to be testable at unit, integration, and system levels. Test automation must be a first-class citizen of the development process.',
   'Untestable software cannot be safely changed. Manual testing does not scale. Test automation is the foundation of confident, high-velocity delivery.',
   'Unit test coverage must meet the defined threshold (typically >80% for critical paths). Integration and API tests must be automated and run in CI/CD pipelines. End-to-end tests must cover critical business flows. Test data management must be addressed for all test environments.',
   ARRAY['Is unit test coverage meeting the defined threshold?', 'Are integration and API tests automated and running in CI/CD?', 'Are end-to-end tests covering critical business flows?', 'Is test data management documented and implemented?', 'Are test results tracked as quality metrics?'],
   'High', true),
  ('SW-10', 'Dependency Injection', 'Software',
   'Dependencies must be injected into components from the outside rather than created internally. Components must not be responsible for constructing their own dependencies.',
   'Internal dependency construction creates tight coupling, makes testing difficult (dependencies cannot be mocked), and inhibits flexibility. Dependency injection enables testability and extensibility.',
   'A dependency injection container or framework must be used. All external dependencies (databases, message brokers, external services) must be injected. Dependencies must be expressed as interfaces, not concrete types. Testing must use injected mocks or stubs, not real external dependencies.',
   ARRAY['Is a dependency injection framework in use?', 'Are all external dependencies injected as interfaces?', 'Are unit tests using injected mocks for external dependencies?', 'Is the component dependency graph clean (no circular dependencies)?'],
   'Medium', true)
ON CONFLICT (principle_code) DO NOTHING;

-- Data Principles (D-01 to D-10)
INSERT INTO ea_principles (principle_code, principle_name, category, statement, rationale, implications, items_to_verify, arb_weight, is_active)
VALUES 
  ('D-01', 'Quality', 'Data',
   'Data must meet defined quality standards across accuracy, completeness, consistency, timeliness, and validity. Data quality must be monitored continuously and managed proactively.',
   'Poor data quality leads to flawed business decisions, regulatory non-compliance, and loss of stakeholder trust. Quality must be managed as a measurable, owned property of data assets.',
   'Data quality dimensions must be defined for each data domain (accuracy, completeness, timeliness, validity, consistency). Data quality rules must be implemented at ingestion and transformation points. Data quality dashboards must be published to data owners. Data quality SLOs must be defined and breaches must trigger remediation workflows.',
   ARRAY['Are data quality dimensions defined for key data entities?', 'Are data quality rules implemented at ingestion and transformation?', 'Is data quality monitored and surfaced through dashboards?', 'Are data quality SLOs defined and tracked?', 'Is there a data quality issue remediation process?'],
   'High', true),
  ('D-02', 'Governance', 'Data',
   'Data must be governed through defined policies, standards, ownership, and stewardship across its full lifecycle. Data governance must be institutionalised, not ad hoc.',
   'Ungoverned data creates inconsistency, security risk, regulatory exposure, and inability to derive value. Governance provides the framework for responsible, consistent data management.',
   'A data governance framework must define ownership, stewardship, classification, and policy enforcement. Data must be catalogued in the enterprise data catalogue with metadata. Data policies must be enforced through technical controls, not just processes. Data governance roles (data owner, data steward, data custodian) must be defined and assigned.',
   ARRAY['Are data governance roles (owner, steward, custodian) defined and assigned?', 'Is data catalogued in the enterprise data catalogue?', 'Are data policies technically enforced?', 'Is there a data governance committee or process for resolving data disputes?'],
   'Critical', true),
  ('D-03', 'Integration (Data)', 'Data',
   'Data must be integrated across systems using approved, standard patterns that preserve data quality, lineage, and consistency. Direct database-to-database integration is prohibited.',
   'Uncontrolled data integration creates consistency issues, hidden dependencies, and compliance risk. Governed integration patterns ensure data quality and lineage are maintained.',
   'Data integration must use approved patterns: API, event stream, data product, or approved ETL platform. Direct database access across domain boundaries is prohibited. Data integration must be catalogued with source, target, transformation logic, frequency, and data lineage. Data contracts must be established between data producers and consumers.',
   ARRAY['Are all data integrations using approved patterns (API, event, data product, ETL)?', 'Is direct cross-domain database access absent?', 'Are data integrations catalogued with lineage documented?', 'Are data contracts established and versioned?'],
   'High', true),
  ('D-04', 'Single Source of Truth', 'Data',
   'Each data entity must have exactly one authoritative source system. All other systems must consume the canonical version from that source rather than maintaining their own copies.',
   'Multiple authoritative sources for the same data create inconsistency, reconciliation overhead, and conflicting business decisions. A single source of truth enables consistent, trustworthy data.',
   'The golden record and its authoritative source system must be documented for all key data entities. Data replication must be governed (only to approved targets, with freshness SLAs). Data consumers must not modify replicated data — they must request changes via the source system. Master Data Management (MDM) must be applied for critical shared data entities.',
   ARRAY['Is the authoritative source documented for all key data entities?', 'Is data replication governed with freshness SLAs?', 'Are consumers prevented from modifying replicated data?', 'Is MDM applied for critical shared entities (customer, product, account)?'],
   'High', true),
  ('D-05', 'Accessibility (Data)', 'Data',
   'Data must be accessible to authorised consumers in the right format, at the right time, through approved, self-service mechanisms. Access must be controlled, audited, and easy for authorised users.',
   'Data that cannot be accessed efficiently creates shadow data stores, manual workarounds, and missed business value. Accessibility must be balanced with governance and security.',
   'Data must be published through approved channels (APIs, data catalogue, data products, approved analytics platforms). Self-service data discovery must be enabled through the enterprise data catalogue. Access controls must be granular (row-level, column-level where required). Data access must be audited and logged.',
   ARRAY['Is data published through approved channels?', 'Is the enterprise data catalogue populated with metadata and access information?', 'Is access control granular (row/column level where required)?', 'Is data access audited and log retained per policy?', 'Is there a self-service mechanism for authorised users to discover and request access?'],
   'Medium', true),
  ('D-06', 'Retention and Disposal', 'Data',
   'All data must have defined retention policies based on business, regulatory, and legal requirements. Data must be disposed of securely and completely when retention periods expire.',
   'Retaining data beyond its required period increases regulatory risk, storage cost, and breach impact. Disposing of data too early violates legal requirements. Policy must govern the balance.',
   'Retention policies must be defined for each data classification and regulatory obligation. Automated data archival and deletion pipelines must be implemented. Secure deletion (cryptographic erasure or certified deletion) must be applied. Retention and disposal records must be maintained for audit.',
   ARRAY['Are data retention policies defined for each data type and classification?', 'Is automated data archival and deletion implemented?', 'Is secure deletion applied (cryptographic erasure or certified wipe)?', 'Are retention and disposal records maintained?', 'Are legal hold processes defined and implemented?'],
   'Critical', true),
  ('D-07', 'Master Data Management', 'Data',
   'Critical shared data entities (customer, product, account, counterparty, reference data) must be managed through a defined Master Data Management capability that ensures consistency, accuracy, and single-source governance.',
   'Inconsistent master data across systems results in duplicate records, reconciliation failures, and incorrect business outcomes. MDM provides the authoritative, trusted version of critical shared data.',
   'MDM scope must be defined, identifying which entities require MDM treatment. MDM matching, merging, and deduplication rules must be documented. All systems must consume master data from the MDM hub, not maintain their own copies. MDM data quality must be monitored and reported.',
   ARRAY['Are critical shared entities managed through the MDM platform?', 'Are MDM matching and deduplication rules documented?', 'Are all systems consuming from the MDM hub?', 'Is MDM data quality monitored?'],
   'High', true),
  ('D-08', 'Analytics', 'Data',
   'Data architecture must support the analytics and reporting needs of the organisation through a governed, performant, and accessible analytics platform. Analytics must not be bolt-on.',
   'Data that cannot be analysed cannot generate business value. Analytics capability must be a designed component of the data architecture, not an afterthought.',
   'Analytics platform architecture (data warehouse, data lakehouse, OLAP) must be defined. Data must be modelled and published in a form suitable for analytics consumption. Self-service analytics must be enabled for business users through approved tooling. Analytics data must be subject to the same governance, quality, and security standards as operational data.',
   ARRAY['Is an analytics platform defined and used for reporting?', 'Is data modelled (dimensional, wide table, or equivalent) for analytics?', 'Is self-service analytics available for business users?', 'Are analytics datasets subject to data governance and quality controls?'],
   'Medium', true),
  ('D-09', 'Lineage', 'Data',
   'The origin, transformation history, and consumption of all data must be traceable end-to-end. Data lineage must be captured automatically and be available for audit and impact analysis.',
   'Data lineage is essential for regulatory compliance (BCBS 239, GDPR), debugging data quality issues, impact assessment of changes, and building trust in data. Manual lineage documentation is insufficient.',
   'Data lineage must be captured automatically through the data pipeline tooling. Lineage must include source system, transformation logic, timestamp, and target system. Data lineage must be queryable for impact analysis (what downstream data is affected if a source changes?). Lineage must be retained for the lifetime of the data plus the regulatory retention period.',
   ARRAY['Is data lineage captured automatically?', 'Does lineage cover source, transformations, and consumption?', 'Is lineage queryable for impact analysis?', 'Is lineage retained per regulatory requirements?', 'Is lineage used as evidence in regulatory compliance reporting?'],
   'High', true),
  ('D-10', 'Interoperability (Data)', 'Data',
   'Data formats, schemas, and standards must be interoperable across systems and with external parties. Proprietary data formats that prevent integration must be avoided.',
   'Proprietary data formats create integration barriers, limit ecosystem participation, and increase migration cost. Open, standard formats reduce friction and extend the useful life of data assets.',
   'Open data formats and standards must be preferred (JSON, Parquet, Avro, CSV, XML, ISO standards). Schema registries must be used for event and message data to ensure consumer compatibility. Data exchange with external parties must use agreed, documented standards. Schema evolution must be backward-compatible by default.',
   ARRAY['Are open, standard data formats used?', 'Is a schema registry in use for event data?', 'Are schemas backward-compatible across versions?', 'Is external data exchange using agreed standards?'],
   'Medium', true)
ON CONFLICT (principle_code) DO NOTHING;

-- Infrastructure Principles (I-01 to I-10)
INSERT INTO ea_principles (principle_code, principle_name, category, statement, rationale, implications, items_to_verify, arb_weight, is_active)
VALUES 
  ('I-01', 'Scalability (Infrastructure)', 'Infrastructure',
   'Infrastructure must scale dynamically to meet workload demand without manual intervention. Infrastructure scalability must be validated and must not impose limits on application scalability.',
   'Static infrastructure provisioning leads to either over-provisioning (wasteful) or under-provisioning (service degradation). Dynamic, elastic infrastructure is foundational to modern operations.',
   'Horizontal auto-scaling must be configured for all compute workloads. Infrastructure capacity limits must be well above peak workload projections. Capacity planning reviews must be conducted regularly. Infrastructure-as-Code must be used to enable rapid, repeatable provisioning.',
   ARRAY['Is auto-scaling configured and tested for all compute workloads?', 'Is infrastructure capacity above peak workload projections with headroom?', 'Is a capacity planning review process in place?', 'Is IaC used for all infrastructure provisioning?', 'Have infrastructure scaling limits been tested under simulated peak load?'],
   'High', true),
  ('I-02', 'Reliability (Infrastructure)', 'Infrastructure',
   'Infrastructure must be designed for high reliability through redundancy, automated failover, and self-healing capabilities. Infrastructure failures must not result in application downtime beyond defined RTO.',
   'Infrastructure is the foundation of application reliability. Unreliable infrastructure makes application-level reliability impossible to achieve regardless of application design quality.',
   'All infrastructure components must be deployed across multiple availability zones. Automated health checks and self-healing must be implemented at the infrastructure layer. Infrastructure monitoring must detect failures faster than they impact users. Failover must be tested regularly, not just documented.',
   ARRAY['Are infrastructure components deployed across multiple availability zones?', 'Is automated failover tested and evidenced?', 'Is infrastructure health monitoring in place with alerting?', 'Are self-healing mechanisms (auto-restart, auto-replacement) implemented?', 'Is there evidence of regular failover testing?'],
   'Critical', true),
  ('I-03', 'Standardization', 'Infrastructure',
   'Infrastructure components, configurations, and operating procedures must be standardised across the enterprise. Non-standard infrastructure must be justified and have a migration plan.',
   'Infrastructure diversity increases operational complexity, skill requirements, security risk, and support cost. Standardisation enables shared tooling, skills, and efficient operations.',
   'Enterprise-approved infrastructure platforms, OS images, and runtimes must be used. Deviation from standards requires ARB approval and a documented migration plan. Golden image management must be applied for VM and container base images. Configuration standards must be enforced through policy-as-code.',
   ARRAY['Are enterprise-approved infrastructure platforms and runtimes used?', 'Are deviations from standards documented with migration plans?', 'Are golden images used for VM and container base images?', 'Is policy-as-code enforced for infrastructure configuration?'],
   'High', true),
  ('I-04', 'Cost Efficiency', 'Infrastructure',
   'Infrastructure must be provisioned and operated at the minimum cost required to meet performance, reliability, and compliance requirements. Waste must be identified and eliminated continuously.',
   'Infrastructure cost is a significant and growing component of technology spend. Inefficient infrastructure provisioning and operation consumes budget that could fund innovation.',
   'Right-sizing analysis must be conducted regularly. Reserved instances and committed use discounts must be applied for steady-state workloads. Unused or idle resources must be identified and decommissioned. Cost allocation tagging must be applied to all infrastructure resources. FinOps practices must be adopted for cloud cost management.',
   ARRAY['Is a TCO/cost analysis conducted for the infrastructure design?', 'Are right-sizing recommendations applied?', 'Are reserved instances used for predictable workloads?', 'Are idle/unused resources identified for decommission?', 'Is cost allocation tagging applied to all resources?', 'Is there a FinOps review process for cloud spend?'],
   'Medium', true),
  ('I-05', 'Energy Efficiency', 'Infrastructure',
   'Infrastructure must be operated with consideration for energy consumption and environmental impact. Energy-efficient technology choices and operational practices must be preferred.',
   'Data centres and cloud infrastructure are significant energy consumers. Energy efficiency reduces environmental impact, lowers operating cost, and meets ESG reporting obligations.',
   'Serverless and managed services must be preferred over always-on compute where workload patterns suit. Resource utilisation targets must be set to avoid low-utilisation waste. Regions with higher renewable energy mix must be preferred for non-latency-sensitive workloads. Energy consumption metrics must be tracked and reported.',
   ARRAY['Are serverless or managed services used where workload patterns allow?', 'Are resource utilisation targets defined and monitored?', 'Is region selection considering renewable energy availability where possible?', 'Are energy consumption or carbon metrics tracked?'],
   'Low', true),
  ('I-06', 'Cloud Integration', 'Infrastructure',
   'Infrastructure must leverage native cloud integration capabilities, services, and APIs to maximise the value derived from cloud platform investment and minimise custom integration overhead.',
   'Cloud-native integration services reduce operational overhead, improve reliability through managed SLAs, and accelerate delivery. Replicating on-premises integration patterns in the cloud negates cloud value.',
   'Cloud-native integration services (Azure Service Bus, Event Grid, API Management, Logic Apps) must be preferred. On-premises connectivity must use approved, secure patterns (ExpressRoute, VPN, private endpoints). Multi-cloud strategies must be governed to avoid unmanaged cloud sprawl. Cloud integration patterns must be documented in the enterprise integration catalogue.',
   ARRAY['Are cloud-native integration services used in preference to custom solutions?', 'Is on-premises connectivity using approved, secure patterns?', 'Is multi-cloud usage governed and justified?', 'Are cloud integration patterns documented in the enterprise catalogue?'],
   'High', true),
  ('I-07', 'Automation', 'Infrastructure',
   'All infrastructure provisioning, configuration, deployment, monitoring, and remediation must be automated. Manual infrastructure operations are a source of inconsistency and risk.',
   'Manual infrastructure operations are slow, error-prone, and impossible to audit accurately. Automation enables consistency, speed, auditability, and the ability to recover rapidly from failure.',
   'Infrastructure-as-Code (Terraform, Bicep, ARM templates) must be used for all provisioning. Configuration-as-Code (Ansible, DSC) must be used for all configuration management. Deployment pipelines must fully automate infrastructure changes. Runbook automation must replace manual operational procedures wherever possible.',
   ARRAY['Is IaC used for all infrastructure provisioning?', 'Is configuration-as-code used for all configuration management?', 'Is infrastructure change deployed through automated pipelines?', 'Are manual runbooks being progressively replaced with automation?', 'Is there an automation maturity roadmap for operations?'],
   'High', true),
  ('I-08', 'Resilience (Infrastructure)', 'Infrastructure',
   'Infrastructure must be designed to continue operating or recover rapidly in the face of component failures, network disruptions, and disaster scenarios. Resilience must be tested, not assumed.',
   'Infrastructure resilience is the foundation of application availability. Designed and tested resilience prevents business disruption from infrastructure failures.',
   'Infrastructure must implement redundancy at every critical layer (compute, network, storage). Disaster recovery procedures must be documented and tested at least annually. Backup and restore must be automated and tested. Chaos engineering must be applied to validate resilience under failure conditions.',
   ARRAY['Is redundancy implemented at all critical infrastructure layers?', 'Is DR documented and tested annually (with evidence)?', 'Are backup and restore processes automated and tested?', 'Is chaos engineering or fault injection used to validate resilience?', 'Are RTO and RPO targets defined and validated through testing?'],
   'Critical', true),
  ('I-09', 'No Single Point of Failure', 'Infrastructure',
   'Infrastructure architecture must eliminate all single points of failure. Every critical component must have a redundant counterpart capable of taking over without manual intervention.',
   'A single failed component should never result in system-wide outage. SPOF elimination is a fundamental reliability engineering practice.',
   'All critical components (load balancers, databases, queues, compute, network) must be deployed in active-active or active-passive redundant configuration. Geographic redundancy must be applied for the highest-criticality systems. SPOF analysis must be documented and reviewed as part of every architecture review. Single DNS records, single network paths, and single database instances are not acceptable for production systems.',
   ARRAY['Is a SPOF analysis documented for all critical infrastructure components?', 'Are all critical components deployed in redundant configuration?', 'Are active-active or active-passive failover patterns applied?', 'Is geographic redundancy applied for critical systems?', 'Are network paths redundant (multiple uplinks, BGP failover)?'],
   'Critical', true),
  ('I-10', 'Interoperability (Infrastructure)', 'Infrastructure',
   'Infrastructure must support interoperability with existing enterprise platforms, tooling, and future technology choices through the use of open standards, standard APIs, and infrastructure abstraction layers.',
   'Proprietary infrastructure lock-in increases switching cost and reduces flexibility. Interoperable infrastructure enables technology evolution without full replacement.',
   'Open infrastructure standards and APIs must be preferred (Kubernetes, Terraform, OpenTelemetry). Infrastructure abstraction layers must be used to insulate applications from infrastructure specifics. Vendor lock-in risks must be assessed and managed in infrastructure choices. Infrastructure interoperability must be tested when integrating with enterprise shared services.',
   ARRAY['Are open infrastructure standards and APIs used?', 'Is infrastructure abstraction applied to insulate applications from infrastructure specifics?', 'Are vendor lock-in risks assessed and documented?', 'Does the infrastructure integrate with enterprise shared services (monitoring, security, identity)?'],
   'Medium', true)
ON CONFLICT (principle_code) DO NOTHING;

-- ============================================================================
-- PRINCIPLE-DOMAIN MAPPINGS
-- ============================================================================

-- Map General principles to general domain
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 3
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'G-%' AND d.slug = 'general'
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map Business principles to business domain
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 3
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'B-%' AND d.slug = 'business'
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map Security principles to devsecops domain
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 3
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'S-%' AND d.slug = 'devsecops'
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map Application principles to application domain
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 3
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'A-%' AND d.slug = 'application'
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map Software principles to application domain
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 3
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'SW-%' AND d.slug = 'application'
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map Data principles to data domain
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 3
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'D-%' AND d.slug = 'data'
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map Infrastructure principles to infrastructure domain
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 3
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'I-%' AND d.slug = 'infrastructure'
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map General principles to all other domains with lower relevance
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 1
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'G-%' 
AND d.slug IN ('business', 'application', 'integration', 'data', 'infrastructure', 'devsecops', 'nfr')
ON CONFLICT (principle_id, domain_id) DO NOTHING;

-- Map Security principles to all domains with lower relevance
INSERT INTO principle_domains (principle_id, domain_id, relevance_score)
SELECT p.id, d.id, 2
FROM ea_principles p, domains d
WHERE p.principle_code LIKE 'S-%' 
AND d.slug IN ('general', 'business', 'application', 'integration', 'data', 'infrastructure', 'nfr')
ON CONFLICT (principle_id, domain_id) DO NOTHING;
