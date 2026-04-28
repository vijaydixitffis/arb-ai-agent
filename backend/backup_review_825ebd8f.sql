-- Backup for review_id: 825ebd8f-c8db-4654-9b83-0ebca7ffd5e1
-- Solution: Bank Customer Lifecycle Management Digital Transformation
-- Generated at: 2026-04-26 05:59:40.086025+05:30

-- REVIEW TABLE
INSERT INTO reviews (id, created_at, submitted_at, reviewed_at, sa_user_id, solution_name, scope_tags, status, decision, llm_model, tokens_used, processing_time_ms, llm_raw_response, ea_user_id, ea_override_notes, ea_overridden_at, report_json)
VALUES (
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  '2026-04-26 05:59:40.086025+05:30',
  '2026-04-28 17:52:44.194964+05:30'
  '2026-04-28 17:56:45.182550+05:30'
  'd42ae7dd-10fc-4a30-9b19-37bcdd464aac'
  'Bank Customer Lifecycle Management Digital Transformation',
  ARRAY['general', 'application', 'business', 'integration', 'data', 'infrastructure', 'devsecops', 'nfr'],
  'ea_review',
  'reject'
  'gemini-2.5-flash-lite',
  38703,
  119940,
  NULL,
NULL
  NULL,
NULL
  '{"ai_review": {"adrs": [{"id": "ADR-GEN-01", "type": "DECISION", "owner": "solution_architect", "context": "The Banking Backend is a core component requiring agility.", "decision": "Microservices over Monolith for Banking Backend", "rationale": "Chosen for flexibility, scalability, and independent deployment of services.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-GEN-02", "type": "DECISION", "owner": "solution_architect", "context": "Integration is a key aspect of the CLM Platform.", "decision": "Event-Driven Integration via Azure Service Bus", "rationale": "Enables loose coupling and asynchronous communication between microservices.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-GEN-03", "type": "DECISION", "owner": "solution_architect", "context": "Centralized API management is crucial for the CLM Platform.", "decision": "Azure API Management as Single API Gateway", "rationale": "Provides a unified entry point for all APIs, enhancing security and manageability.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-GEN-04", "type": "DECISION", "owner": "solution_architect", "context": "CRM functionality is a key part of the CLM Platform.", "decision": "Salesforce Financial Services Cloud (COTS over Custom Build)", "rationale": "Leverages a proven COTS solution to accelerate delivery and reduce custom development effort.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-GEN-05", "type": "DECISION", "owner": "solution_architect", "context": "Regulatory reporting is a critical requirement.", "decision": "Azure Synapse Analytics for Regulatory Reporting (over Self-Managed Spark)", "rationale": "Utilizes a managed cloud service for analytics, simplifying operations and scaling.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-GEN-06", "type": "DECISION", "owner": "solution_architect", "context": "User-facing portals are essential for the CLM Platform.", "decision": "React 18 - TypeScript SPA for Customer and Staff Portals", "rationale": "Modern JavaScript framework for building responsive and maintainable user interfaces.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-APP-01", "type": "DECISION", "owner": "solution_architect", "context": "The Banking Backend is a core component requiring high agility and independent scaling.", "decision": "Microservices over Monolith for Banking Backend", "rationale": "Chosen for scalability, independent deployment, and technology diversity.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-APP-02", "type": "DECISION", "owner": "solution_architect", "context": "Decoupling services within the CLM Platform and integrating with external systems.", "decision": "Event-Driven Integration via Azure Service Bus", "rationale": "Enables loose coupling, asynchronous communication, and improved resilience.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-APP-03", "type": "DECISION", "owner": "solution_architect", "context": "Exposing Banking Backend services to internal and external consumers.", "decision": "Azure API Management as Single API Gateway", "rationale": "Provides a centralized point for API management, security, and monitoring.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-APP-04", "type": "DECISION", "owner": "solution_architect", "context": "Customer Relationship Management (CRM) functionality within the CLM Platform.", "decision": "Salesforce Financial Services Cloud (COTS over Custom Build)", "rationale": "Leverages industry-specific features and reduces development time and cost.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-APP-05", "type": "DECISION", "owner": "solution_architect", "context": "Handling large volumes of data for regulatory reporting requirements.", "decision": "Azure Synapse Analytics for Regulatory Reporting (over Self-Managed Spark)", "rationale": "Offers integrated data warehousing, big data analytics, and simplifies infrastructure management.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-APP-06", "type": "DECISION", "owner": "solution_architect", "context": "Developing the user-facing portals for customer onboarding and staff interaction.", "decision": "React 18 - TypeScript SPA for Customer and Staff Portals", "rationale": "Modern, performant framework with strong typing for building interactive user interfaces.", "target_date": null, "waiver_expiry_date": null}, {"id": "ADR-DSO-01", "type": "WAIVER", "owner": "solution_architect", "context": "This decision was made to optimize costs and resource utilization in the development environment during the initial phases of the project. Dedicated PaaS instances for development environments are planned for later stages.", "decision": "Waiver for partial Dev-Prod Parity", "rationale": "The development environment utilizes shared PaaS resources (e.g., SQL MI) instead of dedicated resources as in SIT, UAT, and Prod. This is a deviation from strict Dev-Prod Parity.", "target_date": null, "waiver_expiry_date": "2027-04-28"}, {"id": "ADR-NFR-01", "type": "WAIVER", "owner": "Compliance Infosec", "context": "The solution is a new build and the VAPT is scheduled post-initial deployment.", "decision": "Waiver for VAPT evidence prior to go-live", "rationale": "Penetration testing is scheduled for Q3 2026, post-go-live. This waiver is requested due to the critical nature of the platform and the planned testing timeline.", "target_date": null, "waiver_expiry_date": "2026-12-31"}], "actions": [{"id": "GEN-ACT-01", "action": "Update SA documentation to include a dedicated section on adherence to enterprise architecture principles, providing specific examples.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "GEN-F01"}, {"id": "GEN-ACT-02", "action": "Develop and include a Total Cost of Ownership (TCO) analysis in the SA documentation.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "GEN-F02"}, {"id": "GEN-ACT-03", "action": "Document the process for incorporating end-user feedback and requirements into the CLM Platform architecture.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "GEN-F03"}, {"id": "GEN-ACT-04", "action": "Detail adherence to key enterprise processes within the SA documentation.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "GEN-F04"}, {"id": "GEN-ACT-05", "action": "Articulate the alignment of the CLM Platform with enterprise strategic objectives in the SA documentation.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "GEN-F05"}, {"id": "APP-ACT-01", "action": "Provide detailed documentation on the CLM Platform''s architecture style, including patterns, technologies, and their alignment with enterprise standards.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "APP-F01"}, {"id": "APP-ACT-02", "action": "Establish and document a process for ensuring documentation currency, including version control and regular review cycles.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "APP-F02"}, {"id": "APP-ACT-03", "action": "Document the comprehensive monitoring and alerting strategy for the CLM Platform, covering key metrics, alert thresholds, and response procedures.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "APP-F03"}, {"id": "APP-ACT-04", "action": "Detail the resilience patterns implemented within the CLM Platform, such as redundancy, failover, and disaster recovery mechanisms.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "APP-F04"}, {"id": "APP-ACT-05", "action": "Implement and document the process for generating Software Bill of Materials (SBOM) and continuously monitoring the health of third-party dependencies.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "APP-F05"}, {"id": "APP-ACT-06", "action": "Define and implement a clear process for identifying, tracking, and prioritizing the remediation of technical debt within the CLM Platform.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "APP-F06"}, {"id": "APP-ACT-07", "action": "Document the strategy for managing versioning compatibility across all components and integrations of the CLM Platform.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "APP-F07"}, {"id": "BUS-ACT-01", "action": "Update the ''Evidence Source'' column in the Business NFRs Register with specific evidence or status updates for NFRs currently marked as ''In Design'' or ''Not Tested''.", "due_days": 30, "priority": "LOW", "owner_role": "solution_architect", "finding_ref": "BUS-F02"}, {"id": "BUS-ACT-02", "action": "Create and submit a dedicated Business Scope document or add a section to an existing document clearly defining the in-scope and out-of-scope elements of the CLM Platform.", "due_days": 15, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "BUS-F03"}, {"id": "BUS-ACT-03", "action": "Develop and submit a stakeholder analysis or RACI matrix for the CLM Platform project.", "due_days": 30, "priority": "MEDIUM", "owner_role": "solution_architect", "finding_ref": "BUS-F04"}, {"id": "BUS-ACT-04", "action": "Provide documentation detailing the impact on current business operations and a plan for operational readiness, including training and support for the CLM Platform.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "BUS-F05"}, {"id": "INT-ACT-01", "action": "Develop and populate the Integration Domain Knowledge Base with comprehensive API design standards, including but not limited to versioning strategies, authentication/authorization mechanisms, request/response formats, and error handling.", "due_days": 60, "priority": "HIGH", "owner_role": "enterprise_architect", "finding_ref": "INT-F01"}, {"id": "INT-ACT-02", "action": "Define and document the enterprise standards for integration catalogue completeness, including required fields, metadata, and governance processes.", "due_days": 60, "priority": "HIGH", "owner_role": "enterprise_architect", "finding_ref": "INT-F02"}, {"id": "INT-ACT-03", "action": "Establish and document enterprise-wide standards and best practices for ensuring idempotency in integrations, including guidance on idempotency keys and mechanisms.", "due_days": 60, "priority": "HIGH", "owner_role": "enterprise_architect", "finding_ref": "INT-F03"}, {"id": "INT-ACT-04", "action": "Create and disseminate enterprise security standards for integrations, covering aspects like encryption, authentication protocols, authorization, and threat mitigation.", "due_days": 60, "priority": "HIGH", "owner_role": "enterprise_architect", "finding_ref": "INT-F04"}, {"id": "INT-ACT-05", "action": "Define and document enterprise Non-Functional Requirements (NFRs) coverage standards for integrations, including performance, availability, scalability, and reliability metrics.", "due_days": 60, "priority": "HIGH", "owner_role": "enterprise_architect", "finding_ref": "INT-F05"}, {"id": "DAT-ACT-01", "action": "Complete the Data Classification Register by filling in all missing details for each data asset, ensuring all columns are populated accurately.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "DAT-F01"}, {"id": "DAT-ACT-02", "action": "Detail the automated enforcement mechanisms for data retention and deletion policies, including audit trails, within the ''DAT_02_Data_Architecture_and_Governance.docx'' document.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "DAT-F02"}, {"id": "DAT-ACT-03", "action": "Provide comprehensive data model documentation for all bounded contexts, including ERDs and attribute definitions, and replace placeholder diagrams in ''DAT_02_Data_Architecture_and_Governance.docx''.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "DAT-F03"}, {"id": "DAT-ACT-04", "action": "Develop and document a formal process for tracking EOS/EOL for all data platforms and services, and include this in the ''DAT_02_Data_Architecture_and_Governance.docx''.", "due_days": 30, "priority": "HIGH", "owner_role": "solution_architect", "finding_ref": "DAT-F04"}, {"id": "DSO-ACT-01", "action": "Implement and report on ''Build success rate'', ''Average build duration'', and ''PR cycle time'' metrics. Ensure targets are defined and current values are tracked.", "due_days": 30, "priority": "MEDIUM", "owner_role": "dev_team", "finding_ref": "DSO-F01"}, {"id": "DSO-ACT-02", "action": "Develop and execute unit and integration tests. Establish CI gates to enforce minimum code coverage targets (line and branch).", "due_days": 60, "priority": "HIGH", "owner_role": "dev_team", "finding_ref": "DSO-F02"}, {"id": "DSO-ACT-03", "action": "Execute performance tests for critical APIs (onboarding, KYC) under expected load. Document results including P95 response times and error rates.", "due_days": 60, "priority": "HIGH", "owner_role": "dev_team", "finding_ref": "DSO-F05"}, {"id": "DSO-ACT-04", "action": "Schedule and execute DAST scans in the staging environment. Review and address any medium or high findings, documenting accepted risks with owner sign-off.", "due_days": 45, "priority": "MEDIUM", "owner_role": "security_team", "finding_ref": "DSO-F06"}, {"id": "DSO-ACT-05", "action": "Establish and report on defect tracking metrics for critical and high defects in the backlog and at go-no-go. Ensure evidence of current status is available.", "due_days": 30, "priority": "HIGH", "owner_role": "dev_team", "finding_ref": "DSO-F07"}, {"id": "DSO-ACT-06", "action": "Implement and report on code duplication, technical debt ratio, security hotspot review completion, and API contract test pass rate metrics. Provide evidence of current status.", "due_days": 45, "priority": "MEDIUM", "owner_role": "dev_team", "finding_ref": "DSO-F09"}, {"id": "NFR-ACT-01", "action": "Schedule and execute penetration testing. Provide a report detailing findings, remediation actions, and re-testing results.", "due_days": 90, "priority": "HIGH", "owner_role": "security_team", "finding_ref": "NFR-F01"}, {"id": "NFR-ACT-02", "action": "Execute Gatling load tests in the UAT environment as planned (May 5-9, 2026) and document the results against the defined performance targets.", "due_days": 15, "priority": "HIGH", "owner_role": "dev_team", "finding_ref": "NFR-F02"}, {"id": "NFR-ACT-03", "action": "Update NFR-001 evidence with results from the Gatling load test, specifically validating the support for 5,000 concurrent users without degradation.", "due_days": 20, "priority": "MEDIUM", "owner_role": "dev_team", "finding_ref": "NFR-F03"}, {"id": "NFR-ACT-04", "action": "Schedule and execute a DR drill. Document the process, outcomes, and confirm adherence to RPO and RTO targets.", "due_days": 60, "priority": "HIGH", "owner_role": "enterprise_architect", "finding_ref": "NFR-F04"}, {"id": "NFR-ACT-05", "action": "Complete and document the Gatling load tests for NFR-003 (Onboarding form submission P95) and NFR-004 (KYC Tier-1 decision time).", "due_days": 20, "priority": "HIGH", "owner_role": "dev_team", "finding_ref": "NFR-F06"}], "blockers": [{"id": "GEN-BLK-01", "description": "Evidence for ARCHITECTURE_PRINCIPLES_ADHERENCE is missing. The SA document does not explicitly state adherence to enterprise architecture principles.", "domain_slug": "general", "finding_ref": "GEN-F01", "resolution_required": "Provide a section in the SA documentation explicitly detailing adherence to enterprise architecture principles, referencing specific principles and how the CLM Platform aligns."}, {"id": "GEN-BLK-02", "description": "Evidence for ECONOMICS_TCO is missing. The SA document does not contain any information regarding the Total Cost of Ownership (TCO) for the CLM Platform.", "domain_slug": "general", "finding_ref": "GEN-F02", "resolution_required": "Include a TCO analysis in the SA documentation, outlining projected costs for development, deployment, and ongoing operations."}, {"id": "GEN-BLK-03", "description": "Evidence for END_USER_VOICE is missing. The SA document does not describe how end-user feedback or requirements have been incorporated into the architecture.", "domain_slug": "general", "finding_ref": "GEN-F03", "resolution_required": "Document the process for incorporating end-user feedback and requirements into the CLM Platform architecture, including any user research or validation activities."}, {"id": "GEN-BLK-04", "description": "Evidence for PROCESS_ADHERENCE is missing. The SA document does not detail how the solution adheres to established enterprise processes (e.g., development, deployment, security).", "domain_slug": "general", "finding_ref": "GEN-F04", "resolution_required": "Provide a section in the SA documentation that outlines adherence to key enterprise processes, specifying how each process is followed for the CLM Platform."}, {"id": "GEN-BLK-05", "description": "Evidence for STRATEGY_ALIGNMENT is missing. The SA document does not explicitly demonstrate how the CLM Platform aligns with the overall enterprise strategy.", "domain_slug": "general", "finding_ref": "GEN-F05", "resolution_required": "Include a section in the SA documentation that clearly articulates the alignment of the CLM Platform with the enterprise''s strategic objectives."}, {"id": "APP-BLK-01", "description": "Evidence for ARCHITECTURE_STYLE mandatory check is absent.", "domain_slug": "application", "finding_ref": "APP-F01", "resolution_required": "Provide evidence or documentation detailing the architecture style and its adherence to enterprise standards."}, {"id": "APP-BLK-02", "description": "Evidence for DOCUMENTATION_CURRENCY mandatory check is absent.", "domain_slug": "application", "finding_ref": "APP-F02", "resolution_required": "Provide evidence of documentation currency, such as version control, last updated dates, or a documented review process."}, {"id": "APP-BLK-03", "description": "Evidence for MONITORING_AND_ALERTING mandatory check is absent.", "domain_slug": "application", "finding_ref": "APP-F03", "resolution_required": "Provide documentation or evidence of the monitoring and alerting strategy for the CLM Platform."}, {"id": "APP-BLK-04", "description": "Evidence for RESILIENCE_PATTERNS mandatory check is absent.", "domain_slug": "application", "finding_ref": "APP-F04", "resolution_required": "Provide documentation or evidence detailing the resilience patterns implemented in the CLM Platform."}, {"id": "APP-BLK-05", "description": "Evidence for SBOM_AND_DEPENDENCY_HEALTH mandatory check is absent.", "domain_slug": "application", "finding_ref": "APP-F05", "resolution_required": "Provide evidence of SBOM generation and dependency health checks for all components of the CLM Platform."}, {"id": "APP-BLK-06", "description": "Evidence for TECH_DEBT_TRACKING mandatory check is absent.", "domain_slug": "application", "finding_ref": "APP-F06", "resolution_required": "Provide evidence of a process for tracking and managing technical debt within the CLM Platform."}, {"id": "APP-BLK-07", "description": "Evidence for VERSIONING_COMPATIBILITY mandatory check is absent.", "domain_slug": "application", "finding_ref": "APP-F07", "resolution_required": "Provide evidence of the strategy for managing versioning compatibility across CLM Platform components and integrations."}, {"id": "BUS-BLK-01", "description": "Evidence for Business Operations is missing. The SA submission does not contain any artifacts detailing how the business operations will be impacted or managed post-transformation.", "domain_slug": "business", "finding_ref": "BUS-F05", "resolution_required": "Provide documentation or artifacts that describe the impact on business operations and the plan for managing them."}, {"id": "INT-BLK-01", "description": "Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for API Design Standards.", "domain_slug": "integration", "finding_ref": "INT-F01", "resolution_required": "Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines."}, {"id": "INT-BLK-02", "description": "Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for Catalogue Completeness.", "domain_slug": "integration", "finding_ref": "INT-F02", "resolution_required": "Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines."}, {"id": "INT-BLK-03", "description": "Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for Idempotency.", "domain_slug": "integration", "finding_ref": "INT-F03", "resolution_required": "Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines."}, {"id": "INT-BLK-04", "description": "Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for Integration Security.", "domain_slug": "integration", "finding_ref": "INT-F04", "resolution_required": "Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines."}, {"id": "INT-BLK-05", "description": "Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for NFR Coverage.", "domain_slug": "integration", "finding_ref": "INT-F05", "resolution_required": "Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines."}, {"id": "DAT-BLK-01", "description": "Lack of detailed data classification evidence for all data assets. While some assets are classified, a comprehensive review and clear documentation for all are missing.", "domain_slug": "data", "finding_ref": "DAT-F01", "resolution_required": "Provide a complete data classification register for all data assets, detailing classification levels, ownership, and PII status, referencing the ''DAT_01_Data_Classification_Register.xlsx'' artifact."}, {"id": "DAT-BLK-02", "description": "Incomplete data lifecycle documentation. Retention periods and deletion mechanisms are listed, but a clear, auditable process for enforcing these across all data stores is not detailed.", "domain_slug": "data", "finding_ref": "DAT-F02", "resolution_required": "Document the end-to-end data lifecycle management process, including automated enforcement of retention and deletion policies, referencing ''DAT_02_Data_Architecture_and_Governance.docx''."}, {"id": "DAT-BLK-03", "description": "Insufficient data model documentation. While the canonical Customer entity is mentioned, detailed documentation for other domain-specific data models and their relationships is absent.", "domain_slug": "data", "finding_ref": "DAT-F03", "resolution_required": "Provide comprehensive data model documentation for all bounded contexts, including entity-relationship diagrams and attribute definitions, as referenced in ''DAT_02_Data_Architecture_and_Governance.docx''."}, {"id": "DAT-BLK-04", "description": "Absence of explicit End-of-Support (EOS) and End-of-Life (EOL) tracking for data platforms and services. The ''EoSEoL Data Platform Assessment'' section in ''DAT_02_Data_Architecture_and_Governance.docx'' is not elaborated.", "domain_slug": "data", "finding_ref": "DAT-F04", "resolution_required": "Submit a detailed assessment and tracking plan for EOS/EOL for all data platforms and services used within the CLM Platform."}, {"id": "DSO-BLK-01", "description": "Code coverage metrics (unit test line coverage and branch coverage) are not yet measured, with tests not written. This is a mandatory requirement for demonstrating software quality.", "domain_slug": "devsecops", "finding_ref": "DSO-F02", "resolution_required": "Implement unit and integration tests and establish CI gates for code coverage metrics."}, {"id": "DSO-BLK-02", "description": "Performance testing for API response times and error rates under load has not been conducted. This is a critical gap for ensuring the stability and reliability of the platform.", "domain_slug": "devsecops", "finding_ref": "DSO-F05", "resolution_required": "Execute performance tests for critical APIs and document results, including response times and error rates under expected load."}, {"id": "NFR-BLK-01", "description": "VAPT evidence is missing. The SA submission indicates penetration testing is ''Planned'' for Q3 2026, but no evidence of current or completed VAPT activities is provided, which is a mandatory requirement.", "domain_slug": "nfr", "finding_ref": "NFR-F01", "resolution_required": "Provide evidence of completed VAPT or a detailed plan with interim milestones and a firm go-live commitment."}, {"id": "NFR-BLK-02", "description": "DR drill evidence is missing. While DR targets and procedures are documented, the actual DR drill has not been performed, and evidence is required before go-live.", "domain_slug": "nfr", "finding_ref": "NFR-F04", "resolution_required": "Conduct and document a DR drill, providing evidence of successful failover and adherence to RTO/RPO targets."}], "decision": "reject", "findings": [{"id": "GEN-F01", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for ARCHITECTURE_PRINCIPLES_ADHERENCE is missing. The SA document (APP_02_HLD_and_ADRs.docx) does not explicitly state adherence to enterprise architecture principles. No KB documents were provided for validation.", "rag_label": "RED", "rag_score": 1, "domain_slug": "general", "artifact_ref": "APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "ARCHITECTURE_PRINCIPLES_ADHERENCE"}, {"id": "GEN-F02", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for ECONOMICS_TCO is missing. The SA document (GEN_03_Standards_and_Policies_Doc.docx) does not contain any information regarding the Total Cost of Ownership (TCO) for the CLM Platform. No KB documents were provided for validation.", "rag_label": "RED", "rag_score": 1, "domain_slug": "general", "artifact_ref": "GEN_03_Standards_and_Policies_Doc.docx", "principle_id": null, "check_category": "ECONOMICS_TCO"}, {"id": "GEN-F03", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for END_USER_VOICE is missing. The SA document (APP_02_HLD_and_ADRs.docx) does not describe how end-user feedback or requirements have been incorporated into the architecture. No KB documents were provided for validation.", "rag_label": "RED", "rag_score": 1, "domain_slug": "general", "artifact_ref": "APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "END_USER_VOICE"}, {"id": "GEN-F04", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for PROCESS_ADHERENCE is missing. The SA document (GEN_03_Standards_and_Policies_Doc.docx) does not detail how the solution adheres to established enterprise processes (e.g., development, deployment, security). No KB documents were provided for validation.", "rag_label": "RED", "rag_score": 1, "domain_slug": "general", "artifact_ref": "GEN_03_Standards_and_Policies_Doc.docx", "principle_id": null, "check_category": "PROCESS_ADHERENCE"}, {"id": "GEN-F05", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for STRATEGY_ALIGNMENT is missing. The SA document (APP_02_HLD_and_ADRs.docx) does not explicitly demonstrate how the CLM Platform aligns with the overall enterprise strategy. No KB documents were provided for validation.", "rag_label": "RED", "rag_score": 1, "domain_slug": "general", "artifact_ref": "APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "STRATEGY_ALIGNMENT"}, {"id": "APP-F01", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for ARCHITECTURE_STYLE mandatory check is absent. The provided HLD mentions a cloud-native, API-led, microservices architecture but lacks specific details or adherence to enterprise standards.", "rag_label": "RED", "rag_score": 1, "domain_slug": "application", "artifact_ref": "Artefact 1: APP_02_HLD_and_ADRs.docx - Section 1. Architecture Overview", "principle_id": null, "check_category": "ARCHITECTURE_STYLE"}, {"id": "APP-F02", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for DOCUMENTATION_CURRENCY mandatory check is absent. The HLD document does not contain information regarding its currency or update process.", "rag_label": "RED", "rag_score": 1, "domain_slug": "application", "artifact_ref": "Artefact 1: APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "DOCUMENTATION_CURRENCY"}, {"id": "APP-F03", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for MONITORING_AND_ALERTING mandatory check is absent. No details regarding monitoring and alerting strategies for the CLM Platform are present in the submitted artifacts.", "rag_label": "RED", "rag_score": 1, "domain_slug": "application", "artifact_ref": "Artefact 1: APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "MONITORING_AND_ALERTING"}, {"id": "APP-F04", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for RESILIENCE_PATTERNS mandatory check is absent. The submitted artifacts do not describe the resilience patterns implemented in the CLM Platform.", "rag_label": "RED", "rag_score": 1, "domain_slug": "application", "artifact_ref": "Artefact 1: APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "RESILIENCE_PATTERNS"}, {"id": "APP-F05", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for SBOM_AND_DEPENDENCY_HEALTH mandatory check is absent. There is no mention of SBOM generation or dependency health management for the CLM Platform.", "rag_label": "RED", "rag_score": 1, "domain_slug": "application", "artifact_ref": "Artefact 1: APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "SBOM_AND_DEPENDENCY_HEALTH"}, {"id": "APP-F06", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for TECH_DEBT_TRACKING mandatory check is absent. The submitted artifacts do not include information on how technical debt is tracked or managed for the CLM Platform.", "rag_label": "RED", "rag_score": 1, "domain_slug": "application", "artifact_ref": "Artefact 1: APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "TECH_DEBT_TRACKING"}, {"id": "APP-F07", "kb_ref": "N/A - No KB documents provided", "finding": "Evidence for VERSIONING_COMPATIBILITY mandatory check is absent. The artifacts do not describe the approach to versioning compatibility for the CLM Platform.", "rag_label": "RED", "rag_score": 1, "domain_slug": "application", "artifact_ref": "Artefact 1: APP_02_HLD_and_ADRs.docx", "principle_id": null, "check_category": "VERSIONING_COMPATIBILITY"}, {"id": "BUS-F01", "kb_ref": null, "finding": "The Business Case document (BUS_02_Business_Case_and_Problem_Statement.docx) outlines the strategic alignment and problem statement for the CLM Platform, directly addressing the need for digital transformation and regulatory compliance. However, specific ROI and detailed KPIs could be further elaborated.", "rag_label": "GREEN", "rag_score": 4, "domain_slug": "business", "artifact_ref": "BUS_02_Business_Case_and_Problem_Statement.docx", "principle_id": null, "check_category": "BUSINESS_CASE"}, {"id": "BUS-F02", "kb_ref": null, "finding": "The Business NFRs Register (BUS_01_Business_NFRs_Register.xlsx) is well-structured and covers a broad range of NFRs. However, many NFRs are marked as ''In Design'' or ''Not Tested'' with no concrete evidence provided, impacting the confidence in their current status.", "rag_label": "AMBER", "rag_score": 3, "domain_slug": "business", "artifact_ref": "BUS_01_Business_NFRs_Register.xlsx", "principle_id": null, "check_category": "BUSINESS_NFRS"}, {"id": "BUS-F03", "kb_ref": null, "finding": "Evidence for Business Scope is absent. The submitted artifacts do not contain a clear definition of the CLM Platform''s scope, boundaries, or key deliverables, making it difficult to assess the project''s focus and potential for scope creep.", "rag_label": "RED", "rag_score": 1, "domain_slug": "business", "artifact_ref": "None provided", "principle_id": null, "check_category": "BUSINESS_SCOPE"}, {"id": "BUS-F04", "kb_ref": null, "finding": "Key stakeholders are mentioned implicitly through ownership of NFRs in BUS_01_Business_NFRs_Register.xlsx (e.g., Chief Compliance Officer, DPO, Product Owner). However, a formal stakeholder analysis or RACI matrix is missing, which would provide a clearer picture of stakeholder engagement and responsibilities.", "rag_label": "AMBER", "rag_score": 3, "domain_slug": "business", "artifact_ref": "BUS_01_Business_NFRs_Register.xlsx", "principle_id": null, "check_category": "BUSINESS_STAKEHOLDERS"}, {"id": "BUS-F05", "kb_ref": null, "finding": "Evidence for Business Operations is absent. There are no artifacts submitted that describe the impact of the CLM Platform on current business operations, nor is there a plan for operational readiness, training, or ongoing support.", "rag_label": "RED", "rag_score": 1, "domain_slug": "business", "artifact_ref": "None provided", "principle_id": null, "check_category": "BUSINESS_OPERATIONS"}, {"id": "INT-F01", "kb_ref": "N/A - KB documentation for Integration Domain is missing.", "finding": "Evidence for API Design Standards cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_03_API_Interface_Catalog.docx'' mentions OpenAPI 3.0, versioning via URI, Bearer token validation at APIM, Idempotency-Key header, cursor-based pagination, RFC 7807 Problem Details, and rate limits, but without KB standards, these cannot be assessed for compliance.", "rag_label": "RED", "rag_score": 1, "domain_slug": "integration", "artifact_ref": "APP_03_API_Interface_Catalog.docx", "principle_id": null, "check_category": "API_DESIGN_STANDARDS"}, {"id": "INT-F02", "kb_ref": "N/A - KB documentation for Integration Domain is missing.", "finding": "Evidence for Catalogue Completeness cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' provides an integration catalogue, but its completeness against enterprise standards cannot be verified without the relevant KB.", "rag_label": "RED", "rag_score": 1, "domain_slug": "integration", "artifact_ref": "APP_01_Integration_Catalogue_and_Tech_Debt.xlsx", "principle_id": null, "check_category": "CATALOGUE_COMPLETENESS"}, {"id": "INT-F03", "kb_ref": "N/A - KB documentation for Integration Domain is missing.", "finding": "Evidence for Idempotency cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' lists ''Idempotency'' as a column for several integrations (e.g., INT-001, INT-002, INT-003, INT-004, INT-005), and ''Idempotency-Key header mandatory'' is mentioned in ''APP_03_API_Interface_Catalog.docx'', but the specific enterprise standards for idempotency are not available for verification.", "rag_label": "RED", "rag_score": 1, "domain_slug": "integration", "artifact_ref": "APP_01_Integration_Catalogue_and_Tech_Debt.xlsx, APP_03_API_Interface_Catalog.docx", "principle_id": null, "check_category": "IDEMPOTENCY"}, {"id": "INT-F04", "kb_ref": "N/A - KB documentation for Integration Domain is missing.", "finding": "Evidence for Integration Security cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' details various security controls (e.g., OAuth 2.0, mTLS, TLS 1.3, WAF, client-generated correlation ID, Azure AD Bearer token, MFA), but compliance with enterprise security standards cannot be confirmed without the relevant KB.", "rag_label": "RED", "rag_score": 1, "domain_slug": "integration", "artifact_ref": "APP_01_Integration_Catalogue_and_Tech_Debt.xlsx", "principle_id": null, "check_category": "INTEGRATION_SECURITY"}, {"id": "INT-F05", "kb_ref": "N/A - KB documentation for Integration Domain is missing.", "finding": "Evidence for NFR Coverage cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' lists NFRs for various integrations (e.g., response time, availability), but their adequacy and adherence to enterprise standards cannot be assessed without the relevant KB.", "rag_label": "RED", "rag_score": 1, "domain_slug": "integration", "artifact_ref": "APP_01_Integration_Catalogue_and_Tech_Debt.xlsx", "principle_id": null, "check_category": "NFR_COVERAGE"}, {"id": "DAT-F01", "kb_ref": "KB Document: Data Classification Standard (Assumed)", "finding": "The provided ''DAT_01_Data_Classification_Register.xlsx'' is incomplete. While it lists several data assets, a comprehensive classification for all data assets within the CLM Platform is not evident. Specifically, the ''Classification System'' and ''Store'' columns are often empty or ''NaN'', and the scope of ''all data assets'' is not clearly defined.", "rag_label": "RED", "rag_score": 1, "domain_slug": "data", "artifact_ref": "DAT_01_Data_Classification_Register.xlsx", "principle_id": null, "check_category": "DATA_CLASSIFICATION"}, {"id": "DAT-F02", "kb_ref": "KB Document: Data Lifecycle Management Policy (Assumed)", "finding": "The ''Data Retention & Deletion Schedule'' section in ''DAT_02_Data_Architecture_and_Governance.docx'' lists retention periods but lacks detail on the mechanisms for automated enforcement and auditing of these policies across all data stores. For example, ''SQL archival'' and ''Logical delete'' need further clarification on implementation and verification.", "rag_label": "RED", "rag_score": 1, "domain_slug": "data", "artifact_ref": "DAT_02_Data_Architecture_and_Governance.docx", "principle_id": null, "check_category": "DATA_LIFECYCLE"}, {"id": "DAT-F03", "kb_ref": "KB Document: Data Modeling Standards (Assumed)", "finding": "The ''DAT_02_Data_Architecture_and_Governance.docx'' mentions a canonical Customer entity and DDD principles but lacks detailed documentation for other data models within the CLM Platform. The ''Data Architecture Diagram'' and ''Data Flow Diagram'' are placeholders, and specific details on other bounded context data models are missing.", "rag_label": "RED", "rag_score": 1, "domain_slug": "data", "artifact_ref": "DAT_02_Data_Architecture_and_Governance.docx", "principle_id": null, "check_category": "DATA_MODEL_DOCUMENTATION"}, {"id": "DAT-F04", "kb_ref": "KB Document: Technology Lifecycle Management Policy (Assumed)", "finding": "The ''EoSEoL Data Platform Assessment'' mentioned in ''DAT_02_Data_Architecture_and_Governance.docx'' is not elaborated upon. There is no evidence of a defined process or documentation for tracking End-of-Support (EOS) and End-of-Life (EOL) for the data platforms and services utilized by the CLM Platform.", "rag_label": "RED", "rag_score": 1, "domain_slug": "data", "artifact_ref": "DAT_02_Data_Architecture_and_Governance.docx", "principle_id": null, "check_category": "EOS_EOL_TRACKING"}, {"id": "DSO-F01", "kb_ref": "KB Document: CI/CD Best Practices - Metrics and Monitoring", "finding": "Several key CI/CD pipeline quality metrics (''Build success rate'', ''Average build duration'', ''PR cycle time'') are marked as ''NOT MEASURED'' and are associated with a ''new build pipeline''. Evidence of current measurement and targets is missing.", "rag_label": "AMBER", "rag_score": 2, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: DevOps Metrics Dashboard CLM Platform, Rows 14-16", "principle_id": null, "check_category": "CICD_PIPELINE_QUALITY"}, {"id": "DSO-F02", "kb_ref": "KB Document: Software Quality Standards - Test Coverage", "finding": "Unit test line coverage and branch coverage are ''NOT STARTED'' with ''0 (no tests written yet)''. This is a mandatory requirement and evidence of compliance is absent.", "rag_label": "RED", "rag_score": 1, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: SW Quality Metrics CLM Platform, Rows 2-3", "principle_id": null, "check_category": "TEST_COVERAGE"}, {"id": "DSO-F03", "kb_ref": "KB Document: SAST Integration and Quality Gates", "finding": "SAST tools (SonarQube) are integrated into the CI pipeline, with quality gates enforcing zero Blocker and Critical issues. Code duplication and technical debt ratio are being tracked.", "rag_label": "GREEN", "rag_score": 5, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: SW Quality Metrics CLM Platform, Rows 4-7; DSO_03_Secure_Code_Review_Report.docx", "principle_id": null, "check_category": "SAST_INTEGRATION"}, {"id": "DSO-F04", "kb_ref": "KB Document: Secrets Management Best Practices", "finding": "Secrets are managed via Azure Key Vault, with references in all services. GitGuardian scans are clean, and pre-commit hooks are in place. Service account certificate rotation is configured.", "rag_label": "GREEN", "rag_score": 5, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: DevOps Metrics Dashboard CLM Platform, Rows 20-22", "principle_id": null, "check_category": "SECRETS_CONFIG_MGMT"}, {"id": "DSO-F05", "kb_ref": "KB Document: Performance Testing Standards", "finding": "Performance testing for API response times (onboarding, KYC check) and error rates under load are ''Not tested'' and ''NOT STARTED''. This is a mandatory requirement and evidence is absent.", "rag_label": "RED", "rag_score": 1, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: SW Quality Metrics CLM Platform, Rows 15-17", "principle_id": null, "check_category": "PERFORMANCE_TEST_RESULTS"}, {"id": "DSO-F06", "kb_ref": "KB Document: DAST Integration and Reporting", "finding": "DAST scanning is planned with OWASP ZAP for staging, but results are ''Not yet run''. Medium findings are noted with accepted risk, but active scanning and remediation evidence is missing.", "rag_label": "AMBER", "rag_score": 3, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: SW Quality Metrics CLM Platform, Rows 12-14", "principle_id": null, "check_category": "DAST_RESULTS"}, {"id": "DSO-F07", "kb_ref": "KB Document: Defect Management and Tracking", "finding": "Defect tracking metrics for ''Critical defects in backlog'' and ''High defects open at gono-go'' are ''NOT MEASURED''. While a zero-tolerance policy for critical defects is mentioned, current status and evidence are missing.", "rag_label": "AMBER", "rag_score": 2, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: SW Quality Metrics CLM Platform, Rows 19-20", "principle_id": null, "check_category": "DEFECT_METRICS"}, {"id": "DSO-F08", "kb_ref": "KB Document: Code Review Standards", "finding": "Code review coverage is robust, with 100% of PRs reviewed by a minimum of two engineers, enforced via branch protection. EA architectural approval for design PRs is also enforced.", "rag_label": "GREEN", "rag_score": 5, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: SW Quality Metrics CLM Platform, Rows 17-18", "principle_id": null, "check_category": "CODE_REVIEW_COVERAGE"}, {"id": "DSO-F09", "kb_ref": "KB Document: Software Quality Metrics and Reporting", "finding": "Several SW quality metrics are in a ''NOT STARTED'' or ''NOT MEASURED'' state, including code duplication, technical debt ratio, security hotspot review completion, and API contract test pass rate. While plans are in place, current status and evidence are missing.", "rag_label": "AMBER", "rag_score": 3, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: SW Quality Metrics CLM Platform, Rows 6-9, 21", "principle_id": null, "check_category": "SW_QUALITY_METRICS"}, {"id": "DSO-F10", "kb_ref": "KB Document: 12-Factor App Principles", "finding": "Most 12-Factor compliance items are met (''COMPLIANT''). However, ''Dev-Prod Parity'' is marked ''PARTIAL'' due to DEV using shared PaaS, which is noted as an acceptable gap.", "rag_label": "GREEN", "rag_score": 4, "domain_slug": "devsecops", "artifact_ref": "DSO_01_DevOps_and_SW_Quality_Metrics.xlsx, Sheet: DevOps Metrics Dashboard CLM Platform, Row 11", "principle_id": null, "check_category": "TWELVE_FACTOR_COMPLIANCE"}, {"id": "NFR-F01", "kb_ref": "Enterprise Architecture Standards - Security - VAPT", "finding": "Evidence for Vulnerability Assessment and Penetration Testing (VAPT) is missing. The SA submission states VAPT is ''Planned'' for Q3 2026, but no evidence of completed testing or interim validation is provided, failing the mandatory requirement.", "rag_label": "RED", "rag_score": 1, "domain_slug": "nfr", "artifact_ref": "NFR_01_NFR_Requirements_and_Security_Controls.xlsx (SC-021)", "principle_id": "SEC-PRIN-005", "check_category": "VAPT_EVIDENCE"}, {"id": "NFR-F02", "kb_ref": "Enterprise Architecture Standards - Performance - Load Testing", "finding": "Performance testing is planned but not yet executed. The ''Performance Baseline Report'' indicates tests are targeted for May 2026, and ARB requires results before final sign-off. NFR-001, NFR-003, NFR-004, and NFR-005 all rely on these upcoming tests.", "rag_label": "AMBER", "rag_score": 3, "domain_slug": "nfr", "artifact_ref": "NFR_01_NFR_Requirements_and_Security_Controls.xlsx, NFR_03_Performance_Baseline_Report.docx", "principle_id": "PERF-PRIN-002", "check_category": "SCALABILITY_PERFORMANCE"}, {"id": "NFR-F03", "kb_ref": "Enterprise Architecture Standards - Scalability - Concurrent Users", "finding": "Scalability NFR-001 (5,000 concurrent users) has a target but no established baseline. The evidence states ''Test planned 5-9 May 2026 in UAT environment'', indicating the requirement is not yet met.", "rag_label": "AMBER", "rag_score": 3, "domain_slug": "nfr", "artifact_ref": "NFR_01_NFR_Requirements_and_Security_Controls.xlsx (NFR-001)", "principle_id": "SCAL-PRIN-001", "check_category": "SCALABILITY_PERFORMANCE"}, {"id": "NFR-F04", "kb_ref": "Enterprise Architecture Standards - DR - DR Drills", "finding": "Disaster Recovery (DR) drill has not been performed. While RPO (15 mins) and RTO (4 hours) targets are defined, the evidence states ''DR drill not done'' and ''DR drill required before go-live'', failing the mandatory check.", "rag_label": "RED", "rag_score": 1, "domain_slug": "nfr", "artifact_ref": "NFR_02_HA_and_DR_Plan.docx, NFR_01_NFR_Requirements_and_Security_Controls.xlsx (NFR-010, NFR-011)", "principle_id": "DR-PRIN-003", "check_category": "DR"}, {"id": "NFR-F05", "kb_ref": "Enterprise Architecture Standards - HA - Uptime", "finding": "High Availability (HA) targets and design are well-defined and evidenced. Customer Portal targets 99.9% uptime (NFR-007), Banking Backend targets 99.99% (NFR-008), and APIM gateway targets 99.99% (NFR-009), with supporting Azure service SLAs and architectural choices noted.", "rag_label": "GREEN", "rag_score": 5, "domain_slug": "nfr", "artifact_ref": "NFR_01_NFR_Requirements_and_Security_Controls.xlsx (NFR-007, NFR-008, NFR-009)", "principle_id": "HA-PRIN-001", "check_category": "HA_RESILIENCE"}, {"id": "NFR-F06", "kb_ref": "Enterprise Architecture Standards - Performance - Response Time", "finding": "Performance NFR-003 (Onboarding form submission P95 response time < 2000ms) and NFR-004 (KYC Tier-1 automated decision turnaround time < 30s) are not yet measured. Evidence states ''test not yet run'' and ''prod load test pending'', indicating these are not validated.", "rag_label": "AMBER", "rag_score": 3, "domain_slug": "nfr", "artifact_ref": "NFR_01_NFR_Requirements_and_Security_Controls.xlsx (NFR-003, NFR-004)", "principle_id": "PERF-PRIN-001", "check_category": "SCALABILITY_PERFORMANCE"}, {"id": "NFR-F07", "kb_ref": "Enterprise Architecture Standards - Secrets Management - Key Vault", "finding": "Secrets management is compliant. All secrets, API keys, and encryption keys are planned to be stored in Azure Key Vault Managed HSM, with RBAC-gated access and no secrets in code, as evidenced by SC-006.", "rag_label": "GREEN", "rag_score": 5, "domain_slug": "nfr", "artifact_ref": "NFR_01_NFR_Requirements_and_Security_Controls.xlsx (SC-006)", "principle_id": "SEC-PRIN-003", "check_category": "KEY_VAULT_SECRETS"}], "nfr_analysis": {"summary": {"average_score": 0, "total_criteria": 0, "compliant_count": 0}, "criteria": []}, "processed_at": "2026-04-28T12:26:45.179783+00:00", "domain_scores": {"nfr": 2, "data": 1, "general": 1, "business": 1, "devsecops": 2, "application": 1, "integration": 1, "infrastructure": 3}, "aggregate_score": 2, "recommendations": [{"id": "BUS-REC-01", "priority": "MEDIUM", "finding_ref": "BUS-F01", "recommendation": "While the Business Case document outlines strategic alignment, it could be enhanced by explicitly detailing the expected ROI and key performance indicators for the CLM Platform."}, {"id": "BUS-REC-02", "priority": "LOW", "finding_ref": "BUS-F02", "recommendation": "The Business NFRs Register is comprehensive, but the ''Evidence Source'' column for several NFRs is marked as ''In Design'' or ''Not Tested''. It is recommended to update this with concrete evidence as it becomes available."}, {"id": "BUS-REC-03", "priority": "HIGH", "finding_ref": "BUS-F03", "recommendation": "The Business Scope is not clearly defined. It is recommended to provide a dedicated artifact or section that explicitly outlines the boundaries of the CLM Platform, including what is in and out of scope."}, {"id": "BUS-REC-04", "priority": "MEDIUM", "finding_ref": "BUS-F04", "recommendation": "While key stakeholders are implied through roles in the NFRs, a formal stakeholder analysis or RACI matrix would provide clarity on responsibilities and engagement."}, {"id": "DSO-REC-01", "priority": "MEDIUM", "finding_ref": "DSO-F01", "recommendation": "The ''Build success rate'', ''Average build duration'', and ''PR cycle time'' metrics are ''NOT MEASURED''. These metrics are crucial for understanding and optimizing the CI/CD pipeline efficiency."}, {"id": "DSO-REC-02", "priority": "HIGH", "finding_ref": "DSO-F04", "recommendation": "While container security scans are planned, there are no results yet for critical vulnerabilities in base images. This needs to be actively monitored and addressed."}, {"id": "DSO-REC-03", "priority": "MEDIUM", "finding_ref": "DSO-F07", "recommendation": "DAST results for medium findings in staging are ''Not yet run''. While risks are accepted, active scanning and remediation are necessary."}, {"id": "DSO-REC-04", "priority": "HIGH", "finding_ref": "DSO-F08", "recommendation": "API contract tests are ''NOT STARTED'' as contracts are in draft. Establishing contract testing early is key to ensuring inter-service communication reliability."}, {"id": "DSO-REC-05", "priority": "MEDIUM", "finding_ref": "DSO-F09", "recommendation": "Regression automation coverage is ''NOT STARTED''. Automating regression tests is essential for maintaining software quality and enabling faster release cycles."}, {"id": "DSO-REC-06", "priority": "HIGH", "finding_ref": "DSO-F10", "recommendation": "Defect tracking metrics for ''Critical defects in backlog'' and ''High defects open at gono-go'' are ''NOT MEASURED''. These are critical for go-live decisions."}, {"id": "NFR-REC-01", "priority": "HIGH", "finding_ref": "NFR-F02", "recommendation": "Performance testing (Gatling load tests) is planned but not yet executed. Establish a baseline and validate performance targets before go-live."}, {"id": "NFR-REC-02", "priority": "MEDIUM", "finding_ref": "NFR-F03", "recommendation": "While AKS auto-scale is validated, the scalability NFR-001 for 5,000 concurrent users lacks a baseline. The Gatling load test should specifically validate this target."}, {"id": "NFR-REC-03", "priority": "MEDIUM", "finding_ref": "NFR-F05", "recommendation": "The performance target for the Staff Portal Customer 360 API response time (P95 < 1000ms) is noted, but the evidence link points to ''Cosmos DB indexed queries - Redis cache expected to meet SLA''. This needs to be validated through testing."}, {"id": "NFR-REC-04", "priority": "MEDIUM", "finding_ref": "NFR-F06", "recommendation": "The performance target for Banking Backend internal API (P95 < 500ms) is noted, but evidence states ''Microservice latency budgets defined; not yet validated''. This requires validation through testing."}]}}'::jsonb
);

