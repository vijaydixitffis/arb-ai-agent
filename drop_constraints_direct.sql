-- Direct SQL to drop all check constraints from review outcome tables
ALTER TABLE public.domain_reviews DROP CONSTRAINT IF EXISTS chk_dr_domain;
ALTER TABLE public.recommendations DROP CONSTRAINT IF EXISTS recommendations_priority_check;
ALTER TABLE public.actions DROP CONSTRAINT IF EXISTS actions_proposed_due_date_check;
ALTER TABLE public.adrs DROP CONSTRAINT IF EXISTS chk_adrs_domain;
ALTER TABLE public.adrs DROP CONSTRAINT IF EXISTS adrs_proposed_target_date_check;
