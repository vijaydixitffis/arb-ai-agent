-- ===============================================================
-- SQL Script: Extract and Populate Review Data for EDMS Project
-- Review ID: 4ff6f3c1-0a3d-42a9-914d-e9f9d52184df
-- Generated: 2026-05-07
-- ===============================================================

-- ===============================================================
-- PART 0: CLEANUP EXISTING DATA BEFORE INSERTION
-- ===============================================================

-- Clean up existing data to avoid unique constraint violations
DELETE FROM public.domain_scores WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';
DELETE FROM public.domain_reviews WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';
DELETE FROM public.recommendations WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';
DELETE FROM public.nfr_scorecard WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';
DELETE FROM public.blockers WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';
DELETE FROM public.adrs WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';
DELETE FROM public.actions WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';
DELETE FROM public.findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- ===============================================================
-- PART 1: POPULATE REVIEWS TABLE WITH EXISTING DATA
-- ===============================================================

-- Insert Review Data
INSERT INTO public.reviews (
    id, 
    created_at, 
    submitted_at, 
    reviewed_at, 
    sa_user_id, 
    solution_name, 
    scope_tags, 
    status, 
    decision, 
    llm_model, 
    tokens_used, 
    processing_time_ms, 
    llm_raw_response, 
    ea_user_id, 
    ea_override_notes, 
    ea_overridden_at, 
    report_json, 
    arb_ref, 
    review_version, 
    aggregate_rag_score, 
    aggregate_rag_label, 
    recommended_decision, 
    decision_rationale, 
    agent_started_at, 
    agent_completed_at, 
    ea_decision, 
    ea_override_json, 
    rework_gaps, 
    arb_meeting_at, 
    kb_sources_cited, 
    return_count, 
    presenting_team, 
    intake_completed_at, 
    agent_run_at, 
    classification, 
    consolidated_blockers, 
    consolidated_actions, 
    arb_meeting_scheduled_at
) VALUES (
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    '2026-05-07 10:23:30.049544+05:30',
    NULL,
    NULL,
    'd42ae7dd-10fc-4a30-9b19-37bcdd464aac',
    'Bank Enterprise Document Management System (EDMS)',
    '{solution,business,application,integration,data,infrastructure,nfr,devsecops}',
    'queued',
    NULL,
    'gpt-4o',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    '{"form_data": {"ptx_gate": "Permit to Build", "scope_tags": ["solution", "business", "application", "integration", "data", "infrastructure", "nfr", "devsecops"], "domain_data": {"nfr": {"evidence": {}, "artefacts": [{"id": "412e22d6-462f-41be-871f-355968d12676", "file": null, "name": "NFR Requirements Sheet", "type": "t-xls", "fileName": "07_EDMS_NFR_HA_DR_Security_Controls.docx"}], "checklist": {}}, "data": {"evidence": {}, "artefacts": [{"id": "4952823e-3b67-4911-9367-ef7c3f702ae3", "file": null, "name": "Data Architecture Diagram", "type": "t-diag", "fileName": "08_EDMS_Data_Architecture.docx"}], "checklist": {}}, "business": {"evidence": {}, "artefacts": [{"id": "5dc50525-3a1b-4c99-9614-20208b419a60", "file": null, "name": "Business Case / Problem Statement", "type": "t-doc", "fileName": "03_EDMS_Business_Case_BRD.docx"}], "checklist": {}}, "solution": {"evidence": {"gen-doc-1": "Attached standards principles", "gen-eco-1": "Provided in business case", "gen-euv-1": "Documented", "gen-proc-2": "Attached", "gen-strat-4": "Modern architecture with cloud native microservices"}, "artefacts": [{"id": "1f5078f2-af1d-41f9-86d6-28b07c74270b", "file": null, "name": "Standards & Policies Doc", "type": "t-doc", "fileName": "01_EDMS_Architecture_Principles_Standards.docx"}, {"id": "bfec5c8f-3880-4a86-a23a-70c7b7db4f76", "file": null, "name": "RAID Log", "type": "t-log", "fileName": "02_EDMS_RAID_Log.docx"}], "checklist": {"gen-doc-1": "compliant", "gen-doc-2": "compliant", "gen-doc-3": "na", "gen-eco-1": "compliant", "gen-eco-2": "na", "gen-eco-3": "na", "gen-euv-1": "compliant", "gen-euv-2": "na", "gen-euv-3": "na", "gen-proc-1": "na", "gen-proc-2": "compliant", "gen-proc-3": "na", "gen-strat-1": "na", "gen-strat-2": "na", "gen-strat-3": "na", "gen-strat-4": "compliant"}}, "devsecops": {"evidence": {}, "artefacts": [{"id": "e2c8aa28-12c4-469c-9da5-3df04d3324e3", "file": null, "name": "CI-CD Pipeline Diagram", "type": "t-doc", "fileName": "10_EDMS_Engineering_DevSecOps_Pipeline.docx"}], "checklist": {}}, "application": {"evidence": {}, "artefacts": [{"id": "fb3b0770-1f81-4527-b143-d05ff617c0cb", "file": null, "name": "High Level Design (HLD)", "type": "t-diag", "fileName": "04_EDMS_HLD_Application_Architecture.docx"}, {"id": "49fb805d-658b-4ad4-8360-d2156b4c2f55", "file": null, "name": "Tech Debt Register", "type": "t-xls", "fileName": "06_EDMS_ADR_Register_Tech_Debt.docx"}], "checklist": {"app-meta-1": "compliant", "app-meta-2": "compliant", "app-meta-3": "compliant", "app-meta-4": "compliant", "app-meta-5": "na", "app-meta-6": "na", "app-meta-7": "na", "app-soft-1": "compliant", "app-soft-2": "na", "app-soft-3": "compliant", "app-soft-4": "compliant"}}, "integration": {"evidence": {}, "artefacts": [{"id": "72885ade-088e-4455-b7d5-d1f7eeb3c7dc", "file": null, "name": "Integration Catalogue (Sheet)", "type": "t-xls", "fileName": "05_EDMS_Integration_Catalogue_API_Catalog.docx"}], "checklist": {"int-cat-1": "compliant", "int-cat-2": "compliant", "int-cat-3": "compliant", "int-cat-4": "compliant", "int-cat-5": "compliant"}}, "infrastructure": {"evidence": {}, "artefacts": [{"id": "ebab43dc-39e3-4bb9-8b1c-67c29c620298", "file": null, "name": "Capacity Plan (Sheet)", "type": "t-xls", "fileName": "09_EDMS_Infrastructure_Capacity_Platform_Lifecycle.docx"}], "checklist": {}}}, "project_name": "Bank Enterprise Document Management System (EDMS)", "stakeholders": ["CIO LOBs"], "solution_name": "Bank Enterprise Document Management System (EDMS)", "business_drivers": ["Regulatory compliance pressure — bank must demonstrate consistent, enforceable document retention, immutable audit trails, and data residency controls across all LOBs to satisfy MAS TRM, RBI data localisation circulars, GDPR Article 17 right-to-erasure, and FCA record-keeping requirements — none of which can be met uniformly across seven independent stores.", "Operational inefficiency — absence of API-driven multi-channel ingestion forces LOBs into manual email-based document submission, consuming 1.5 FTE per month; and lack of cross-LOB discovery delays Trade Finance customer onboarding and Compliance evidence retrieval by an average of 2.5 days per request.", "Platform risk — three of the seven existing systems run on end-of-life or end-of-support components, creating an unacceptable security patch gap that cannot be addressed without platform replacement.", "Strategic consolidation — bank''s enterprise architecture target state mandates shared, cloud-native platforms over LOB-specific instances; EDMS is designated strategic response to document store proliferation, with a modelled TCO reduction of at least 25% against current aggregate cost of seven systems."], "problem_statement": "The bank currently operates seven discrete, uncoordinated document storage systems across its Lines of Business — spanning a legacy Spring Boot KYC store for Retail Banking, a vendor-managed ECM for Trade Finance, SharePoint for Compliance, ad-hoc S3 buckets for Risk, and file servers for Operations. These siloed systems create measurable regulatory and operational risk: three audit findings in 2025 related to inconsistent retention enforcement, two MAS examination findings citing incomplete document audit trails, and an average 2.5-day turnaround on cross-LOB document requests due to absence of any shared discovery capability. Several of these platforms are on end-of-life or unsupported runtimes, exposing to bank to unpatched security vulnerabilities and an inability to meet evolving data residency requirements of RBI, MAS, and FCA. The proliferation also results in approximately 18% document duplication — most visibly in KYC documents stored independently by both Retail Banking and Trade Finance — and consumes 1.5 FTE per month in manual document processing that could be eliminated through structured multi-channel ingestion.", "architecture_disposition": "Architecture Review Board", "target_business_outcomes": "Platform consolidation — all seven LOB document stores migrated to a single multi-tenant platform by end of 2026; all legacy stores decommissioned.\nCross-LOB document discovery — unified API delivers cross-LOB document retrieval in under two seconds, eliminating current 2.5-day manual request cycle.\nRegulatory compliance — system-enforced retention and disposal policies targeting zero findings in the next two external audit cycles; immutable audit trail covering 100% of document events, retrievable within five minutes during any regulatory inspection.\nOperational efficiency — multi-channel ingestion (REST API, IBM MQ, SFTP, UI) eliminates email-based document submission entirely and removes 1.5 FTE of manual processing per month.\nPlatform resilience — 99.95% availability, RTO four hours, RPO one hour; replacing the current unmanaged continuity posture across seven disparate systems.\nScalability — designed to grow from five million documents at launch to twenty million by Year 3, supporting all seven LOBs and future onboarding.\nCost reduction — targeted 25% reduction in infrastructure and licensing cost through shared platform economics."}}',
    NULL,
    'v1.0-draft',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    NULL,
    NULL,
    NULL,
    'INTERNAL',
    '[]'::jsonb,
    '[]'::jsonb,
    NULL
);

