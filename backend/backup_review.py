#!/usr/bin/env python3
"""Backup AI review tables for a specific review_id as SQL INSERT statements"""

from app.core.database import get_db
from app.db.review_models import Review, DomainScore, Finding, ADR, Action
import json

def main():
    db = next(get_db())
    review_id = '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1'

    # Get review
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        print('Review not found')
        return

    # Get related records
    domain_scores = db.query(DomainScore).filter(DomainScore.review_id == review_id).all()
    findings = db.query(Finding).filter(Finding.review_id == review_id).all()
    adrs = db.query(ADR).filter(ADR.review_id == review_id).all()
    actions = db.query(Action).filter(Action.review_id == review_id).all()

    # Generate INSERT statements
    output = []
    output.append('-- Backup for review_id: ' + str(review_id))
    output.append('-- Solution: ' + review.solution_name)
    output.append('-- Generated at: ' + str(review.created_at))
    output.append('')

    # Review table
    output.append('-- REVIEW TABLE')
    output.append(f"INSERT INTO reviews (id, created_at, submitted_at, reviewed_at, sa_user_id, solution_name, scope_tags, status, decision, llm_model, tokens_used, processing_time_ms, llm_raw_response, ea_user_id, ea_override_notes, ea_overridden_at, report_json)")
    output.append(f"VALUES (")
    output.append(f"  '{review.id}',")
    output.append(f"  '{review.created_at}',")
    output.append(f"  '{review.submitted_at}'" if review.submitted_at else "NULL",)
    output.append(f"  '{review.reviewed_at}'" if review.reviewed_at else "NULL",)
    output.append(f"  '{review.sa_user_id}'" if review.sa_user_id else "NULL",)
    solution_name_escaped = review.solution_name.replace("'", "''")
    output.append(f"  '{solution_name_escaped}',")
    output.append(f"  ARRAY{review.scope_tags},")
    output.append(f"  '{review.status}',")
    output.append(f"  '{review.decision}'" if review.decision else "NULL",)
    output.append(f"  '{review.llm_model}',")
    output.append(f"  {review.tokens_used},")
    output.append(f"  {review.processing_time_ms},")
    if review.llm_raw_response:
        llm_escaped = review.llm_raw_response.replace("'", "''")
        output.append(f"  E'{llm_escaped}',")
    else:
        output.append(f"  NULL,")
    output.append(f"  '{review.ea_user_id}'" if review.ea_user_id else "NULL",)
    if review.ea_override_notes:
        notes_escaped = review.ea_override_notes.replace("'", "''")
        output.append(f"  '{notes_escaped}',")
    else:
        output.append(f"  NULL,")
    output.append(f"  '{review.ea_overridden_at}'" if review.ea_overridden_at else "NULL",)
    report_json_escaped = json.dumps(review.report_json).replace("'", "''")
    output.append(f"  '{report_json_escaped}'::jsonb")
    output.append(");")
    output.append('')

    # Domain scores
    output.append('-- DOMAIN_SCORES TABLE')
    for ds in domain_scores:
        output.append(f"INSERT INTO domain_scores (id, review_id, domain, score, created_at)")
        output.append(f"VALUES ('{ds.id}', '{ds.review_id}', '{ds.domain}', {ds.score}, '{ds.created_at}');")
    output.append('')

    # Findings
    output.append('-- FINDINGS TABLE')
    for f in findings:
        output.append(f"INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)")
        output.append(f"VALUES (")
        output.append(f"  '{f.id}',")
        output.append(f"  '{f.review_id}',")
        output.append(f"  '{f.domain}',")
        output.append(f"  '{f.principle_id}'" if f.principle_id else "NULL",)
        output.append(f"  '{f.severity}',")
        finding_escaped = f.finding.replace("'", "''")
        output.append(f"  '{finding_escaped}',")
        if f.recommendation:
            rec_escaped = f.recommendation.replace("'", "''")
            output.append(f"  '{rec_escaped}',")
        else:
            output.append(f"  NULL,")
        output.append(f"  {str(f.is_resolved).lower()},")
        output.append(f"  '{f.created_at}'")
        output.append(");")
    output.append('')

    # ADRs
    output.append('-- ADRS TABLE')
    for adr in adrs:
        output.append(f"INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)")
        output.append(f"VALUES (")
        output.append(f"  '{adr.id}',")
        output.append(f"  '{adr.review_id}',")
        output.append(f"  '{adr.adr_id}',")
        decision_escaped = adr.decision.replace("'", "''")
        output.append(f"  '{decision_escaped}',")
        rationale_escaped = adr.rationale.replace("'", "''")
        output.append(f"  '{rationale_escaped}',")
        if adr.context:
            context_escaped = adr.context.replace("'", "''")
            output.append(f"  '{context_escaped}',")
        else:
            output.append(f"  NULL,")
        if adr.consequences:
            consequences_escaped = adr.consequences.replace("'", "''")
            output.append(f"  '{consequences_escaped}',")
        else:
            output.append(f"  NULL,")
        output.append(f"  '{adr.owner}'" if adr.owner else "NULL",)
        output.append(f"  '{adr.target_date}'" if adr.target_date else "NULL",)
        output.append(f"  '{adr.status}',")
        output.append(f"  '{adr.created_at}',")
        output.append(f"  '{adr.updated_at}'")
        output.append(");")
    output.append('')

    # Actions
    output.append('-- ACTIONS TABLE')
    for act in actions:
        output.append(f"INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)")
        output.append(f"VALUES (")
        output.append(f"  '{act.id}',")
        output.append(f"  '{act.review_id}',")
        action_escaped = act.action_text.replace("'", "''")
        output.append(f"  '{action_escaped}',")
        output.append(f"  '{act.status}',")
        output.append(f"  '{act.owner_role}'" if act.owner_role else "NULL",)
        output.append(f"  {act.due_days},")
        output.append(f"  '{act.due_date}'" if act.due_date else "NULL",)
        output.append(f"  '{act.created_at}'")
        output.append(");")

    # Write to file
    with open('backup_review_825ebd8f.sql', 'w') as f:
        f.write('\n'.join(output))

    print('Backup created: backup_review_825ebd8f.sql')
    print(f'Review: {review.solution_name}')
    print(f'Domain scores: {len(domain_scores)}')
    print(f'Findings: {len(findings)}')
    print(f'ADRs: {len(adrs)}')
    print(f'Actions: {len(actions)}')

if __name__ == '__main__':
    main()