-- DOMAIN_SCORES TABLE
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('ac8249db-70b3-4dad-ae03-1f95f7879e22', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'general', 1, '2026-04-28 12:26:45.204154+05:30');
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('3e522a80-0919-40dc-9776-ed65b833decb', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'application', 1, '2026-04-28 12:26:45.204162+05:30');
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('36db8f5e-b20c-47da-b08f-a0580be81d18', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'business', 1, '2026-04-28 12:26:45.204166+05:30');
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('2d31c750-6d27-4ce5-8b7b-280bc252a896', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'integration', 1, '2026-04-28 12:26:45.204169+05:30');
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('75485cdb-33c3-49f9-9943-59bfa91c3266', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'data', 1, '2026-04-28 12:26:45.204172+05:30');
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('8edda3a3-a88a-4719-80ab-b09abd855091', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'infrastructure', 3, '2026-04-28 12:26:45.204176+05:30');
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('7d320d9b-67ff-4908-a600-229e02d19b46', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'devsecops', 2, '2026-04-28 12:26:45.204179+05:30');
INSERT INTO domain_scores (id, review_id, domain, score, created_at)
VALUES ('8493af83-3a6a-4201-972e-59fabab238a2', '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1', 'nfr', 2, '2026-04-28 12:26:45.204182+05:30');