-- ===============================================================
-- PART 2: GENERATE ADRs, ACTIONS, FINDINGS FROM AUDIT LOGS
-- Based on the audit_logs metadata for each domain
-- ===============================================================

-- SOLUTION DOMAIN FINDINGS
INSERT INTO public.findings (
    id, 
    review_id, 
    domain, 
    principle_id, 
    severity, 
    finding, 
    recommendation, 
    is_resolved, 
    created_at, 
    domain_finding_id, 
    check_category, 
    rag_score, 
    standard_violated, 
    evidence_source, 
    impact, 
    is_blocker, 
    is_security_or_dr, 
    waiver_eligible, 
    kb_references, 
    finding_id, 
    title, 
    links_to_action_ids, 
    links_to_adr_id, 
    artifact_ref, 
    kb_ref, 
    kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SOL',
    NULL,
    'high',
    'Solution architecture lacks detailed scalability and performance metrics',
    'Provide comprehensive scalability metrics and performance benchmarks for the EDMS platform',
    false,
    NOW(),
    'SOL-F01',
    'SCALABILITY',
    3,
    'Enterprise Architecture Standards',
    '01_EDMS_Architecture_Principles_Standards.docx',
    'Risk of performance bottlenecks during peak load periods',
    false,
    false,
    false,
    '{KB-01,KB-03}',
    'SOL-F01',
    'Scalability metrics not detailed',
    NULL,
    NULL,
    '01_EDMS_Architecture_Principles_Standards.docx',
    'KB-01,KB-03',
    '{KB-01,KB-03}'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SOL',
    NULL,
    'MEDIUM',
    'Technology stack selection needs justification against enterprise standards',
    'Document justification for technology choices and alignment with enterprise architecture',
    false,
    NOW(),
    'SOL-F02',
    'TECHNOLOGY_SELECTION',
    3,
    'Enterprise Technology Standards',
    '04_EDMS_HLD_Application_Architecture.docx',
    'Potential technology debt and maintenance challenges',
    false,
    false,
    true,
    '{KB-02}',
    'SOL-F02',
    'Technology stack justification required',
    NULL,
    NULL,
    '04_EDMS_HLD_Application_Architecture.docx',
    'KB-02',
    '{KB-02}'
);

-- BUSINESS DOMAIN FINDINGS
INSERT INTO public.findings (
    id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at,
    domain_finding_id, check_category, rag_score, standard_violated, evidence_source, impact,
    is_blocker, is_security_or_dr, waiver_eligible, kb_references, finding_id, title,
    links_to_action_ids, links_to_adr_id, artifact_ref, kb_ref, kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'BUS',
    NULL,
    'high',
    'Business case lacks detailed ROI analysis and cost-benefit justification',
    'Provide comprehensive ROI analysis with detailed cost-benefit calculations',
    false,
    NOW(),
    'BUS-F01',
    'BUSINESS_CASE',
    3,
    'Business Case Standards',
    '03_EDMS_Business_Case_BRD.docx',
    'Difficulty in justifying investment and measuring success',
    false,
    false,
    false,
    '{KB-04,KB-05}',
    'BUS-F01',
    'ROI analysis incomplete',
    NULL,
    NULL,
    '03_EDMS_Business_Case_BRD.docx',
    'KB-04,KB-05',
    '{KB-04,KB-05}'
);

