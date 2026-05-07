-- ===============================================================
-- SQL Script: Cleanup Review Data for EDMS Project
-- Review ID: 4ff6f3c1-0a3d-42a9-914d-e9f9d52184df
-- Generated: 2026-05-07
-- Purpose: Clean up all review result tables (excluding reviews and audit_logs)
-- ===============================================================

-- ===============================================================
-- CLEANUP STATEMENTS FOR REVIEW TABLES
-- ===============================================================

-- Clean up all inserted data for specific review (except reviews and audit_logs tables)
-- This allows for re-running script without conflicts

-- Clean up domain_scores (has unique constraint on review_id, domain)
DELETE FROM public.domain_scores WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up domain_reviews (has unique constraint on review_id, domain)
DELETE FROM public.domain_reviews WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up recommendations (references findings and ADRs)
DELETE FROM public.recommendations WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up NFR scorecard
DELETE FROM public.nfr_scorecard WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up blockers (references findings and actions)
DELETE FROM public.blockers WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up ADRs (referenced by recommendations)
DELETE FROM public.adrs WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up actions (referenced by blockers)
DELETE FROM public.actions WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up findings (referenced by actions and recommendations)
DELETE FROM public.findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- ===============================================================
-- RESET REVIEW STATUS FOR RE-RUN
-- ===============================================================

-- Reset review status to allow re-running the review process
UPDATE public.reviews SET 
    status = 'drafting',
    decision = NULL,
    agent_started_at = NULL,
    agent_completed_at = NULL,
    reviewed_at = NULL,
    llm_raw_response = NULL,
    tokens_used = NULL,
    processing_time_ms = NULL,
    aggregate_rag_score = NULL,
    aggregate_rag_label = NULL,
    recommended_decision = NULL,
    decision_rationale = NULL,
    agent_run_at = NULL,
    ea_decision = NULL,
    ea_override_notes = NULL,
    ea_overridden_at = NULL,
    ea_override_json = NULL,
    rework_gaps = NULL,
    arb_meeting_at = NULL,
    arb_meeting_scheduled_at = NULL,
    consolidated_blockers = '[]'::jsonb,
    consolidated_actions = '[]'::jsonb,
    report_json = NULL,
    return_count = 0
WHERE id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- ===============================================================
-- CLEANUP VERIFICATION QUERIES
-- ===============================================================

-- Verify cleanup was successful
SELECT 
    'Findings' as table_name, COUNT(*) as record_count FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Actions', COUNT(*) FROM actions WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'ADRs', COUNT(*) FROM adrs WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Domain_Reviews', COUNT(*) FROM domain_reviews WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Recommendations', COUNT(*) FROM recommendations WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'NFR_Scorecard', COUNT(*) FROM nfr_scorecard WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Blockers', COUNT(*) FROM blockers WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Domain_Scores', COUNT(*) FROM domain_scores WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Verify review status reset
SELECT 
    'Review Status' as info_type,
    status,
    decision,
    agent_started_at,
    agent_completed_at,
    reviewed_at,
    tokens_used,
    processing_time_ms
FROM reviews 
WHERE id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- ===============================================================
-- END OF SCRIPT
-- ===============================================================