-- FINDINGS TABLE
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'b2e7085d-c873-48c3-8033-2793415fc54e',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for ARCHITECTURE_PRINCIPLES_ADHERENCE is missing. The SA document (APP_02_HLD_and_ADRs.docx) does not explicitly state adherence to enterprise architecture principles. No KB documents were provided for validation.',
  NULL,
  false,
  '2026-04-28 12:26:45.210137+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '361f9022-3ba6-4647-99ad-9671e39955f9',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for ECONOMICS_TCO is missing. The SA document (GEN_03_Standards_and_Policies_Doc.docx) does not contain any information regarding the Total Cost of Ownership (TCO) for the CLM Platform. No KB documents were provided for validation.',
  NULL,
  false,
  '2026-04-28 12:26:45.210143+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '556754b1-0e3e-4f8c-b910-9e00ed995621',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for END_USER_VOICE is missing. The SA document (APP_02_HLD_and_ADRs.docx) does not describe how end-user feedback or requirements have been incorporated into the architecture. No KB documents were provided for validation.',
  NULL,
  false,
  '2026-04-28 12:26:45.210147+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '471dee84-e33d-487a-bde4-6bc729575ba7',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for PROCESS_ADHERENCE is missing. The SA document (GEN_03_Standards_and_Policies_Doc.docx) does not detail how the solution adheres to established enterprise processes (e.g., development, deployment, security). No KB documents were provided for validation.',
  NULL,
  false,
  '2026-04-28 12:26:45.210150+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '7b9822fa-95cb-4593-b6e4-ca1584bf1a3d',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for STRATEGY_ALIGNMENT is missing. The SA document (APP_02_HLD_and_ADRs.docx) does not explicitly demonstrate how the CLM Platform aligns with the overall enterprise strategy. No KB documents were provided for validation.',
  NULL,
  false,
  '2026-04-28 12:26:45.210153+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '600d2407-6738-4c95-8935-ebecaaffec92',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for ARCHITECTURE_STYLE mandatory check is absent. The provided HLD mentions a cloud-native, API-led, microservices architecture but lacks specific details or adherence to enterprise standards.',
  NULL,
  false,
  '2026-04-28 12:26:45.210156+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '95f9bf27-2144-47ff-8e2a-a1a7cb3b8f4f',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for DOCUMENTATION_CURRENCY mandatory check is absent. The HLD document does not contain information regarding its currency or update process.',
  NULL,
  false,
  '2026-04-28 12:26:45.210159+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '3c7b9138-24d1-4990-9936-1c06ef99b21c',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for MONITORING_AND_ALERTING mandatory check is absent. No details regarding monitoring and alerting strategies for the CLM Platform are present in the submitted artifacts.',
  NULL,
  false,
  '2026-04-28 12:26:45.210162+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'b3672b1d-2f79-4bd7-a737-02a89d67fe01',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for RESILIENCE_PATTERNS mandatory check is absent. The submitted artifacts do not describe the resilience patterns implemented in the CLM Platform.',
  NULL,
  false,
  '2026-04-28 12:26:45.210170+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'ab72aea5-ee03-4850-a803-9732e2f42691',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for SBOM_AND_DEPENDENCY_HEALTH mandatory check is absent. There is no mention of SBOM generation or dependency health management for the CLM Platform.',
  NULL,
  false,
  '2026-04-28 12:26:45.210173+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'dc45d9fb-166b-44f5-ac80-e4d5a831bf6f',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for TECH_DEBT_TRACKING mandatory check is absent. The submitted artifacts do not include information on how technical debt is tracked or managed for the CLM Platform.',
  NULL,
  false,
  '2026-04-28 12:26:45.210176+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '118eab90-9c83-4827-a016-57be25e1c43a',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for VERSIONING_COMPATIBILITY mandatory check is absent. The artifacts do not describe the approach to versioning compatibility for the CLM Platform.',
  NULL,
  false,
  '2026-04-28 12:26:45.210179+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'ff3db04e-6930-42f7-a88e-90ca1ffcef3b',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'business',