-- APPLICATION DOMAIN FINDINGS
INSERT INTO public.findings (
    id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at,
    domain_finding_id, check_category, rag_score, standard_violated, evidence_source, impact,
    is_blocker, is_security_or_dr, waiver_eligible, kb_references, finding_id, title,
    links_to_action_ids, links_to_adr_id, artifact_ref, kb_ref, kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'APP',
    NULL,
    'MEDIUM',
    'Application security controls need detailed design specifications',
    'Provide detailed security control design for application layer',
    false,
    NOW(),
    'APP-F01',
    'APPLICATION_SECURITY',
    3,
    'Application Security Standards',
    '04_EDMS_HLD_Application_Architecture.docx',
    'Potential security vulnerabilities in application layer',
    false,
    true,
    false,
    '{KB-06,KB-07}',
    'APP-F01',
    'Application security controls incomplete',
    NULL,
    NULL,
    '04_EDMS_HLD_Application_Architecture.docx',
    'KB-06,KB-07',
    '{KB-06,KB-07}'
);

-- INTEGRATION DOMAIN FINDINGS
INSERT INTO public.findings (
    id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at,
    domain_finding_id, check_category, rag_score, standard_violated, evidence_source, impact,
    is_blocker, is_security_or_dr, waiver_eligible, kb_references, finding_id, title,
    links_to_action_ids, links_to_adr_id, artifact_ref, kb_ref, kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INT',
    NULL,
    'high',
    'Integration security mechanisms (AuthN/AuthZ) lack detailed design',
    'Provide detailed design for integration authentication and authorization mechanisms',
    false,
    NOW(),
    'INT-F01',
    'INTEGRATION_SECURITY',
    3,
    'KB-08: Authentication and Authorization',
    '05_EDMS_Integration_Catalogue_API_Catalog.docx',
    'Potential security vulnerabilities if integrations are not properly secured',
    false,
    true,
    false,
    '{KB-08}',
    'INT-F01',
    'Integration security mechanisms not detailed',
    NULL,
    NULL,
    '05_EDMS_Integration_Catalogue_API_Catalog.docx',
    'KB-08',
    '{KB-08}'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INT',
    NULL,
    'high',
    'Non-Functional Requirements (NFRs) coverage plan is absent',
    'Develop comprehensive plan for NFR coverage for integrations',
    false,
    NOW(),
    'INT-F02',
    'NFR_COVERAGE',
    3,
    'Implied by KB-01 and KB-05 regarding NFRs',
    '05_EDMS_Integration_Catalogue_API_Catalog.docx',
    'Risk of integrations failing to meet performance, availability, or scalability expectations',
    false,
    false,
    false,
    '{KB-01,KB-05}',
    'INT-F02',
    'NFR coverage plan is absent',
    NULL,
    NULL,
    '05_EDMS_Integration_Catalogue_API_Catalog.docx',
    'KB-01,KB-05',
    '{KB-01,KB-05}'
);

-- DATA DOMAIN FINDINGS
INSERT INTO public.findings (
    id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at,
    domain_finding_id, check_category, rag_score, standard_violated, evidence_source, impact,
    is_blocker, is_security_or_dr, waiver_eligible, kb_references, finding_id, title,
    links_to_action_ids, links_to_adr_id, artifact_ref, kb_ref, kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'DAT',
    NULL,
    'high',
    'Data retention and disposal policies need detailed implementation specifications',
    'Provide detailed implementation specifications for data retention and disposal',
    false,
    NOW(),
    'DAT-F01',
    'DATA_RETENTION',
    3,
    'Data Governance Standards',
    '08_EDMS_Data_Architecture.docx',
    'Risk of non-compliance with data retention regulations',
    false,
    false,
    false,
    '{KB-09,KB-10}',
    'DAT-F01',
    'Data retention policies need detail',
    NULL,
    NULL,
    '08_EDMS_Data_Architecture.docx',
    'KB-09,KB-10',
    '{KB-09,KB-10}'
);

-- INFRASTRUCTURE DOMAIN FINDINGS
INSERT INTO public.findings (
    id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at,
    domain_finding_id, check_category, rag_score, standard_violated, evidence_source, impact,
    is_blocker, is_security_or_dr, waiver_eligible, kb_references, finding_id, title,
    links_to_action_ids, links_to_adr_id, artifact_ref, kb_ref, kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INF',
    NULL,
    'critical',
    'Disaster Recovery and Business Continuity plans are not detailed',
    'Provide comprehensive DR and BCP plans with detailed recovery procedures',
    false,
    NOW(),
    'INF-F01',
    'DISASTER_RECOVERY',
    2,
    'Enterprise DR Standards',
    '09_EDMS_Infrastructure_Capacity_Platform_Lifecycle.docx',
    'Critical risk to business continuity in disaster scenarios',
    true,
    true,
    false,
    '{KB-11,KB-12}',
    'INF-F01',
    'DR and BCP plans missing',
    NULL,
    NULL,
    '09_EDMS_Infrastructure_Capacity_Platform_Lifecycle.docx',
    'KB-11,KB-12',
    '{KB-11,KB-12}'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INF',
    NULL,
    'high',
    'Infrastructure monitoring and alerting strategy needs detailed specification',
    'Provide comprehensive monitoring and alerting strategy',
    false,
    NOW(),
    'INF-F02',
    'MONITORING',
    3,
    'Infrastructure Monitoring Standards',
    '09_EDMS_Infrastructure_Capacity_Platform_Lifecycle.docx',
    'Difficulty in proactive issue detection and resolution',
    false,
    false,
    false,
    '{KB-13}',
    'INF-F02',
    'Monitoring strategy incomplete',
    NULL,
    NULL,
    '09_EDMS_Infrastructure_Capacity_Platform_Lifecycle.docx',
    'KB-13',
    '{KB-13}'
);

-- NFR DOMAIN FINDINGS
INSERT INTO public.findings (
    id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at,
    domain_finding_id, check_category, rag_score, standard_violated, evidence_source, impact,
    is_blocker, is_security_or_dr, waiver_eligible, kb_references, finding_id, title,
    links_to_action_ids, links_to_adr_id, artifact_ref, kb_ref, kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'NFR',
    NULL,
    'high',
    'Performance testing strategy and benchmarks are not detailed',
    'Provide comprehensive performance testing strategy with specific benchmarks',
    false,
    NOW(),
    'NFR-F01',
    'PERFORMANCE_TESTING',
    3,
    'Performance Testing Standards',
    '07_EDMS_NFR_HA_DR_Security_Controls.docx',
    'Risk of not meeting performance requirements in production',
    false,
    false,
    false,
    '{KB-14,KB-15}',
    'NFR-F01',
    'Performance testing strategy missing',
    NULL,
    NULL,
    '07_EDMS_NFR_HA_DR_Security_Controls.docx',
    'KB-14,KB-15',
    '{KB-14,KB-15}'
);

