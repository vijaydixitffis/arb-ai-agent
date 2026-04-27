UPDATE reviews 
SET 
    status = 'submitted',
    decision = NULL,
    tokens_used = NULL,
    processing_time_ms = NULL,
    llm_model = NULL,
    report_json = NULL,
    reviewed_at = NULL
WHERE id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
 
-- Also clean up related tables
DELETE FROM domain_scores WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
DELETE FROM findings WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
DELETE FROM actions WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
DELETE FROM adrs WHERE review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';
 
SELECT id, solution_name, status, decision, reviewed_at FROM reviews WHERE id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1';