NULL
  'minor',
  'The Business Case document (BUS_02_Business_Case_and_Problem_Statement.docx) outlines the strategic alignment and problem statement for the CLM Platform, directly addressing the need for digital transformation and regulatory compliance. However, specific ROI and detailed KPIs could be further elaborated.',
  NULL,
  false,
  '2026-04-28 12:26:45.210182+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '429e8f5b-c6eb-4722-991e-05de3a59dfb6',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'business',
NULL
  'minor',
  'The Business NFRs Register (BUS_01_Business_NFRs_Register.xlsx) is well-structured and covers a broad range of NFRs. However, many NFRs are marked as ''In Design'' or ''Not Tested'' with no concrete evidence provided, impacting the confidence in their current status.',
  NULL,
  false,
  '2026-04-28 12:26:45.210185+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'f79057ae-ed96-4436-aee0-7f458818b491',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'business',
NULL
  'critical',
  'Evidence for Business Scope is absent. The submitted artifacts do not contain a clear definition of the CLM Platform''s scope, boundaries, or key deliverables, making it difficult to assess the project''s focus and potential for scope creep.',
  NULL,
  false,
  '2026-04-28 12:26:45.210188+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '6f35eb5d-4a51-44f0-acba-67225f13f603',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'business',
NULL
  'minor',
  'Key stakeholders are mentioned implicitly through ownership of NFRs in BUS_01_Business_NFRs_Register.xlsx (e.g., Chief Compliance Officer, DPO, Product Owner). However, a formal stakeholder analysis or RACI matrix is missing, which would provide a clearer picture of stakeholder engagement and responsibilities.',
  NULL,
  false,
  '2026-04-28 12:26:45.210191+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '61f3d9da-5558-42a2-9868-77994e053414',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'business',