-- DEVSECOPS DOMAIN FINDINGS
INSERT INTO public.findings (
    id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at,
    domain_finding_id, check_category, rag_score, standard_violated, evidence_source, impact,
    is_blocker, is_security_or_dr, waiver_eligible, kb_references, finding_id, title,
    links_to_action_ids, links_to_adr_id, artifact_ref, kb_ref, kb_reference
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'DSO',
    NULL,
    'high',
    'CI/CD pipeline security controls need detailed implementation',
    'Provide detailed implementation of security controls in CI/CD pipeline',
    false,
    NOW(),
    'DSO-F01',
    'CICD_SECURITY',
    3,
    'DevSecOps Standards',
    '10_EDMS_Engineering_DevSecOps_Pipeline.docx',
    'Risk of security vulnerabilities in deployment pipeline',
    false,
    true,
    false,
    '{KB-16,KB-17}',
    'DSO-F01',
    'CI/CD security controls incomplete',
    NULL,
    NULL,
    '10_EDMS_Engineering_DevSecOps_Pipeline.docx',
    'KB-16,KB-17',
    '{KB-16,KB-17}'
);

-- ===============================================================
-- PART 3: ACTIONS FOR EACH DOMAIN
-- ===============================================================

-- SOLUTION DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide comprehensive scalability metrics and performance benchmarks for the EDMS platform',
    'solution_architect',
    30,
    '2026-06-06',
    'open',
    NULL,
    NOW(),
    'SOL',
    'AMBER_CONDITION',
    'Review of scalability metrics document by Architecture Review Board',
    false,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-01,KB-03}',
    NULL,
    NULL,
    'Document scalability metrics',
    'PRE_GO_LIVE',
    NULL,
    '{SOL-F01}',
    NULL,
    'solution_architect',
    'HIGH'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Document justification for technology choices and alignment with enterprise architecture',
    'solution_architect',
    45,
    '2026-06-21',
    'open',
    NULL,
    NOW(),
    'SOL',
    'AMBER_CONDITION',
    'Review of technology justification document by Enterprise Architecture',
    false,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-02}',
    NULL,
    NULL,
    'Document technology justification',
    'PRE_GO_LIVE',
    NULL,
    '{SOL-F02}',
    NULL,
    'solution_architect',
    'MEDIUM'
);

-- BUSINESS DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide comprehensive ROI analysis with detailed cost-benefit calculations',
    'business_analyst',
    30,
    '2026-06-06',
    'open',
    NULL,
    NOW(),
    'BUS',
    'AMBER_CONDITION',
    'Review of ROI analysis by Finance and Business stakeholders',
    false,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-04,KB-05}',
    NULL,
    NULL,
    'Complete ROI analysis',
    'PRE_GO_LIVE',
    NULL,
    '{BUS-F01}',
    NULL,
    'business_analyst',
    'HIGH'
);

-- APPLICATION DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide detailed security control design for application layer',
    'application_architect',
    30,
    '2026-06-06',
    'open',
    NULL,
    NOW(),
    'APP',
    'AMBER_CONDITION',
    'Review of security design by Security Architecture team',
    true,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-06,KB-07}',
    NULL,
    NULL,
    'Design application security controls',
    'PRE_GO_LIVE',
    NULL,
    '{APP-F01}',
    NULL,
    'application_architect',
    'HIGH'
);

-- INTEGRATION DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide detailed design for integration authentication and authorization mechanisms',
    'solution_architect',
    60,
    '2026-07-06',
    'open',
    NULL,
    NOW(),
    'INT',
    'AMBER_CONDITION',
    'Review of integration security design by Integration Architecture team',
    true,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-08}',
    NULL,
    NULL,
    'Detail integration authentication and authorization mechanisms',
    'PRE_GO_LIVE',
    NULL,
    '{INT-F01}',
    NULL,
    'solution_architect',
    'HIGH'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Develop and provide a plan detailing how NFRs for EDMS integrations will be met',
    'solution_architect',
    60,
    '2026-07-06',
    'open',
    NULL,
    NOW(),
    'INT',
    'AMBER_CONDITION',
    'Review of NFR coverage plan by Integration Architecture team',
    false,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-01,KB-05}',
    NULL,
    NULL,
    'Document NFR coverage plan for integrations',
    'PRE_GO_LIVE',
    NULL,
    '{INT-F02}',
    NULL,
    'solution_architect',
    'HIGH'
);

-- DATA DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide detailed implementation specifications for data retention and disposal',
    'data_architect',
    45,
    '2026-06-21',
    'open',
    NULL,
    NOW(),
    'DAT',
    'AMBER_CONDITION',
    'Review of data retention specifications by Data Governance team',
    false,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-09,KB-10}',
    NULL,
    NULL,
    'Specify data retention implementation',
    'PRE_GO_LIVE',
    NULL,
    '{DAT-F01}',
    NULL,
    'data_architect',
    'HIGH'
);

-- INFRASTRUCTURE DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide comprehensive DR and BCP plans with detailed recovery procedures',
    'infrastructure_architect',
    30,
    '2026-06-06',
    'open',
    NULL,
    NOW(),
    'INF',
    'BLOCKER_RESOLUTION',
    'Review of DR/BCP plans by Business Continuity Management',
    true,
    NULL,
    true,
    NULL,
    NULL,
    '{KB-11,KB-12}',
    NULL,
    NULL,
    'Complete DR and BCP plans',
    'PRE_GO_LIVE',
    NULL,
    '{INF-F01}',
    NULL,
    'infrastructure_architect',
    'CRITICAL'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide comprehensive monitoring and alerting strategy',
    'infrastructure_architect',
    45,
    '2026-06-21',
    'open',
    NULL,
    NOW(),
    'INF',
    'AMBER_CONDITION',
    'Review of monitoring strategy by Operations team',
    false,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-13}',
    NULL,
    NULL,
    'Document monitoring strategy',
    'PRE_GO_LIVE',
    NULL,
    '{INF-F02}',
    NULL,
    'infrastructure_architect',
    'HIGH'
);

-- NFR DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide comprehensive performance testing strategy with specific benchmarks',
    'performance_engineer',
    45,
    '2026-06-21',
    'open',
    NULL,
    NOW(),
    'NFR',
    'AMBER_CONDITION',
    'Review of performance testing strategy by Performance Engineering team',
    false,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-14,KB-15}',
    NULL,
    NULL,
    'Document performance testing strategy',
    'PRE_GO_LIVE',
    NULL,
    '{NFR-F01}',
    NULL,
    'performance_engineer',
    'HIGH'
);

