-- Copy and paste this SQL into the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/lufwpadentelascwohlg/sql

-- Drop all check constraints from review outcome tables
ALTER TABLE public.domain_reviews DROP CONSTRAINT IF EXISTS chk_dr_domain;
ALTER TABLE public.domain_reviews DROP CONSTRAINT IF EXISTS chk_dr_agent_status;
ALTER TABLE public.domain_reviews DROP CONSTRAINT IF EXISTS chk_dr_evidence_quality;
ALTER TABLE public.domain_reviews DROP CONSTRAINT IF EXISTS chk_dr_rag_label;
ALTER TABLE public.domain_reviews DROP CONSTRAINT IF EXISTS chk_dr_rag_score;
ALTER TABLE public.domain_reviews DROP CONSTRAINT IF EXISTS chk_dr_readiness;

ALTER TABLE public.recommendations DROP CONSTRAINT IF EXISTS recommendations_priority_check;
ALTER TABLE public.recommendations DROP CONSTRAINT IF EXISTS chk_rec_domain;

-- Add missing columns to recommendations table
ALTER TABLE public.recommendations 
ADD COLUMN IF NOT EXISTS recommendation_id text,
ADD COLUMN IF NOT EXISTS applies_to_finding_id text,
ADD COLUMN IF NOT EXISTS applies_to_adr_id text;

ALTER TABLE public.actions DROP CONSTRAINT IF EXISTS actions_status_check;
ALTER TABLE public.actions DROP CONSTRAINT IF EXISTS actions_proposed_due_date_check;

ALTER TABLE public.adrs DROP CONSTRAINT IF EXISTS adrs_status_check;
ALTER TABLE public.adrs DROP CONSTRAINT IF EXISTS chk_adrs_domain;
ALTER TABLE public.adrs DROP CONSTRAINT IF EXISTS chk_adrs_type;
ALTER TABLE public.adrs DROP CONSTRAINT IF EXISTS adrs_proposed_target_date_check;

ALTER TABLE public.findings DROP CONSTRAINT IF EXISTS chk_findings_rag;
ALTER TABLE public.findings DROP CONSTRAINT IF EXISTS findings_severity_check;

ALTER TABLE public.domain_scores DROP CONSTRAINT IF EXISTS domain_scores_score_check;

ALTER TABLE public.nfr_scorecard DROP CONSTRAINT IF EXISTS chk_nfr_rag_score;

ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS chk_reviews_agg_label;
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS chk_reviews_agg_rag;
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS chk_reviews_ea_decision;
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS chk_reviews_rec_decision;
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS valid_decision;
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS valid_status;

ALTER TABLE public.question_registry DROP CONSTRAINT IF EXISTS qr_agent_domain;
ALTER TABLE public.question_registry DROP CONSTRAINT IF EXISTS qr_blank_nc_severity;
ALTER TABLE public.question_registry DROP CONSTRAINT IF EXISTS qr_frontend_tab;
ALTER TABLE public.question_registry DROP CONSTRAINT IF EXISTS qr_weight;

-- Refresh schema cache
NOTIFY pgbouncer;