NULL
  'critical',
  'Evidence for Business Operations is absent. There are no artifacts submitted that describe the impact of the CLM Platform on current business operations, nor is there a plan for operational readiness, training, or ongoing support.',
  NULL,
  false,
  '2026-04-28 12:26:45.210194+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '847d4786-f1f2-402d-8aa3-76c2c871da76',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Evidence for API Design Standards cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_03_API_Interface_Catalog.docx'' mentions OpenAPI 3.0, versioning via URI, Bearer token validation at APIM, Idempotency-Key header, cursor-based pagination, RFC 7807 Problem Details, and rate limits, but without KB standards, these cannot be assessed for compliance.',
  NULL,
  false,
  '2026-04-28 12:26:45.210197+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'a6bdceff-8d77-4f21-afee-b2ee5e35ba57',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Evidence for Catalogue Completeness cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' provides an integration catalogue, but its completeness against enterprise standards cannot be verified without the relevant KB.',
  NULL,
  false,
  '2026-04-28 12:26:45.210200+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '0b0966c9-49a4-442b-91b2-c2c29cb91dcc',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Evidence for Idempotency cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' lists ''Idempotency'' as a column for several integrations (e.g., INT-001, INT-002, INT-003, INT-004, INT-005), and ''Idempotency-Key header mandatory'' is mentioned in ''APP_03_API_Interface_Catalog.docx'', but the specific enterprise standards for idempotency are not available for verification.',
  NULL,
  false,
  '2026-04-28 12:26:45.210203+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'f9048f7b-7958-4197-87da-deb2f8017e3f',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Evidence for Integration Security cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' details various security controls (e.g., OAuth 2.0, mTLS, TLS 1.3, WAF, client-generated correlation ID, Azure AD Bearer token, MFA), but compliance with enterprise security standards cannot be confirmed without the relevant KB.',
  NULL,
  false,
  '2026-04-28 12:26:45.210206+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'ddeadde5-abe8-4251-843f-3b1c620b64fa',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Evidence for NFR Coverage cannot be validated as there are no KB documents provided for the Integration Domain. The SA artifact ''APP_01_Integration_Catalogue_and_Tech_Debt.xlsx'' lists NFRs for various integrations (e.g., response time, availability), but their adequacy and adherence to enterprise standards cannot be assessed without the relevant KB.',
  NULL,
  false,
  '2026-04-28 12:26:45.210209+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '485a0e1a-9774-4cc0-9bba-5f4c67b4c7f2',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'The provided ''DAT_01_Data_Classification_Register.xlsx'' is incomplete. While it lists several data assets, a comprehensive classification for all data assets within the CLM Platform is not evident. Specifically, the ''Classification System'' and ''Store'' columns are often empty or ''NaN'', and the scope of ''all data assets'' is not clearly defined.',
  NULL,
  false,
  '2026-04-28 12:26:45.210212+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '735c2380-c99d-4d87-99cb-37bf88b44e09',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'The ''Data Retention & Deletion Schedule'' section in ''DAT_02_Data_Architecture_and_Governance.docx'' lists retention periods but lacks detail on the mechanisms for automated enforcement and auditing of these policies across all data stores. For example, ''SQL archival'' and ''Logical delete'' need further clarification on implementation and verification.',
  NULL,
  false,
  '2026-04-28 12:26:45.210215+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'b387030d-e14e-4daf-bd8e-683183bc3a3f',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'The ''DAT_02_Data_Architecture_and_Governance.docx'' mentions a canonical Customer entity and DDD principles but lacks detailed documentation for other data models within the CLM Platform. The ''Data Architecture Diagram'' and ''Data Flow Diagram'' are placeholders, and specific details on other bounded context data models are missing.',
  NULL,
  false,
  '2026-04-28 12:26:45.210218+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'a29d2efb-dfe3-4b5c-98c6-0bb75f3cc2a1',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'The ''EoSEoL Data Platform Assessment'' mentioned in ''DAT_02_Data_Architecture_and_Governance.docx'' is not elaborated upon. There is no evidence of a defined process or documentation for tracking End-of-Support (EOS) and End-of-Life (EOL) for the data platforms and services utilized by the CLM Platform.',
  NULL,
  false,
  '2026-04-28 12:26:45.210221+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'f572aa04-5a1e-4a00-a0ec-89bb756e5be9',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'major',
  'Several key CI/CD pipeline quality metrics (''Build success rate'', ''Average build duration'', ''PR cycle time'') are marked as ''NOT MEASURED'' and are associated with a ''new build pipeline''. Evidence of current measurement and targets is missing.',
  NULL,
  false,
  '2026-04-28 12:26:45.210224+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '179144ec-65fc-4a94-98cf-1a6dc939ec54',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'critical',
  'Unit test line coverage and branch coverage are ''NOT STARTED'' with ''0 (no tests written yet)''. This is a mandatory requirement and evidence of compliance is absent.',
  NULL,
  false,
  '2026-04-28 12:26:45.210227+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '037a0066-2117-4266-8dd9-23e42a115f8b',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'minor',
  'SAST tools (SonarQube) are integrated into the CI pipeline, with quality gates enforcing zero Blocker and Critical issues. Code duplication and technical debt ratio are being tracked.',
  NULL,
  false,
  '2026-04-28 12:26:45.210230+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '216de8dc-9635-4519-a4f1-90847a0542ac',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'minor',
  'Secrets are managed via Azure Key Vault, with references in all services. GitGuardian scans are clean, and pre-commit hooks are in place. Service account certificate rotation is configured.',
  NULL,
  false,
  '2026-04-28 12:26:45.210233+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '2a3de52d-6795-4e96-9060-128dfc16d1c2',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'critical',
  'Performance testing for API response times (onboarding, KYC check) and error rates under load are ''Not tested'' and ''NOT STARTED''. This is a mandatory requirement and evidence is absent.',
  NULL,
  false,
  '2026-04-28 12:26:45.210236+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '4efc8562-162c-4bcd-baf8-b9c62344eefc',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'minor',
  'DAST scanning is planned with OWASP ZAP for staging, but results are ''Not yet run''. Medium findings are noted with accepted risk, but active scanning and remediation evidence is missing.',
  NULL,
  false,
  '2026-04-28 12:26:45.210239+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '36dcd452-3e8a-4076-8093-16ade3da81b9',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'major',
  'Defect tracking metrics for ''Critical defects in backlog'' and ''High defects open at gono-go'' are ''NOT MEASURED''. While a zero-tolerance policy for critical defects is mentioned, current status and evidence are missing.',
  NULL,
  false,
  '2026-04-28 12:26:45.210242+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '6ad4b5a5-292d-4e92-8e87-e1e9c6639de8',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'minor',
  'Code review coverage is robust, with 100% of PRs reviewed by a minimum of two engineers, enforced via branch protection. EA architectural approval for design PRs is also enforced.',
  NULL,
  false,
  '2026-04-28 12:26:45.210245+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '21efa306-7723-4801-8cda-1a6345c6a753',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'minor',
  'Several SW quality metrics are in a ''NOT STARTED'' or ''NOT MEASURED'' state, including code duplication, technical debt ratio, security hotspot review completion, and API contract test pass rate. While plans are in place, current status and evidence are missing.',
  NULL,
  false,
  '2026-04-28 12:26:45.210248+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '79d0f320-27b6-450d-80b1-826225ad6c27',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'minor',
  'Most 12-Factor compliance items are met (''COMPLIANT''). However, ''Dev-Prod Parity'' is marked ''PARTIAL'' due to DEV using shared PaaS, which is noted as an acceptable gap.',
  NULL,
  false,
  '2026-04-28 12:26:45.210251+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'f0f0687b-aa86-4091-9a9b-6f14ff6d045e',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
  'SEC-PRIN-005'
  'critical',
  'Evidence for Vulnerability Assessment and Penetration Testing (VAPT) is missing. The SA submission states VAPT is ''Planned'' for Q3 2026, but no evidence of completed testing or interim validation is provided, failing the mandatory requirement.',
  NULL,
  false,
  '2026-04-28 12:26:45.210254+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'f0ce7a9d-d9e2-4045-b6ec-6bae7482be90',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
  'PERF-PRIN-002'
  'minor',
  'Performance testing is planned but not yet executed. The ''Performance Baseline Report'' indicates tests are targeted for May 2026, and ARB requires results before final sign-off. NFR-001, NFR-003, NFR-004, and NFR-005 all rely on these upcoming tests.',
  NULL,
  false,
  '2026-04-28 12:26:45.210257+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'b8ea9079-263d-44fb-b3f2-5247506de7eb',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
  'SCAL-PRIN-001'
  'minor',
  'Scalability NFR-001 (5,000 concurrent users) has a target but no established baseline. The evidence states ''Test planned 5-9 May 2026 in UAT environment'', indicating the requirement is not yet met.',
  NULL,
  false,
  '2026-04-28 12:26:45.210260+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'fab43c5c-812d-4563-9df4-e903f2d04e0c',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
  'DR-PRIN-003'
  'critical',
  'Disaster Recovery (DR) drill has not been performed. While RPO (15 mins) and RTO (4 hours) targets are defined, the evidence states ''DR drill not done'' and ''DR drill required before go-live'', failing the mandatory check.',
  NULL,
  false,
  '2026-04-28 12:26:45.210263+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'f0930e0f-8c21-46e2-a49c-5bff4ad80b82',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
  'HA-PRIN-001'
  'minor',
  'High Availability (HA) targets and design are well-defined and evidenced. Customer Portal targets 99.9% uptime (NFR-007), Banking Backend targets 99.99% (NFR-008), and APIM gateway targets 99.99% (NFR-009), with supporting Azure service SLAs and architectural choices noted.',
  NULL,
  false,
  '2026-04-28 12:26:45.210266+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '790f25ec-7449-4082-8121-5a4313e1ac87',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
  'PERF-PRIN-001'
  'minor',
  'Performance NFR-003 (Onboarding form submission P95 response time < 2000ms) and NFR-004 (KYC Tier-1 automated decision turnaround time < 30s) are not yet measured. Evidence states ''test not yet run'' and ''prod load test pending'', indicating these are not validated.',
  NULL,
  false,
  '2026-04-28 12:26:45.210269+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '32e08cb4-1137-4092-9af5-7c09467a8aca',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
  'SEC-PRIN-003'
  'minor',
  'Secrets management is compliant. All secrets, API keys, and encryption keys are planned to be stored in Azure Key Vault Managed HSM, with RBAC-gated access and no secrets in code, as evidenced by SC-006.',
  NULL,
  false,
  '2026-04-28 12:26:45.210272+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '610c7b39-2da5-4a90-b282-ebf081d58e9c',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for ARCHITECTURE_PRINCIPLES_ADHERENCE is missing. The SA document does not explicitly state adherence to enterprise architecture principles.',
  'Provide a section in the SA documentation explicitly detailing adherence to enterprise architecture principles, referencing specific principles and how the CLM Platform aligns.',
  false,
  '2026-04-28 12:26:45.210275+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '6e97a9be-c4b8-4c9f-bdae-c0bd6b54801d',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for ECONOMICS_TCO is missing. The SA document does not contain any information regarding the Total Cost of Ownership (TCO) for the CLM Platform.',
  'Include a TCO analysis in the SA documentation, outlining projected costs for development, deployment, and ongoing operations.',
  false,
  '2026-04-28 12:26:45.210278+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'b47d171d-e4a5-44ec-8ac2-3b0cb44e76d4',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for END_USER_VOICE is missing. The SA document does not describe how end-user feedback or requirements have been incorporated into the architecture.',
  'Document the process for incorporating end-user feedback and requirements into the CLM Platform architecture, including any user research or validation activities.',
  false,
  '2026-04-28 12:26:45.210281+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'e83a32e0-c09e-4b89-a88e-f141d1696df2',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for PROCESS_ADHERENCE is missing. The SA document does not detail how the solution adheres to established enterprise processes (e.g., development, deployment, security).',
  'Provide a section in the SA documentation that outlines adherence to key enterprise processes, specifying how each process is followed for the CLM Platform.',
  false,
  '2026-04-28 12:26:45.210284+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'a4b889dd-9d3d-4ad2-8708-0bd8f78eaf88',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'general',