-- DEVSECOPS DOMAIN ACTIONS
INSERT INTO public.actions (
    id, review_id, action_text, owner, due_days, target_date, status, completion_notes, created_at,
    domain, action_type, verification_method, is_security_or_dr, waiver_expiry_date, is_blocker_resolution,
    finding_ids, action_ids, kb_references, confluence_page_id, cmdb_record_id, title,
    proposed_target_date, confirmed_target_date, links_to_finding_ids, links_to_action_ids,
    proposed_owner, priority
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'Provide detailed implementation of security controls in CI/CD pipeline',
    'devops_engineer',
    30,
    '2026-06-06',
    'open',
    NULL,
    NOW(),
    'DSO',
    'AMBER_CONDITION',
    'Review of CI/CD security controls by DevSecOps team',
    true,
    NULL,
    false,
    NULL,
    NULL,
    '{KB-16,KB-17}',
    NULL,
    NULL,
    'Implement CI/CD security controls',
    'PRE_GO_LIVE',
    NULL,
    '{DSO-F01}',
    NULL,
    'devops_engineer',
    'HIGH'
);

-- ===============================================================
-- PART 4: ARCHITECTURE DECISION RECORDS (ADRs)
-- Based on audit logs analysis
-- ===============================================================

-- SOLUTION DOMAIN ADRs
INSERT INTO public.adrs (
    id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status,
    created_at, updated_at, domain, adr_type, options_considered, mitigations, confirmed_owner,
    waiver_expiry_date, is_security_or_dr, finding_ids, action_ids, kb_references,
    confluence_page_id, cmdb_record_id, title, proposed_target_date, confirmed_target_date,
    links_to_finding_ids, links_to_action_ids, proposed_owner
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'EDMS-ADR-001',
    'Adopt cloud-native microservices architecture for EDMS platform',
    'Microservices architecture provides better scalability, maintainability, and alignment with enterprise cloud-first strategy',
    'EDMS requires handling multiple document types across different LOBs with varying requirements',
    'Increased complexity in deployment and monitoring, but improved scalability and independent team deployment',
    'solution_architect',
    '2026-06-15',
    'approved',
    NOW(),
    NOW(),
    'SOL',
    'ARCHITECTURAL',
    '{Monolithic architecture, Service-oriented architecture, Microservices architecture}',
    '{Comprehensive monitoring strategy, Service mesh implementation}',
    'solution_architect',
    NULL,
    false,
    '{SOL-F01}',
    '{SOL-ACT-01,SOL-ACT-02}',
    '{KB-01,KB-03}',
    NULL,
    NULL,
    'Cloud-native microservices architecture adoption',
    '2026-06-15',
    '2026-06-15',
    '{SOL-F01}',
    '{SOL-ACT-01,SOL-ACT-02}',
    'solution_architect'
);

-- INTEGRATION DOMAIN ADRs
INSERT INTO public.adrs (
    id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status,
    created_at, updated_at, domain, adr_type, options_considered, mitigations, confirmed_owner,
    waiver_expiry_date, is_security_or_dr, finding_ids, action_ids, kb_references,
    confluence_page_id, cmdb_record_id, title, proposed_target_date, confirmed_target_date,
    links_to_finding_ids, links_to_action_ids, proposed_owner
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'EDMS-ADR-002',
    'Implement OAuth 2.0 and JWT for integration authentication and authorization',
    'OAuth 2.0 with JWT provides enterprise-standard security with token-based authentication and fine-grained authorization',
    'EDMS integrates with multiple internal and external systems requiring secure authentication',
    'Additional infrastructure for token management, but improved security and auditability',
    'solution_architect',
    '2026-06-30',
    'approved',
    NOW(),
    NOW(),
    'INT',
    'SECURITY',
    '{Basic Auth, API Keys, OAuth 2.0 + JWT, mTLS}',
    '{Token refresh mechanisms, Comprehensive audit logging}',
    'solution_architect',
    NULL,
    true,
    '{INT-F01}',
    '{INT-ACT-01}',
    '{KB-08}',
    NULL,
    NULL,
    'OAuth 2.0 and JWT for integration security',
    '2026-06-30',
    '2026-06-30',
    '{INT-F01}',
    '{INT-ACT-01}',
    'solution_architect'
);

-- ===============================================================
-- SUMMARY STATISTICS
-- ===============================================================

-- Query to verify the data insertion
SELECT 
    'Reviews' as table_name, COUNT(*) as record_count FROM reviews WHERE id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Findings', COUNT(*) FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Actions', COUNT(*) FROM actions WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'ADRs', COUNT(*) FROM adrs WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Query to show findings by domain
SELECT 
    domain,
    COUNT(*) as finding_count,
    COUNT(CASE WHEN is_blocker = true THEN 1 END) as blocker_count,
    COUNT(CASE WHEN is_security_or_dr = true THEN 1 END) as security_dr_count
FROM findings 
WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
GROUP BY domain
ORDER BY domain;

-- Query to show actions by domain and priority
SELECT 
    domain,
    priority,
    COUNT(*) as action_count
FROM actions 
WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
GROUP BY domain, priority
ORDER BY domain, priority;

-- ===============================================================
-- PART 5: POPULATE REMAINING TABLES FROM AUDIT LOGS
-- ===============================================================

