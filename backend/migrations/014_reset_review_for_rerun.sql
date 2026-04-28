-- Reset review for rerun: delete AI-generated entries and set status to submitted
-- Review ID: 825ebd8f-c8db-4654-9b83-0ebca7ffd5e1

BEGIN;

-- Delete AI-generated review data
DELETE FROM findings WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
DELETE FROM adrs WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
DELETE FROM actions WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
DELETE FROM domain_scores WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';

-- Reset review status to submitted and clear AI-related fields
UPDATE reviews
SET status = 'submitted',
    decision = NULL,
    reviewed_at = NULL,
    llm_raw_response = NULL,
    tokens_used = NULL,
    processing_time_ms = NULL,
    ea_user_id = NULL,
    ea_override_notes = NULL,
    ea_overridden_at = NULL,
    report_json = report_json - 'ai_review'  -- Remove ai_review from report_json
WHERE id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';

COMMIT;

-- Verify the reset
SELECT id, solution_name, status, decision, reviewed_at
FROM reviews
WHERE id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