NULL
  'critical',
  'Evidence for STRATEGY_ALIGNMENT is missing. The SA document does not explicitly demonstrate how the CLM Platform aligns with the overall enterprise strategy.',
  'Include a section in the SA documentation that clearly articulates the alignment of the CLM Platform with the enterprise''s strategic objectives.',
  false,
  '2026-04-28 12:26:45.210287+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '3460b901-699f-42f2-9b1e-0034edc40563',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for ARCHITECTURE_STYLE mandatory check is absent.',
  'Provide evidence or documentation detailing the architecture style and its adherence to enterprise standards.',
  false,
  '2026-04-28 12:26:45.210290+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '2794ec9a-a2da-4d4c-afe2-ba91fdefc2ba',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for DOCUMENTATION_CURRENCY mandatory check is absent.',
  'Provide evidence of documentation currency, such as version control, last updated dates, or a documented review process.',
  false,
  '2026-04-28 12:26:45.210293+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '60189109-0737-4b41-ab68-2e19bb3de329',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for MONITORING_AND_ALERTING mandatory check is absent.',
  'Provide documentation or evidence of the monitoring and alerting strategy for the CLM Platform.',
  false,
  '2026-04-28 12:26:45.210296+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'a7583465-9576-4415-96d2-8ccbd509f236',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for RESILIENCE_PATTERNS mandatory check is absent.',
  'Provide documentation or evidence detailing the resilience patterns implemented in the CLM Platform.',
  false,
  '2026-04-28 12:26:45.210299+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '0c140122-72b8-491e-ab8a-f2733b93edad',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for SBOM_AND_DEPENDENCY_HEALTH mandatory check is absent.',
  'Provide evidence of SBOM generation and dependency health checks for all components of the CLM Platform.',
  false,
  '2026-04-28 12:26:45.210302+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '5767689b-ac39-47d1-a360-30bff0ab4223',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for TECH_DEBT_TRACKING mandatory check is absent.',
  'Provide evidence of a process for tracking and managing technical debt within the CLM Platform.',
  false,
  '2026-04-28 12:26:45.210305+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'efc65888-f5e8-4f00-826f-ba4f10964bc3',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'application',