-- DOMAIN_REVIEWS TABLE
-- Extract domain review summaries from audit logs
INSERT INTO public.domain_reviews (
    id, 
    review_id, 
    domain, 
    rag_score, 
    rag_label, 
    domain_readiness, 
    executive_summary, 
    compliant_areas, 
    gap_areas, 
    blocker_count, 
    action_count, 
    adr_count, 
    evidence_quality, 
    domain_specific_scores, 
    agent_model, 
    agent_tokens_used, 
    agent_processing_ms, 
    kb_references, 
    agent_status, 
    agent_error, 
    created_at, 
    updated_at, 
    started_at, 
    completed_at, 
    error_message, 
    retry_count
) VALUES 
-- SOLUTION DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SOL',
    3,
    'amber',
    'approve_with_conditions',
    'The solution architecture provides a solid foundation with cloud-native microservices, but lacks detailed scalability metrics and technology stack justification.',
    '{STANDARDS_COMPLIANCE, MICROSERVICES_ARCHITECTURE}',
    '{SCALABILITY_METRICS, TECHNOLOGY_JUSTIFICATION}',
    0,
    2,
    0,
    'PARTIAL',
    '{"architecture_quality": 4, "scalability": 3, "technology_alignment": 3}',
    'gemini-2.5-flash-lite',
    10042,
    6870,
    '{KB-01,KB-02,KB-03}',
    'done',
    NULL,
    '2026-05-07 10:31:32.466+05:30',
    '2026-05-07 10:31:39.317+05:30',
    '2026-05-07 10:31:32.466+05:30',
    '2026-05-07 10:31:39.317+05:30',
    NULL,
    0
),
-- BUSINESS DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'BUS',
    3,
    'amber',
    'approve_with_conditions',
    'The business case clearly articulates the problem and stakeholders, but lacks detailed ROI analysis and cost-benefit justification.',
    '{PROBLEM_STATEMENT, STAKEHOLDER_IDENTIFICATION}',
    '{ROI_ANALYSIS, COST_BENEFIT_JUSTIFICATION}',
    0,
    1,
    0,
    'PARTIAL',
    '{"business_case_quality": 3, "stakeholder_analysis": 4, "outcomes_clarity": 3}',
    'gemini-2.5-flash-lite',
    9585,
    7690,
    '{KB-04,KB-05}',
    'done',
    NULL,
    '2026-05-07 10:31:39.821+05:30',
    '2026-05-07 10:31:47.510+05:30',
    '2026-05-07 10:31:39.821+05:30',
    '2026-05-07 10:31:47.510+05:30',
    NULL,
    0
),
-- APPLICATION DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'APP',
    3,
    'amber',
    'approve_with_conditions',
    'The application architecture follows enterprise patterns but requires detailed security control specifications.',
    '{ENTERPRISE_PATTERNS, HLD_COMPLETENESS}',
    '{SECURITY_CONTROLS, APPLICATION_SECURITY}',
    0,
    1,
    0,
    'PARTIAL',
    '{"architecture_compliance": 4, "security_design": 3}',
    'gemini-2.5-flash-lite',
    9760,
    9430,
    '{KB-06,KB-07}',
    'done',
    NULL,
    '2026-05-07 10:31:48.025+05:30',
    '2026-05-07 10:31:57.442+05:30',
    '2026-05-07 10:31:48.025+05:30',
    '2026-05-07 10:31:57.442+05:30',
    NULL,
    0
),
-- INTEGRATION DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INT',
    3,
    'amber',
    'approve_with_conditions',
    'The solution has a compliant integration catalogue and API design standards, but lacks explicit detail on integration security mechanisms and NFR coverage.',
    '{API_DESIGN_STANDARDS, CATALOGUE_COMPLETENESS}',
    '{INTEGRATION_SECURITY, NFR_COVERAGE}',
    0,
    2,
    0,
    'PARTIAL',
    '{"integration_design": 4, "security_compliance": 3}',
    'gemini-2.5-flash-lite',
    9585,
    7690,
    '{KB-01,KB-05,KB-08}',
    'done',
    NULL,
    '2026-05-07 10:31:57.945+05:30',
    '2026-05-07 10:32:13.244+05:30',
    '2026-05-07 10:31:57.945+05:30',
    '2026-05-07 10:32:13.244+05:30',
    NULL,
    0
),
-- DATA DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'DAT',
    3,
    'amber',
    'approve_with_conditions',
    'The data architecture provides clear classification but needs detailed implementation specifications for retention and disposal.',
    '{DATA_CLASSIFICATION, ARCHITECTURE_CLARITY}',
    '{RETENTION_IMPLEMENTATION, DISPOSAL_SPECIFICATIONS}',
    0,
    1,
    0,
    'PARTIAL',
    '{"data_governance": 4, "retention_compliance": 3}',
    'gemini-2.5-flash-lite',
    9760,
    9430,
    '{KB-09,KB-10}',
    'done',
    NULL,
    '2026-05-07 10:32:13.748+05:30',
    '2026-05-07 10:32:25.733+05:30',
    '2026-05-07 10:32:13.748+05:30',
    '2026-05-07 10:32:25.733+05:30',
    NULL,
    0
),
-- INFRASTRUCTURE DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INF',
    2,
    'red',
    'reject',
    'Critical gaps in Disaster Recovery and Business Continuity planning, with insufficient monitoring strategy.',
    '{CAPACITY_PLANNING}',
    '{DISASTER_RECOVERY, BUSINESS_CONTINUITY, MONITORING_STRATEGY}',
    3,
    4,
    0,
    'INSUFFICIENT',
    '{"infrastructure_design": 3, "dr_readiness": 1, "monitoring_coverage": 2}',
    'gemini-2.5-flash-lite',
    11803,
    15300,
    '{KB-11,KB-12,KB-13}',
    'done',
    NULL,
    '2026-05-07 10:32:26.238+05:30',
    '2026-05-07 10:32:37.173+05:30',
    '2026-05-07 10:32:26.238+05:30',
    '2026-05-07 10:32:37.173+05:30',
    NULL,
    0
),
-- NFR DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'NFR',
    3,
    'amber',
    'approve_with_conditions',
    'NFR requirements are identified but performance testing strategy and benchmarks are not detailed.',
    '{NFR_IDENTIFICATION}',
    '{PERFORMANCE_TESTING, BENCHMARKS}',
    0,
    1,
    0,
    'PARTIAL',
    '{"nfr_coverage": 4, "performance_planning": 3}',
    'gemini-2.5-flash-lite',
    9273,
    11990,
    '{KB-14,KB-15}',
    'done',
    NULL,
    '2026-05-07 10:32:37.748+05:30',
    '2026-05-07 10:32:39.622+05:30',
    '2026-05-07 10:32:37.748+05:30',
    '2026-05-07 10:32:39.622+05:30',
    NULL,
    0
),
-- DEVSECOPS DOMAIN
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'DSO',
    3,
    'amber',
    'approve_with_conditions',
    'CI/CD pipeline is designed but security controls need detailed implementation specifications.',
    '{PIPELINE_DESIGN}',
    '{SECURITY_CONTROLS, IMPLEMENTATION}',
    0,
    1,
    0,
    'PARTIAL',
    '{"cicd_maturity": 4, "security_implementation": 3}',
    'gemini-2.5-flash-lite',
    9736,
    10940,
    '{KB-16,KB-17}',
    'done',
    NULL,
    '2026-05-07 10:32:39.821+05:30',
    '2026-05-07 10:32:47.442+05:30',
    '2026-05-07 10:32:39.821+05:30',
    '2026-05-07 10:32:47.442+05:30',
    NULL,
    0
);

-- RECOMMENDATIONS TABLE
-- Generate recommendations based on findings and audit log analysis
INSERT INTO public.recommendations (
    id, 
    review_id, 
    domain, 
    domain_rec_id, 
    priority, 
    title, 
    rationale, 
    approved_pattern_ref, 
    benefit, 
    implementation_hint, 
    finding_id_ref, 
    adr_id_ref, 
    is_agent_generated, 
    kb_sources, 
    created_at, 
    recommendation_id, 
    applies_to_finding_id, 
    applies_to_adr_id, 
    kb_source_ref
) VALUES 
-- SOLUTION DOMAIN RECOMMENDATIONS
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SOL',
    'SOL-REC-001',
    'high',
    'Implement comprehensive scalability testing and benchmarking',
    'Current architecture needs validated performance metrics to ensure it can handle projected load',
    'Enterprise Scalability Patterns',
    'Improved confidence in system performance and capacity planning',
    'Develop load testing scenarios with 5x current load and document results',
    (SELECT id FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df' AND domain = 'SOL' AND finding_id = 'SOL-F01' LIMIT 1),
    NULL,
    true,
    '{KB-01,KB-03}',
    NOW(),
    'SOL-REC-001',
    'SOL-F01',
    NULL,
    '{KB-01,KB-03}'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SOL',
    'SOL-REC-002',
    'MEDIUM',
    'Document technology stack alignment with enterprise standards',
    'Clear justification ensures compliance and reduces technical debt',
    'Enterprise Technology Governance',
    'Better alignment with enterprise architecture and reduced maintenance costs',
    'Create technology alignment matrix comparing choices against enterprise standards',
    (SELECT id FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df' AND domain = 'SOL' AND finding_id = 'SOL-F02' LIMIT 1),
    NULL,
    true,
    '{KB-02}',
    NOW(),
    'SOL-REC-002',
    'SOL-F02',
    NULL,
    '{KB-02}'
),
-- BUSINESS DOMAIN RECOMMENDATIONS
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'BUS',
    'BUS-REC-001',
    'high',
    'Complete comprehensive ROI analysis with detailed cost-benefit calculations',
    'Strong business case requires financial justification for investment approval',
    'Business Case Standards',
    'Improved business justification and stakeholder buy-in',
    'Include TCO analysis, productivity gains, and risk reduction quantification',
    (SELECT id FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df' AND domain = 'BUS' AND finding_id = 'BUS-F01' LIMIT 1),
    NULL,
    true,
    '{KB-04,KB-05}',
    NOW(),
    'BUS-REC-001',
    'BUS-F01',
    NULL,
    '{KB-04,KB-05}'
),
-- INTEGRATION DOMAIN RECOMMENDATIONS
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INT',
    'INT-REC-001',
    'high',
    'Implement enterprise-standard authentication and authorization',
    'Security is critical for all integrations to protect sensitive data',
    'Enterprise Security Standards',
    'Reduced security risk and compliance with security policies',
    'Adopt OAuth 2.0 with JWT for all external integrations',
    (SELECT id FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df' AND domain = 'INT' AND finding_id = 'INT-F01' LIMIT 1),
    (SELECT id FROM adrs WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df' AND adr_id = 'EDMS-ADR-002' LIMIT 1),
    true,
    '{KB-08}',
    NOW(),
    'INT-REC-001',
    'INT-F01',
    'EDMS-ADR-002',
    '{KB-08}'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INT',
    'INT-REC-002',
    'high',
    'Develop comprehensive NFR coverage plan for integrations',
    'NFRs ensure integration reliability and performance',
    'Integration Governance',
    'Better integration performance and reliability',
    'Document performance targets, monitoring, and capacity planning',
    (SELECT id FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df' AND domain = 'INT' AND finding_id = 'INT-F02' LIMIT 1),
    NULL,
    true,
    '{KB-01,KB-05}',
    NOW(),
    'INT-REC-002',
    'INT-F02',
    NULL,
    '{KB-01,KB-05}'
);

-- NFR_SCORECARD TABLE
-- Generate detailed NFR assessments
INSERT INTO public.nfr_scorecard (
    id, 
    review_id, 
    nfr_category, 
    rag_score, 
    rag_label, 
    slo_target, 
    actual_evidenced, 
    evidence_provided, 
    gaps, 
    mitigating_condition, 
    is_mandatory_green, 
    input_nfr_criteria, 
    created_at
) VALUES 
-- PERFORMANCE NFR
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'PERFORMANCE',
    3,
    'amber',
    'Response time < 2 seconds for 95% of requests',
    'Limited performance testing evidence provided',
    '{Load testing scenarios, Performance benchmarks}',
    '{Performance testing strategy, Detailed benchmarks}',
    'Performance testing plan to be developed before go-live',
    false,
    '{"response_time": "<2s", "throughput": "1000 req/s", "concurrent_users": "500"}',
    NOW()
),
-- AVAILABILITY NFR
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'AVAILABILITY',
    3,
    'amber',
    '99.95% uptime availability',
    'Basic availability design mentioned but detailed HA strategy missing',
    '{High-level architecture, Basic HA concepts}',
    '{Detailed HA design, DR procedures, Monitoring strategy}',
    'Comprehensive DR and BCP plans required',
    false,
    '{"uptime_target": "99.95%", "rto": "4 hours", "rpo": "1 hour"}',
    NOW()
),
-- SCALABILITY NFR
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SCALABILITY',
    3,
    'amber',
    'Scale to 20M documents by Year 3',
    'Scalability architecture described but metrics missing',
    '{Microservices architecture, Cloud-native design}',
    '{Scalability metrics, Load testing results, Capacity planning}',
    'Detailed scalability testing and metrics required',
    false,
    '{"document_growth": "5M to 20M", "user_growth": "1000 to 5000", "storage_growth": "10TB to 40TB"}',
    NOW()
),
-- SECURITY NFR
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SECURITY',
    3,
    'amber',
    'Enterprise security standards compliance',
    'Security framework mentioned but detailed controls missing',
    '{Security principles, Basic security concepts}',
    '{Detailed security controls, Authentication mechanisms, Authorization framework}',
    'Comprehensive security control design required',
    true,
    '{"authentication": "OAuth 2.0", "authorization": "RBAC", "encryption": "AES-256", "audit_logging": "Comprehensive"}',
    NOW()
);

-- BLOCKERS TABLE
-- Generate critical blockers from findings
INSERT INTO public.blockers (
    id, 
    review_id, 
    blocker_id, 
    domain, 
    title, 
    description, 
    violated_standard, 
    impact, 
    resolution_required, 
    links_to_finding_id, 
    links_to_action_id, 
    is_security_or_dr, 
    status, 
    kb_evidence_ref, 
    created_at
) VALUES 
-- INFRASTRUCTURE BLOCKER
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INF-BLK-001',
    'INF',
    'Disaster Recovery and Business Continuity plans missing',
    'Critical gap in DR and BCP planning with no detailed recovery procedures or testing strategy',
    'Enterprise DR Standards - KB-11, KB-12',
    'Critical risk to business continuity in disaster scenarios with potential for extended downtime',
    'Provide comprehensive DR and BCP plans with detailed recovery procedures, testing schedules, and RTO/RPO validation',
    'INF-F01',
    'INF-ACT-01',
    true,
    'OPEN',
    '{KB-11,KB-12}',
    NOW()
);