NULL
  'critical',
  'Evidence for VERSIONING_COMPATIBILITY mandatory check is absent.',
  'Provide evidence of the strategy for managing versioning compatibility across CLM Platform components and integrations.',
  false,
  '2026-04-28 12:26:45.210308+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '851df3b9-73f3-4866-a2cd-a4fa010ee594',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'business',
NULL
  'critical',
  'Evidence for Business Operations is missing. The SA submission does not contain any artifacts detailing how the business operations will be impacted or managed post-transformation.',
  'Provide documentation or artifacts that describe the impact on business operations and the plan for managing them.',
  false,
  '2026-04-28 12:26:45.210311+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '51d4d428-bf0c-4551-afa7-9efc3cef77c5',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for API Design Standards.',
  'Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines.',
  false,
  '2026-04-28 12:26:45.210314+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '5766b480-38ca-4084-a928-a8b07ea122a4',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for Catalogue Completeness.',
  'Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines.',
  false,
  '2026-04-28 12:26:45.210317+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '8054938f-bbb0-4f2d-8393-5e4be0aafe35',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for Idempotency.',
  'Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines.',
  false,
  '2026-04-28 12:26:45.210320+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '77ac9511-59ea-44df-83c0-cb5db34a6d25',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for Integration Security.',
  'Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines.',
  false,
  '2026-04-28 12:26:45.210323+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '458d3df2-2603-4bce-9bd6-71e7dcd7a5a8',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'integration',
NULL
  'critical',
  'Absence of Knowledge Base (KB) documentation for the Integration Domain prevents validation against enterprise architecture standards for NFR Coverage.',
  'Provide and populate the Integration Domain Knowledge Base with relevant standards and guidelines.',
  false,
  '2026-04-28 12:26:45.210326+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '53649b12-b727-4220-9725-84049189c2c4',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'Lack of detailed data classification evidence for all data assets. While some assets are classified, a comprehensive review and clear documentation for all are missing.',
  'Provide a complete data classification register for all data assets, detailing classification levels, ownership, and PII status, referencing the ''DAT_01_Data_Classification_Register.xlsx'' artifact.',
  false,
  '2026-04-28 12:26:45.210329+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '7f1ecda3-13fc-4c1d-b221-c896b62d5a86',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'Incomplete data lifecycle documentation. Retention periods and deletion mechanisms are listed, but a clear, auditable process for enforcing these across all data stores is not detailed.',
  'Document the end-to-end data lifecycle management process, including automated enforcement of retention and deletion policies, referencing ''DAT_02_Data_Architecture_and_Governance.docx''.',
  false,
  '2026-04-28 12:26:45.210331+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '59fab5a4-bc5a-4e92-9d4c-f74bb2219d7f',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'Insufficient data model documentation. While the canonical Customer entity is mentioned, detailed documentation for other domain-specific data models and their relationships is absent.',
  'Provide comprehensive data model documentation for all bounded contexts, including entity-relationship diagrams and attribute definitions, as referenced in ''DAT_02_Data_Architecture_and_Governance.docx''.',
  false,
  '2026-04-28 12:26:45.210334+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '8c604ad8-1eee-4ee7-b48f-b279985733ee',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'data',
NULL
  'critical',
  'Absence of explicit End-of-Support (EOS) and End-of-Life (EOL) tracking for data platforms and services. The ''EoSEoL Data Platform Assessment'' section in ''DAT_02_Data_Architecture_and_Governance.docx'' is not elaborated.',
  'Submit a detailed assessment and tracking plan for EOS/EOL for all data platforms and services used within the CLM Platform.',
  false,
  '2026-04-28 12:26:45.210337+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'ce927247-110b-469f-88fd-8a48fa851ceb',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'critical',
  'Code coverage metrics (unit test line coverage and branch coverage) are not yet measured, with tests not written. This is a mandatory requirement for demonstrating software quality.',
  'Implement unit and integration tests and establish CI gates for code coverage metrics.',
  false,
  '2026-04-28 12:26:45.210340+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '18521d67-e535-4236-b6f1-db1b3268e20a',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'devsecops',
NULL
  'critical',
  'Performance testing for API response times and error rates under load has not been conducted. This is a critical gap for ensuring the stability and reliability of the platform.',
  'Execute performance tests for critical APIs and document results, including response times and error rates under expected load.',
  false,
  '2026-04-28 12:26:45.210343+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  'a2b83479-efd8-4db8-aa20-dfed7a3c6439',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
NULL
  'critical',
  'VAPT evidence is missing. The SA submission indicates penetration testing is ''Planned'' for Q3 2026, but no evidence of current or completed VAPT activities is provided, which is a mandatory requirement.',
  'Provide evidence of completed VAPT or a detailed plan with interim milestones and a firm go-live commitment.',
  false,
  '2026-04-28 12:26:45.210346+05:30'
);
INSERT INTO findings (id, review_id, domain, principle_id, severity, finding, recommendation, is_resolved, created_at)
VALUES (
  '3c837b49-fd47-4b5c-b622-99c1f9da6cfc',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'nfr',
NULL
  'critical',
  'DR drill evidence is missing. While DR targets and procedures are documented, the actual DR drill has not been performed, and evidence is required before go-live.',
  'Conduct and document a DR drill, providing evidence of successful failover and adherence to RTO/RPO targets.',
  false,
  '2026-04-28 12:26:45.210349+05:30'
);

-- ADRS TABLE
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '0147b12a-a53f-4734-9aca-8a7f508a7f2e',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-GEN-01',
  'Microservices over Monolith for Banking Backend',
  'Chosen for flexibility, scalability, and independent deployment of services.',
  'The Banking Backend is a core component requiring agility.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220114+05:30',
  '2026-04-28 12:26:45.220115+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  'f9bfb2a8-d790-4264-904f-886c9a8f4d8d',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-GEN-02',
  'Event-Driven Integration via Azure Service Bus',
  'Enables loose coupling and asynchronous communication between microservices.',
  'Integration is a key aspect of the CLM Platform.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220119+05:30',
  '2026-04-28 12:26:45.220119+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '25f0979d-c46b-461e-b4f6-27eb8e28a7b7',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-GEN-03',
  'Azure API Management as Single API Gateway',
  'Provides a unified entry point for all APIs, enhancing security and manageability.',
  'Centralized API management is crucial for the CLM Platform.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220122+05:30',
  '2026-04-28 12:26:45.220123+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  'a12464a8-12b4-4053-966e-6ffc83c965a9',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-GEN-04',
  'Salesforce Financial Services Cloud (COTS over Custom Build)',
  'Leverages a proven COTS solution to accelerate delivery and reduce custom development effort.',
  'CRM functionality is a key part of the CLM Platform.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220126+05:30',
  '2026-04-28 12:26:45.220126+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '3efa8ab8-d06b-4f8c-8a19-5f657d20e56f',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-GEN-05',
  'Azure Synapse Analytics for Regulatory Reporting (over Self-Managed Spark)',
  'Utilizes a managed cloud service for analytics, simplifying operations and scaling.',
  'Regulatory reporting is a critical requirement.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220129+05:30',
  '2026-04-28 12:26:45.220129+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '5acf1c00-b65f-4fcf-ab93-c154097137e5',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-GEN-06',
  'React 18 - TypeScript SPA for Customer and Staff Portals',
  'Modern JavaScript framework for building responsive and maintainable user interfaces.',
  'User-facing portals are essential for the CLM Platform.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220132+05:30',
  '2026-04-28 12:26:45.220133+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '057f8209-d6a0-48c0-b00b-ae7a969ac2d6',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-APP-01',
  'Microservices over Monolith for Banking Backend',
  'Chosen for scalability, independent deployment, and technology diversity.',
  'The Banking Backend is a core component requiring high agility and independent scaling.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220136+05:30',
  '2026-04-28 12:26:45.220136+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  'fdbd5d8c-e596-487e-95af-a1522ed23d4e',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-APP-02',
  'Event-Driven Integration via Azure Service Bus',
  'Enables loose coupling, asynchronous communication, and improved resilience.',
  'Decoupling services within the CLM Platform and integrating with external systems.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220139+05:30',
  '2026-04-28 12:26:45.220139+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '61aa9b0a-0b86-4913-a09f-b2dff52df4bc',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-APP-03',
  'Azure API Management as Single API Gateway',
  'Provides a centralized point for API management, security, and monitoring.',
  'Exposing Banking Backend services to internal and external consumers.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220142+05:30',
  '2026-04-28 12:26:45.220142+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '1221d6ab-1028-4493-8004-26d7c40f9326',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-APP-04',
  'Salesforce Financial Services Cloud (COTS over Custom Build)',
  'Leverages industry-specific features and reduces development time and cost.',
  'Customer Relationship Management (CRM) functionality within the CLM Platform.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220145+05:30',
  '2026-04-28 12:26:45.220146+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  'aa827404-68ef-4660-a319-e35d6b621ea2',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-APP-05',
  'Azure Synapse Analytics for Regulatory Reporting (over Self-Managed Spark)',
  'Offers integrated data warehousing, big data analytics, and simplifies infrastructure management.',
  'Handling large volumes of data for regulatory reporting requirements.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220149+05:30',
  '2026-04-28 12:26:45.220149+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  'd560a4e0-4b99-4d48-8e7e-8056cfaa4568',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-APP-06',
  'React 18 - TypeScript SPA for Customer and Staff Portals',
  'Modern, performant framework with strong typing for building interactive user interfaces.',
  'Developing the user-facing portals for customer onboarding and staff interaction.',
  NULL,
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220152+05:30',
  '2026-04-28 12:26:45.220152+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '63fc5716-cc07-4669-a272-9e49cb38de0d',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-DSO-01',
  'Waiver for partial Dev-Prod Parity',
  'The development environment utilizes shared PaaS resources (e.g., SQL MI) instead of dedicated resources as in SIT, UAT, and Prod. This is a deviation from strict Dev-Prod Parity.',
  'This decision was made to optimize costs and resource utilization in the development environment during the initial phases of the project. Dedicated PaaS instances for development environments are planned for later stages.',
  'waiver_expiry_date: 2027-04-28',
  'solution_architect'