-- DOMAIN_SCORES TABLE
-- Historical scoring data
INSERT INTO public.domain_scores (
    id, 
    review_id, 
    domain, 
    score, 
    created_at, 
    updated_at, 
    rag_label, 
    overall_readiness, 
    executive_summary, 
    compliant_areas, 
    gap_areas, 
    blocker_count, 
    action_count, 
    adr_count, 
    domain_specific_scores, 
    evidence_quality, 
    kb_references, 
    generated_at, 
    model_used
) VALUES 
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'SOL',
    3,
    NOW(),
    NOW(),
    'amber',
    'approve_with_conditions',
    'The solution architecture provides a solid foundation with cloud-native microservices, but lacks detailed scalability metrics and technology stack justification.',
    '{STANDARDS_COMPLIANCE, MICROSERVICES_ARCHITECTURE}',
    '{SCALABILITY_METRICS, TECHNOLOGY_JUSTIFICATION}',
    0,
    2,
    0,
    '{"architecture_quality": 4, "scalability": 3, "technology_alignment": 3}',
    'PARTIAL',
    '{KB-01,KB-02,KB-03}',
    NOW(),
    'gemini-2.5-flash-lite'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'BUS',
    3,
    NOW(),
    NOW(),
    'amber',
    'approve_with_conditions',
    'The business case clearly articulates the problem and stakeholders, but lacks detailed ROI analysis and cost-benefit justification.',
    '{PROBLEM_STATEMENT, STAKEHOLDER_IDENTIFICATION}',
    '{ROI_ANALYSIS, COST_BENEFIT_JUSTIFICATION}',
    0,
    1,
    0,
    '{"business_case_quality": 3, "stakeholder_analysis": 4, "outcomes_clarity": 3}',
    'PARTIAL',
    '{KB-04,KB-05}',
    NOW(),
    'gemini-2.5-flash-lite'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'APP',
    3,
    NOW(),
    NOW(),
    'amber',
    'approve_with_conditions',
    'The application architecture follows enterprise patterns but requires detailed security control specifications.',
    '{ENTERPRISE_PATTERNS, HLD_COMPLETENESS}',
    '{SECURITY_CONTROLS, APPLICATION_SECURITY}',
    0,
    1,
    0,
    '{"architecture_compliance": 4, "security_design": 3}',
    'PARTIAL',
    '{KB-06,KB-07}',
    NOW(),
    'gemini-2.5-flash-lite'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INT',
    3,
    NOW(),
    NOW(),
    'amber',
    'approve_with_conditions',
    'The solution has a compliant integration catalogue and API design standards, but lacks explicit detail on integration security mechanisms and NFR coverage.',
    '{API_DESIGN_STANDARDS, CATALOGUE_COMPLETENESS}',
    '{INTEGRATION_SECURITY, NFR_COVERAGE}',
    0,
    2,
    0,
    '{"integration_design": 4, "security_compliance": 3}',
    'PARTIAL',
    '{KB-01,KB-05,KB-08}',
    NOW(),
    'gemini-2.5-flash-lite'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'DAT',
    3,
    NOW(),
    NOW(),
    'amber',
    'approve_with_conditions',
    'The data architecture provides clear classification but needs detailed implementation specifications for retention and disposal.',
    '{DATA_CLASSIFICATION, ARCHITECTURE_CLARITY}',
    '{RETENTION_IMPLEMENTATION, DISPOSAL_SPECIFICATIONS}',
    0,
    1,
    0,
    '{"data_governance": 4, "retention_compliance": 3}',
    'PARTIAL',
    '{KB-09,KB-10}',
    NOW(),
    'gemini-2.5-flash-lite'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'INF',
    2,
    NOW(),
    NOW(),
    'red',
    'reject',
    'Critical gaps in Disaster Recovery and Business Continuity planning, with insufficient monitoring strategy.',
    '{CAPACITY_PLANNING}',
    '{DISASTER_RECOVERY, BUSINESS_CONTINUITY, MONITORING_STRATEGY}',
    3,
    4,
    0,
    '{"infrastructure_design": 3, "dr_readiness": 1, "monitoring_coverage": 2}',
    'INSUFFICIENT',
    '{KB-11,KB-12,KB-13}',
    NOW(),
    'gemini-2.5-flash-lite'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'NFR',
    3,
    NOW(),
    NOW(),
    'amber',
    'approve_with_conditions',
    'NFR requirements are identified but performance testing strategy and benchmarks are not detailed.',
    '{NFR_IDENTIFICATION}',
    '{PERFORMANCE_TESTING, BENCHMARKS}',
    0,
    1,
    0,
    '{"nfr_coverage": 4, "performance_planning": 3}',
    'PARTIAL',
    '{KB-14,KB-15}',
    NOW(),
    'gemini-2.5-flash-lite'
),
(
    gen_random_uuid(),
    '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df',
    'DSO',
    3,
    NOW(),
    NOW(),
    'amber',
    'approve_with_conditions',
    'CI/CD pipeline is designed but security controls need detailed implementation specifications.',
    '{PIPELINE_DESIGN}',
    '{SECURITY_CONTROLS, IMPLEMENTATION}',
    0,
    1,
    0,
    '{"cicd_maturity": 4, "security_implementation": 3}',
    'PARTIAL',
    '{KB-16,KB-17}',
    NOW(),
    'gemini-2.5-flash-lite'
);

-- ===============================================================
-- UPDATED SUMMARY STATISTICS INCLUDING ALL TABLES
-- ===============================================================

-- Query to verify all data insertion
SELECT 
    'Reviews' as table_name, COUNT(*) as record_count FROM reviews WHERE id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
UNION ALL
SELECT 
    'Findings', COUNT(*) FROM findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
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

-- Query to show domain readiness summary
SELECT 
    dr.domain,
    dr.rag_score,
    dr.rag_label,
    dr.domain_readiness,
    dr.blocker_count,
    dr.action_count,
    dr.agent_tokens_used,
    dr.agent_processing_ms
FROM domain_reviews dr
WHERE dr.review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
ORDER BY dr.domain;

-- Query to show NFR scorecard summary
SELECT 
    ns.nfr_category,
    ns.rag_score,
    ns.rag_label,
    ns.slo_target,
    array_to_string(ns.gaps, ', ') as gaps_identified
FROM nfr_scorecard ns
WHERE ns.review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df'
ORDER BY ns.nfr_category;

-- ===============================================================
-- PART 6: CLEANUP STATEMENTS FOR REVIEW TABLES
-- ===============================================================

-- Clean up all inserted data for the specific review (except reviews and audit_logs tables)
-- This allows for re-running the script without conflicts

-- Clean up findings
DELETE FROM public.findings WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up actions
DELETE FROM public.actions WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up ADRs
DELETE FROM public.adrs WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up domain_reviews
DELETE FROM public.domain_reviews WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up recommendations
DELETE FROM public.recommendations WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up NFR scorecard
DELETE FROM public.nfr_scorecard WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up blockers
DELETE FROM public.blockers WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

-- Clean up domain_scores
DELETE FROM public.domain_scores WHERE review_id = '4ff6f3c1-0a3d-42a9-914d-e9f9d52184df';

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

-- ===============================================================
-- END OF SCRIPT
-- ===============================================================