NULL
  'proposed',
  '2026-04-28 12:26:45.220155+05:30',
  '2026-04-28 12:26:45.220156+05:30'
);
INSERT INTO adrs (id, review_id, adr_id, decision, rationale, context, consequences, owner, target_date, status, created_at, updated_at)
VALUES (
  '608488ef-d2d6-40c6-a7ea-c55b61e64553',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'ADR-NFR-01',
  'Waiver for VAPT evidence prior to go-live',
  'Penetration testing is scheduled for Q3 2026, post-go-live. This waiver is requested due to the critical nature of the platform and the planned testing timeline.',
  'The solution is a new build and the VAPT is scheduled post-initial deployment.',
  'waiver_expiry_date: 2026-12-31',
  'Compliance Infosec'
NULL
  'proposed',
  '2026-04-28 12:26:45.220159+05:30',
  '2026-04-28 12:26:45.220159+05:30'
);

-- ACTIONS TABLE
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'd33d428c-875b-40ae-b8e9-056db5314602',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Update SA documentation to include a dedicated section on adherence to enterprise architecture principles, providing specific examples.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215725+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '020872e1-159a-4ed9-9998-f303edc539c6',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Develop and include a Total Cost of Ownership (TCO) analysis in the SA documentation.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215732+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '5ae022b3-708b-4f19-8eea-c880519d6ba8',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Document the process for incorporating end-user feedback and requirements into the CLM Platform architecture.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215735+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '7181f4f9-c777-4780-b191-f527a6835946',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Detail adherence to key enterprise processes within the SA documentation.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215739+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '1e06ae68-5cc1-4969-bdfa-5537a805b9a5',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Articulate the alignment of the CLM Platform with enterprise strategic objectives in the SA documentation.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215742+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '3c847c77-2fdf-4b22-9275-76d8c110e17b',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Provide detailed documentation on the CLM Platform''s architecture style, including patterns, technologies, and their alignment with enterprise standards.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215745+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '06687083-afc4-46cb-85f7-c33e211db688',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Establish and document a process for ensuring documentation currency, including version control and regular review cycles.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215749+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '0ec9751f-4723-4f97-aaf6-5c92338ca7b3',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Document the comprehensive monitoring and alerting strategy for the CLM Platform, covering key metrics, alert thresholds, and response procedures.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215752+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '8ff79a49-6870-4d8e-95f0-f774e639ebdd',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Detail the resilience patterns implemented within the CLM Platform, such as redundancy, failover, and disaster recovery mechanisms.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215755+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '831a9afd-e84b-443f-9305-1ae6fa4fbe25',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Implement and document the process for generating Software Bill of Materials (SBOM) and continuously monitoring the health of third-party dependencies.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215758+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'c2710cc2-3fe8-44a1-b713-78c5c9c7a561',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Define and implement a clear process for identifying, tracking, and prioritizing the remediation of technical debt within the CLM Platform.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215761+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '65477185-b0fd-4896-ac8e-8c99f035a7f8',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Document the strategy for managing versioning compatibility across all components and integrations of the CLM Platform.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215765+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'a99288d6-b4f5-41d4-b1e2-c44ead2284d7',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Update the ''Evidence Source'' column in the Business NFRs Register with specific evidence or status updates for NFRs currently marked as ''In Design'' or ''Not Tested''.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215768+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '65745546-21e7-4370-964f-beb5ee101070',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Create and submit a dedicated Business Scope document or add a section to an existing document clearly defining the in-scope and out-of-scope elements of the CLM Platform.',
  'open',
  'solution_architect'
  15,
  '2026-05-13'
  '2026-04-28 12:26:45.215771+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'ca2c4a3d-be7b-4417-874a-d6503007794d',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Develop and submit a stakeholder analysis or RACI matrix for the CLM Platform project.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215774+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '368877a7-b999-4c54-869a-5dca78cfb850',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Provide documentation detailing the impact on current business operations and a plan for operational readiness, including training and support for the CLM Platform.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215777+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '6f38b35c-cc31-4c9a-a1db-20fa509e251a',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Develop and populate the Integration Domain Knowledge Base with comprehensive API design standards, including but not limited to versioning strategies, authentication/authorization mechanisms, request/response formats, and error handling.',
  'open',
  'enterprise_architect'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215780+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'c5bf86e8-4ea2-4e82-ae12-078086c341d8',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Define and document the enterprise standards for integration catalogue completeness, including required fields, metadata, and governance processes.',
  'open',
  'enterprise_architect'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215784+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'bee34ba0-c47d-4877-8b83-91a1d879ebcc',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Establish and document enterprise-wide standards and best practices for ensuring idempotency in integrations, including guidance on idempotency keys and mechanisms.',
  'open',
  'enterprise_architect'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215787+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'a42ee554-302e-48e3-a372-df7b010d77f0',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Create and disseminate enterprise security standards for integrations, covering aspects like encryption, authentication protocols, authorization, and threat mitigation.',
  'open',
  'enterprise_architect'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215790+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '6c5f313a-f275-4875-87e2-cce23a7a6dc5',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Define and document enterprise Non-Functional Requirements (NFRs) coverage standards for integrations, including performance, availability, scalability, and reliability metrics.',
  'open',
  'enterprise_architect'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215793+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'cecbee91-00da-4a67-90da-54c27ad7e1b4',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Complete the Data Classification Register by filling in all missing details for each data asset, ensuring all columns are populated accurately.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215797+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '5499700a-f73f-4a75-86dc-ab87287e6209',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Detail the automated enforcement mechanisms for data retention and deletion policies, including audit trails, within the ''DAT_02_Data_Architecture_and_Governance.docx'' document.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215800+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '282785f0-56cb-45b0-b6df-fc48ca033b17',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Provide comprehensive data model documentation for all bounded contexts, including ERDs and attribute definitions, and replace placeholder diagrams in ''DAT_02_Data_Architecture_and_Governance.docx''.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215803+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '150ff762-1514-491d-9db0-6c287e9782c9',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Develop and document a formal process for tracking EOS/EOL for all data platforms and services, and include this in the ''DAT_02_Data_Architecture_and_Governance.docx''.',
  'open',
  'solution_architect'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215806+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'aeb7828b-86e6-4810-85ff-cfa04f80d96b',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Implement and report on ''Build success rate'', ''Average build duration'', and ''PR cycle time'' metrics. Ensure targets are defined and current values are tracked.',
  'open',
  'dev_team'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215809+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'ded410ce-de79-466b-a804-45a3630d091a',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Develop and execute unit and integration tests. Establish CI gates to enforce minimum code coverage targets (line and branch).',
  'open',
  'dev_team'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215812+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '01cf483f-ff2b-4816-983b-5aec0d63865b',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Execute performance tests for critical APIs (onboarding, KYC) under expected load. Document results including P95 response times and error rates.',
  'open',
  'dev_team'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215815+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '4c73da0d-c983-4345-b941-99fb0fa6d5fa',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Schedule and execute DAST scans in the staging environment. Review and address any medium or high findings, documenting accepted risks with owner sign-off.',
  'open',
  'security_team'
  45,
  '2026-06-12'
  '2026-04-28 12:26:45.215819+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '1b99c898-46e8-4bb7-8926-55845181715c',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Establish and report on defect tracking metrics for critical and high defects in the backlog and at go-no-go. Ensure evidence of current status is available.',
  'open',
  'dev_team'
  30,
  '2026-05-28'
  '2026-04-28 12:26:45.215822+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'ed59c871-4bf9-4864-8a9e-4e7f9407c774',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Implement and report on code duplication, technical debt ratio, security hotspot review completion, and API contract test pass rate metrics. Provide evidence of current status.',
  'open',
  'dev_team'
  45,
  '2026-06-12'
  '2026-04-28 12:26:45.215825+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '25943f3c-fa00-415b-b880-a82943c3a1fb',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Schedule and execute penetration testing. Provide a report detailing findings, remediation actions, and re-testing results.',
  'open',
  'security_team'
  90,
  '2026-07-27'
  '2026-04-28 12:26:45.215828+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '849b4061-336c-486e-a234-d786608d0b83',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Execute Gatling load tests in the UAT environment as planned (May 5-9, 2026) and document the results against the defined performance targets.',
  'open',
  'dev_team'
  15,
  '2026-05-13'
  '2026-04-28 12:26:45.215832+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'd12099b2-32ba-4741-a3fc-175de28d3f58',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Update NFR-001 evidence with results from the Gatling load test, specifically validating the support for 5,000 concurrent users without degradation.',
  'open',
  'dev_team'
  20,
  '2026-05-18'
  '2026-04-28 12:26:45.215835+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  'ad78c94d-197f-4e5b-87d6-73eb1585b7b1',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Schedule and execute a DR drill. Document the process, outcomes, and confirm adherence to RPO and RTO targets.',
  'open',
  'enterprise_architect'
  60,
  '2026-06-27'
  '2026-04-28 12:26:45.215838+05:30'
);
INSERT INTO actions (id, review_id, action_text, status, owner_role, due_days, due_date, created_at)
VALUES (
  '48512ced-e4cc-491f-8204-a6ddc7941055',
  '825ebd8f-c8db-4654-9b83-0ebca7ffd5e1',
  'Complete and document the Gatling load tests for NFR-003 (Onboarding form submission P95) and NFR-004 (KYC Tier-1 decision time).',
  'open',
  'dev_team'
  20,
  '2026-05-18'
  '2026-04-28 12:26:45.215841+05:30'
);