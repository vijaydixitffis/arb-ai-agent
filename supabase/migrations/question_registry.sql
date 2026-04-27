-- ============================================================
-- QUESTION REGISTRY — DDL + FULL SEED DATA
-- All 130 checklist question codes from report-schema.json
-- Version : 1.0  |  Date: 2026-04-27
-- ============================================================
-- Column meanings at a glance:
--   question_code       — matches report_json checklist key (e.g. app-soft-3)
--   question_text       — human-readable question shown in UI and sent to LLM
--   frontend_tab        — which domain_data key the frontend stores this in
--   agent_domain        — which domain agent consumes this question
--   check_category      — validation bucket within the agent (maps to findings.check_category)
--   display_group       — sub-heading label within the frontend tab form
--   sort_order          — display order within the frontend tab
--   weight              — how the agent should calibrate severity
--   is_mandatory_green  — TRUE: non_compliant or not_answered = BLOCKER regardless of evidence
--   blank_nc_severity   — default severity when answer is non_compliant AND evidence is blank
--   na_permitted        — whether "na" is a valid answer (not all questions allow it)
--   is_active           — soft-delete flag; set FALSE to retire a question without data loss
-- ============================================================

BEGIN;

-- ============================================================
-- TABLE DEFINITION
-- ============================================================
CREATE TABLE IF NOT EXISTS public.question_registry (
  id                  serial        PRIMARY KEY,
  question_code       text          NOT NULL,
  question_text       text          NOT NULL,
  frontend_tab        text          NOT NULL,
  agent_domain        text          NOT NULL,
  check_category      text          NOT NULL,
  display_group       text          NOT NULL,
  sort_order          smallint      NOT NULL DEFAULT 99,
  weight              text          NOT NULL DEFAULT 'advisory',
  is_mandatory_green  boolean       NOT NULL DEFAULT false,
  blank_nc_severity   text          NOT NULL DEFAULT 'medium',
  na_permitted        boolean       NOT NULL DEFAULT true,
  hint_text           text,          -- optional tooltip shown in the UI form
  is_active           boolean       NOT NULL DEFAULT true,
  schema_version      text          NOT NULL DEFAULT '1.0',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  updated_at          timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT qr_code_version_unique UNIQUE (question_code, schema_version),

  CONSTRAINT qr_frontend_tab CHECK (frontend_tab = ANY(ARRAY[
    'general','business','application','integration',
    'data','infrastructure','devsecops','nfr'
  ])),
  CONSTRAINT qr_agent_domain CHECK (agent_domain = ANY(ARRAY[
    'general','business','application','software',
    'integration','api','security','data',
    'infra','devsecops','engg_quality','nfr'
  ])),
  CONSTRAINT qr_weight CHECK (weight = ANY(ARRAY[
    'mandatory_green','important','advisory'
  ])),
  CONSTRAINT qr_blank_nc_severity CHECK (blank_nc_severity = ANY(ARRAY[
    'blocker','high','medium','low','info'
  ]))
);

CREATE INDEX IF NOT EXISTS idx_qr_code        ON public.question_registry (question_code);
CREATE INDEX IF NOT EXISTS idx_qr_tab         ON public.question_registry (frontend_tab);
CREATE INDEX IF NOT EXISTS idx_qr_agent       ON public.question_registry (agent_domain);
CREATE INDEX IF NOT EXISTS idx_qr_category    ON public.question_registry (check_category);
CREATE INDEX IF NOT EXISTS idx_qr_mandatory   ON public.question_registry (is_mandatory_green) WHERE is_mandatory_green = true;
CREATE INDEX IF NOT EXISTS idx_qr_active      ON public.question_registry (is_active) WHERE is_active = true;

CREATE OR REPLACE TRIGGER trg_qr_updated_at
  BEFORE UPDATE ON public.question_registry
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SEED DATA — all 130 questions
-- Columns: question_code, question_text, frontend_tab,
--          agent_domain, check_category, display_group,
--          sort_order, weight, is_mandatory_green,
--          blank_nc_severity, na_permitted, hint_text
-- ============================================================
INSERT INTO public.question_registry
  (question_code, question_text, frontend_tab, agent_domain, check_category,
   display_group, sort_order, weight, is_mandatory_green, blank_nc_severity,
   na_permitted, hint_text)
VALUES

-- ════════════════════════════════════════════════════════════
-- TAB: general  |  AGENT: general
-- ════════════════════════════════════════════════════════════
('gen-doc-1',  'Adherence to architecture principles documented?',
  'general','general','ARCHITECTURE_PRINCIPLES_ADHERENCE',
  'Documentation',1,'advisory',false,'medium',false,
  'Confirm principles from Confluence are referenced in the solution HLD'),

('gen-doc-2',  'Adherence to patterns, standards and policies documented?',
  'general','general','ARCHITECTURE_PRINCIPLES_ADHERENCE',
  'Documentation',2,'advisory',false,'medium',false,
  'List deviations explicitly; these will need ADRs or waivers'),

('gen-doc-3',  'Level of documentation adequate for ARB review?',
  'general','general','ARCHITECTURE_PRINCIPLES_ADHERENCE',
  'Documentation',3,'advisory',false,'medium',false,
  'Minimum: HLD, ADRs, integration catalogue, runbook'),

('gen-eco-1',  'Total cost of ownership (3yr/5yr) calculated?',
  'general','general','ECONOMICS_TCO',
  'Economics',4,'advisory',false,'low',true,
  'Include dev, maintenance, ops, infra, licence and support costs'),

('gen-eco-2',  'Budget alignment verified?',
  'general','general','ECONOMICS_TCO',
  'Economics',5,'advisory',false,'low',true,NULL),

('gen-eco-3',  'Opportunities for cost optimisation identified?',
  'general','general','ECONOMICS_TCO',
  'Economics',6,'advisory',false,'low',true,NULL),

('gen-euv-1',  'Top 10 end-user concerns / issues identified?',
  'general','general','END_USER_VOICE',
  'End User Voice',7,'advisory',false,'low',true,
  'Pull from support tickets, incident logs or user surveys'),

('gen-euv-2',  'End-user wish list and usability aspirations documented?',
  'general','general','END_USER_VOICE',
  'End User Voice',8,'advisory',false,'low',true,NULL),

('gen-euv-3',  'Support tickets and incidents analysed for patterns?',
  'general','general','END_USER_VOICE',
  'End User Voice',9,'advisory',false,'low',true,NULL),

('gen-proc-1', 'Adherence to PtX / EARR process verified?',
  'general','general','PROCESS_ADHERENCE',
  'Process Adherence',10,'advisory',false,'medium',false,NULL),

('gen-proc-2', 'RAID logs and decision logs maintained?',
  'general','general','PROCESS_ADHERENCE',
  'Process Adherence',11,'advisory',false,'medium',false,NULL),

('gen-proc-3', 'Roadmap alignment verified?',
  'general','general','PROCESS_ADHERENCE',
  'Process Adherence',12,'advisory',false,'medium',false,NULL),

('gen-proc-4', 'Consolidation, federation and standardisation considered?',
  'general','general','PROCESS_ADHERENCE',
  'Process Adherence',13,'advisory',false,'low',true,NULL),

('gen-strat-1','Change in business priority assessed?',
  'general','general','STRATEGY_ALIGNMENT',
  'Strategy Impact',14,'advisory',false,'medium',false,NULL),

('gen-strat-2','Change in business model considered?',
  'general','general','STRATEGY_ALIGNMENT',
  'Strategy Impact',15,'advisory',false,'medium',false,NULL),

('gen-strat-3','Change in target operating model evaluated?',
  'general','general','STRATEGY_ALIGNMENT',
  'Strategy Impact',16,'advisory',false,'medium',false,NULL),

('gen-strat-4','Alignment to target architecture / roadmap verified?',
  'general','general','STRATEGY_ALIGNMENT',
  'Strategy Impact',17,'important',false,'medium',false,NULL),

-- ════════════════════════════════════════════════════════════
-- TAB: business  |  AGENT: business
-- ════════════════════════════════════════════════════════════
('bus-what-1','Business use cases and capabilities impacted documented?',
  'business','business','BUSINESS_SCOPE',
  'What',1,'important',false,'medium',false,NULL),

('bus-what-2','Growth and change plans defined?',
  'business','business','BUSINESS_SCOPE',
  'What',2,'important',false,'medium',false,
  'Include YoY volume projections and any business model changes'),

('bus-what-3','Domain model established?',
  'business','business','BUSINESS_SCOPE',
  'What',3,'advisory',false,'medium',false,NULL),

('bus-what-4','Service / contract / functions documented?',
  'business','business','BUSINESS_SCOPE',
  'What',4,'advisory',false,'medium',false,NULL),

('bus-why-1', 'Justification for this capability / app / service documented?',
  'business','business','BUSINESS_CASE',
  'Why',5,'important',false,'medium',false,NULL),

('bus-why-2', 'Entry and exit criteria for business functions defined?',
  'business','business','BUSINESS_CASE',
  'Why',6,'advisory',false,'low',true,NULL),

('bus-why-3', 'Business case documented and current?',
  'business','business','BUSINESS_CASE',
  'Why',7,'important',false,'medium',false,NULL),

('bus-why-4', 'Product lifecycle and roadmap alignment verified?',
  'business','business','BUSINESS_CASE',
  'Why',8,'advisory',false,'medium',false,NULL),

('bus-who-1', 'Actors, users, systems and entities identified?',
  'business','business','BUSINESS_STAKEHOLDERS',
  'Who',9,'advisory',false,'medium',false,NULL),

('bus-who-2', 'Roles and user groups documented?',
  'business','business','BUSINESS_STAKEHOLDERS',
  'Who',10,'advisory',false,'medium',false,NULL),

('bus-who-3', 'Multi-timezone requirements considered?',
  'business','business','BUSINESS_STAKEHOLDERS',
  'Who',11,'advisory',false,'low',true,NULL),

('bus-who-4', 'Multilingual support requirements considered?',
  'business','business','BUSINESS_STAKEHOLDERS',
  'Who',12,'advisory',false,'low',true,NULL),

('bus-who-5', 'Multi-currency requirements considered?',
  'business','business','BUSINESS_STAKEHOLDERS',
  'Who',13,'advisory',false,'low',true,NULL),

('bus-nfr-1', 'Security — password policy, expiry, resets, lockout specs defined?',
  'business','business','BUSINESS_NFRS',
  'Business NFRs',14,'advisory',false,'medium',false,NULL),

('bus-nfr-2', 'Performance and scalability business metrics defined?',
  'business','business','BUSINESS_NFRS',
  'Business NFRs',15,'advisory',false,'medium',false,NULL),

('bus-nfr-3', 'Business continuity plan established?',
  'business','business','BUSINESS_NFRS',
  'Business NFRs',16,'important',false,'medium',false,NULL),

('bus-nfr-4', 'Analytics and monetisation requirements considered?',
  'business','business','BUSINESS_NFRS',
  'Business NFRs',17,'advisory',false,'low',true,NULL),

('bus-oth-1', 'Operation time requirements defined (24/7, weekdays, etc.)?',
  'business','business','BUSINESS_OPERATIONS',
  'Operations',18,'advisory',false,'low',true,NULL),

('bus-oth-2', 'Business change management plan established?',
  'business','business','BUSINESS_OPERATIONS',
  'Operations',19,'advisory',false,'low',true,NULL),

('bus-oth-3', 'Target operating model defined?',
  'business','business','BUSINESS_OPERATIONS',
  'Operations',20,'advisory',false,'medium',false,NULL),

('bus-oth-4', 'Continuity plan documented?',
  'business','business','BUSINESS_OPERATIONS',
  'Operations',21,'advisory',false,'medium',false,NULL),

('bus-oth-5', 'Reporting and monetisation strategy defined?',
  'business','business','BUSINESS_OPERATIONS',
  'Operations',22,'advisory',false,'low',true,NULL),

-- ════════════════════════════════════════════════════════════
-- TAB: application  |  AGENTS: application + software
-- ════════════════════════════════════════════════════════════

-- Agent: application — metadata, lifecycle, observability
('app-meta-1','COTS / Bespoke / Legacy classification documented?',
  'application','application','TECH_STACK_COMPLIANCE',
  'Metadata & Lifecycle',1,'advisory',false,'medium',false,NULL),

('app-meta-2','Monolith / Microservices architecture style defined?',
  'application','application','ARCHITECTURE_STYLE',
  'Metadata & Lifecycle',2,'advisory',false,'medium',false,NULL),

('app-meta-3','Full technology stack documented?',
  'application','application','TECH_STACK_COMPLIANCE',
  'Metadata & Lifecycle',3,'important',false,'high',false,NULL),

('app-meta-4','Technology debt identified and tracked?',
  'application','application','TECH_DEBT_TRACKING',
  'Metadata & Lifecycle',4,'advisory',false,'medium',false,NULL),

('app-meta-5','SW and platform upgrade plan documented?',
  'application','application','SBOM_AND_DEPENDENCY_HEALTH',
  'Metadata & Lifecycle',5,'important',false,'high',false,NULL),

('app-meta-6','Dependent library End-of-Support (EoS) dates tracked?',
  'application','application','SBOM_AND_DEPENDENCY_HEALTH',
  'Metadata & Lifecycle',6,'important',false,'high',false,
  'Flag any libraries with EoS within 12 months; set eos_risk_flag=true'),

('app-meta-7','EoL / EoS / licence expiry dates documented?',
  'application','application','SBOM_AND_DEPENDENCY_HEALTH',
  'Metadata & Lifecycle',7,'important',false,'high',false,NULL),

('app-oth-1', 'Usability metrics defined?',
  'application','application','DOCUMENTATION_CURRENCY',
  'Other',8,'advisory',false,'low',true,NULL),

('app-oth-2', 'Audit trail and logging implemented?',
  'application','application','MONITORING_AND_ALERTING',
  'Other',9,'important',false,'high',false,NULL),

('app-oth-3', 'Monitoring and alerting configured?',
  'application','application','MONITORING_AND_ALERTING',
  'Other',10,'important',false,'high',false,NULL),

('app-oth-4', 'TCO calculated (3yr / 5yr)?',
  'application','application','TECH_STACK_COMPLIANCE',
  'Other',11,'advisory',false,'low',true,NULL),

('app-oth-5', 'Integrations QoS (quality of service) defined?',
  'application','application','TECH_STACK_COMPLIANCE',
  'Other',12,'advisory',false,'medium',false,NULL),

('app-oth-6', 'Distributed cache architecture required and documented?',
  'application','application','ARCHITECTURE_STYLE',
  'Other',13,'advisory',false,'medium',true,
  'Answer na if stateless; justify in evidence field'),

('app-oth-7', 'Notifications and events architecture implemented?',
  'application','application','ARCHITECTURE_STYLE',
  'Other',14,'advisory',false,'low',true,NULL),

('app-oth-8', 'Scheduled jobs and batch processes documented?',
  'application','application','TECH_STACK_COMPLIANCE',
  'Other',15,'advisory',false,'low',true,NULL),

-- Agent: software — resilience, versioning, documentation
('app-soft-1','Technology choices align to approved standards; SBOM present?',
  'application','software','TECH_STACK_COMPLIANCE',
  'Software Architecture',16,'important',false,'high',false,NULL),

('app-soft-2','Versioning and backward compatibility policy; ADRs documented?',
  'application','software','VERSIONING_COMPATIBILITY',
  'Software Architecture',17,'important',false,'medium',false,NULL),

('app-soft-3','Resilience patterns applied: timeouts, retries, circuit breakers, idempotency?',
  'application','software','RESILIENCE_PATTERNS',
  'Software Architecture',18,'important',false,'high',false,
  'Evidence should reference HLD section showing pattern implementation'),

('app-soft-4','Documentation current: diagrams, ADRs, runbooks, ownership established?',
  'application','software','DOCUMENTATION_CURRENCY',
  'Software Architecture',19,'advisory',false,'medium',false,NULL),

-- ════════════════════════════════════════════════════════════
-- TAB: integration  |  AGENTS: integration + api
-- ════════════════════════════════════════════════════════════

-- Agent: integration — catalogue completeness, NFRs per integration
('int-cat-1', 'Integration catalogue documents SR, Provider, Consumer for all integrations?',
  'integration','integration','CATALOGUE_COMPLETENESS',
  'Catalogue',1,'important',false,'high',false,
  'Every integration row must have SR, provider, consumer, pattern and data flow'),

('int-cat-2', 'Pattern, Type and Method defined (API / File / MSG / Event)?',
  'integration','integration','CATALOGUE_COMPLETENESS',
  'Catalogue',2,'important',false,'high',false,NULL),

('int-cat-3', 'Interaction style specified (Async / Batch / Sync / Real-time)?',
  'integration','integration','CATALOGUE_COMPLETENESS',
  'Catalogue',3,'important',false,'medium',false,NULL),

('int-cat-4', 'Integration frequency documented?',
  'integration','integration','CATALOGUE_COMPLETENESS',
  'Catalogue',4,'advisory',false,'medium',false,NULL),

('int-cat-5', 'Data flows described for each integration?',
  'integration','integration','CATALOGUE_COMPLETENESS',
  'Catalogue',5,'important',false,'medium',false,NULL),

('int-nfr-1', 'Scalability requirements defined per integration?',
  'integration','integration','NFR_COVERAGE',
  'Integration NFRs',6,'advisory',false,'medium',false,NULL),

('int-nfr-2', 'Security requirements specified per integration?',
  'integration','integration','INTEGRATION_SECURITY',
  'Integration NFRs',7,'important',false,'high',false,NULL),

('int-nfr-3', 'Performance metrics defined per integration?',
  'integration','integration','NFR_COVERAGE',
  'Integration NFRs',8,'advisory',false,'medium',false,NULL),

('int-nfr-4', 'Bandwidth requirements documented?',
  'integration','integration','NFR_COVERAGE',
  'Integration NFRs',9,'advisory',false,'low',true,NULL),

('int-nfr-5', 'HA and redundancy requirements considered per integration?',
  'integration','integration','NFR_COVERAGE',
  'Integration NFRs',10,'important',false,'medium',false,NULL),

('int-nfr-6', 'DR requirements specified per integration?',
  'integration','integration','NFR_COVERAGE',
  'Integration NFRs',11,'important',false,'medium',false,NULL),

-- Agent: api — API design quality
('int-check-1','Interface catalogue covers Events, SLAs and API versioning?',
  'integration','api','CATALOGUE_COMPLETENESS',
  'API Design',12,'important',false,'high',false,NULL),

('int-check-2','Consistent API design: resource modelling, errors, pagination, filtering?',
  'integration','api','API_DESIGN_STANDARDS',
  'API Design',13,'important',false,'high',false,
  'Reference API Standards v3.1 — resource naming, HTTP verbs, error codes'),

('int-check-3','Event schemas, registry and compatibility rules documented?',
  'integration','api','API_DESIGN_STANDARDS',
  'API Design',14,'important',false,'medium',false,NULL),

('int-check-4','Reliability controls: idempotency, throttling and rate limiting implemented?',
  'integration','api','IDEMPOTENCY',
  'API Design',15,'important',false,'high',false,NULL),

-- ════════════════════════════════════════════════════════════
-- TAB: data  |  AGENT: data
-- ════════════════════════════════════════════════════════════
('data-meta-1','Data classification and ownership documented?',
  'data','data','DATA_CLASSIFICATION',
  'Data Governance',1,'important',false,'high',false,NULL),

('data-meta-2','Data usage and management roles & responsibilities defined?',
  'data','data','DATA_CLASSIFICATION',
  'Data Governance',2,'advisory',false,'medium',false,NULL),

('data-meta-3','Data lifecycle policy established (retention, archival, deletion)?',
  'data','data','DATA_LIFECYCLE',
  'Data Governance',3,'important',false,'medium',false,NULL),

('data-meta-4','Data sources and data model documentation maintained?',
  'data','data','DATA_MODEL_DOCUMENTATION',
  'Data Governance',4,'important',false,'medium',false,NULL),

('data-meta-5','Data technology stack documented?',
  'data','data','DATA_MODEL_DOCUMENTATION',
  'Data Governance',5,'advisory',false,'medium',false,NULL),

('data-meta-6','EoS / EoL / version upgrades for data platforms tracked?',
  'data','data','EOS_EOL_TRACKING',
  'Data Governance',6,'important',false,'high',false,NULL),

-- ════════════════════════════════════════════════════════════
-- TAB: infrastructure  |  AGENTS: infra + security (infra-sec-*)
-- ════════════════════════════════════════════════════════════

-- Agent: infra — environment, capacity, IaC
('infra-meta-1','Adequacy of environments, platforms and runtimes assessed?',
  'infrastructure','infra','ENVIRONMENT_ADEQUACY',
  'Metadata & Lifecycle',1,'important',false,'high',false,NULL),

('infra-meta-2','Platform upgrades, EoS and EoL tracked?',
  'infrastructure','infra','PLATFORM_LIFECYCLE',
  'Metadata & Lifecycle',2,'important',false,'high',false,NULL),

('infra-meta-3','Demand, capacity and YoY growth requirements documented?',
  'infrastructure','infra','CAPACITY_PLANNING',
  'Metadata & Lifecycle',3,'important',false,'high',false,NULL),

('infra-meta-4','Bandwidth adequacy verified for compute, storage and network?',
  'infrastructure','infra','CAPACITY_PLANNING',
  'Metadata & Lifecycle',4,'important',false,'medium',false,NULL),

('infra-oth-1', 'Automation and IaC implemented?',
  'infrastructure','infra','IAC_MATURITY',
  'Other',5,'important',false,'medium',false,NULL),

('infra-oth-2', 'Audit trail and logging configured?',
  'infrastructure','infra','OBSERVABILITY',
  'Other',6,'important',false,'high',false,NULL),

('infra-oth-3', 'Monitoring and alerts set up?',
  'infrastructure','infra','OBSERVABILITY',
  'Other',7,'important',false,'high',false,NULL),

('infra-oth-4', 'TCO 3yr / 5yr calculated?',
  'infrastructure','infra','CAPACITY_PLANNING',
  'Other',8,'advisory',false,'low',true,NULL),

('infra-oth-5', 'Integrations QoS defined at infra level?',
  'infrastructure','infra','ENVIRONMENT_ADEQUACY',
  'Other',9,'advisory',false,'medium',false,NULL),

('infra-oth-6', 'Distributed cache architecture required and documented?',
  'infrastructure','infra','ENVIRONMENT_ADEQUACY',
  'Other',10,'advisory',false,'medium',true,NULL),

('infra-oth-7', 'Notifications and events infrastructure implemented?',
  'infrastructure','infra','ENVIRONMENT_ADEQUACY',
  'Other',11,'advisory',false,'low',true,NULL),

('infra-oth-8', 'Scheduled jobs and batch infrastructure documented?',
  'infrastructure','infra','ENVIRONMENT_ADEQUACY',
  'Other',12,'advisory',false,'low',true,NULL),

-- Agent: security — infra-sec questions are security domain
('infra-sec-1', 'Authentication and AuthZ implemented at infra level?',
  'infrastructure','security','AUTHN_AUTHZ',
  'Infra Security',13,'mandatory_green',true,'blocker',false,
  'Includes network-level AuthZ, service mesh mTLS, ingress authentication'),

('infra-sec-2', 'RBAC configured at infra / platform level?',
  'infrastructure','security','RBAC_IAM',
  'Infra Security',14,'mandatory_green',true,'blocker',false,NULL),

('infra-sec-3', 'Key Vault used for secrets at infra level?',
  'infrastructure','security','KEY_VAULT_SECRETS',
  'Infra Security',15,'mandatory_green',true,'blocker',false,NULL),

('infra-sec-4', 'PKI / Encryption implemented (TLS, data at rest)?',
  'infrastructure','security','PKI_ENCRYPTION',
  'Infra Security',16,'mandatory_green',true,'blocker',false,NULL),

('infra-sec-5', 'Certificate lifecycle managed?',
  'infrastructure','security','PKI_ENCRYPTION',
  'Infra Security',17,'mandatory_green',true,'blocker',false,NULL),

('infra-sec-6', 'VAPT and endpoint protection in place at infra level?',
  'infrastructure','security','VAPT_EVIDENCE',
  'Infra Security',18,'mandatory_green',true,'blocker',false,
  'Must include evidence of most recent VAPT test date'),

('infra-sec-7', 'Standards and legal compliance verified at infra level?',
  'infrastructure','security','REGULATORY_COMPLIANCE',
  'Infra Security',19,'mandatory_green',true,'blocker',false,NULL),

('infra-sec-8', 'Integration security implemented at infra level?',
  'infrastructure','security','AUTHN_AUTHZ',
  'Infra Security',20,'mandatory_green',true,'blocker',false,NULL),

-- ════════════════════════════════════════════════════════════
-- TAB: devsecops  |  AGENTS: devsecops + engg_quality
-- ════════════════════════════════════════════════════════════

-- Agent: devsecops
('devops-1',  '12-Factor App compliance verified?',
  'devsecops','devsecops','TWELVE_FACTOR_COMPLIANCE',
  'DevOps',1,'important',false,'medium',false,NULL),

('devops-2',  'Version control and branching strategy defined?',
  'devsecops','devsecops','BRANCHING_STRATEGY',
  'DevOps',2,'important',false,'medium',false,NULL),

('devops-3',  'CI/CD pipeline and toolset established?',
  'devsecops','devsecops','CICD_PIPELINE_QUALITY',
  'DevOps',3,'important',false,'high',false,NULL),

('devops-4',  'Identity access management configured in pipeline?',
  'devsecops','devsecops','SECRETS_CONFIG_MGMT',
  'DevOps',4,'important',false,'high',false,NULL),

('devops-5',  'Secrets and config management implemented (no secrets in code)?',
  'devsecops','devsecops','SECRETS_CONFIG_MGMT',
  'DevOps',5,'important',false,'high',false,
  'Evidence: Key Vault / external secrets operator in pipeline config'),

('devops-6',  'Build and packaging automated?',
  'devsecops','devsecops','CICD_PIPELINE_QUALITY',
  'DevOps',6,'advisory',false,'medium',false,NULL),

('devops-7',  'Deployment strategy and release management defined?',
  'devsecops','devsecops','DEPLOYMENT_STRATEGY',
  'DevOps',7,'important',false,'medium',false,
  'Blue/green, canary or rolling; rollback capability documented'),

('devops-8',  'Templatisation and IaC implemented?',
  'devsecops','devsecops','CICD_PIPELINE_QUALITY',
  'DevOps',8,'important',false,'medium',false,NULL),

-- SecOps questions (agent: devsecops)
('secops-1',  'Threat models and mitigations documented?',
  'devsecops','devsecops','SAST_INTEGRATION',
  'SecOps',9,'important',false,'high',false,NULL),

('secops-2',  'Secure code reviews conducted?',
  'devsecops','devsecops','SAST_INTEGRATION',
  'SecOps',10,'important',false,'high',false,NULL),

('secops-3',  'SAST (static analysis) integrated in CI/CD pipeline?',
  'devsecops','devsecops','SAST_INTEGRATION',
  'SecOps',11,'important',false,'high',false,
  'Evidence: SAST tool name, threshold config and most recent scan pass'),

('secops-4',  'DAST (dynamic analysis) implemented?',
  'devsecops','devsecops','DAST_RESULTS',
  'SecOps',12,'important',false,'high',false,NULL),

('secops-5',  'VAPT completed for this application?',
  'devsecops','devsecops','DAST_RESULTS',
  'SecOps',13,'important',false,'high',false,
  'Application-level VAPT; not the same as infra-level VAPT in infra-sec-6'),

('secops-6',  'Environment hardening applied (OS, container, cluster)?',
  'devsecops','devsecops','DAST_RESULTS',
  'SecOps',14,'important',false,'high',false,NULL),

('secops-7',  'Software hardening implemented (SBOM, dependency pinning)?',
  'devsecops','devsecops','SAST_INTEGRATION',
  'SecOps',15,'important',false,'medium',false,NULL),

('secops-8',  'Security metrics reporting in place?',
  'devsecops','devsecops','SAST_INTEGRATION',
  'SecOps',16,'advisory',false,'low',false,NULL),

-- Agent: engg_quality — engineering excellence questions (engex-*)
('engex-1',   'Static code analysis results available and within threshold?',
  'devsecops','engg_quality','SW_QUALITY_METRICS',
  'Engineering Excellence',17,'important',false,'high',false,NULL),

('engex-2',   'LLD (low-level design) reviews conducted?',
  'devsecops','engg_quality','CODE_REVIEW_COVERAGE',
  'Engineering Excellence',18,'advisory',false,'medium',false,NULL),

('engex-3',   'Code reviews mandatory and enforced?',
  'devsecops','engg_quality','CODE_REVIEW_COVERAGE',
  'Engineering Excellence',19,'important',false,'high',false,NULL),

('engex-4',   'Test plan reviews completed?',
  'devsecops','engg_quality','TEST_COVERAGE',
  'Engineering Excellence',20,'advisory',false,'medium',false,NULL),

('engex-5',   'Defect tracking metrics defined and monitored?',
  'devsecops','engg_quality','DEFECT_METRICS',
  'Engineering Excellence',21,'advisory',false,'medium',false,NULL),

('engex-6',   'Automation testing implemented and results available?',
  'devsecops','engg_quality','TEST_COVERAGE',
  'Engineering Excellence',22,'important',false,'medium',false,NULL),

('engex-7',   'API testing conducted?',
  'devsecops','engg_quality','TEST_COVERAGE',
  'Engineering Excellence',23,'advisory',false,'medium',false,NULL),

('engex-8',   'Performance testing completed and baseline documented?',
  'devsecops','engg_quality','PERFORMANCE_TEST_RESULTS',
  'Engineering Excellence',24,'important',false,'high',false,
  'Results must be less than 90 days old; flag if older'),

('engex-9',   'SW quality metrics reporting in place?',
  'devsecops','engg_quality','SW_QUALITY_METRICS',
  'Engineering Excellence',25,'advisory',false,'low',false,NULL),

-- ════════════════════════════════════════════════════════════
-- TAB: nfr  |  AGENTS: security (nfr-sec-*) + nfr (all others)
-- ════════════════════════════════════════════════════════════

-- HA / Resilience — agent: nfr
('nfr-ha-1',    'Single points of failure (SPOF) identified and mitigated?',
  'nfr','nfr','HA_RESILIENCE',
  'HA & Resilience',1,'important',false,'high',false,NULL),

('nfr-ha-2',    'HA target tier defined (Four 9s / Five 9s)?',
  'nfr','nfr','HA_RESILIENCE',
  'HA & Resilience',2,'important',false,'high',false,NULL),

('nfr-ha-3',    'Failover mechanism defined and tested?',
  'nfr','nfr','HA_RESILIENCE',
  'HA & Resilience',3,'important',false,'high',false,NULL),

('nfr-ha-4',    'DR strategy, RPO and RTO documented?',
  'nfr','nfr','DR',
  'HA & Resilience',4,'important',false,'high',false,
  'DR is mandatory-green for full approval; flag separately in nfr_scorecard'),

('nfr-ha-5',    'Error handling strategy implemented?',
  'nfr','nfr','HA_RESILIENCE',
  'HA & Resilience',5,'important',false,'medium',false,NULL),

('nfr-ha-6',    'Self-healing capabilities implemented?',
  'nfr','nfr','HA_RESILIENCE',
  'HA & Resilience',6,'advisory',false,'medium',true,NULL),

('nfr-ha-7',    'Cache synchronisation strategy configured?',
  'nfr','nfr','HA_RESILIENCE',
  'HA & Resilience',7,'advisory',false,'low',true,NULL),

('nfr-ha-8',    'Reliability, extensibility and maintainability considered?',
  'nfr','nfr','HA_RESILIENCE',
  'HA & Resilience',8,'advisory',false,'medium',false,NULL),

-- Scalability — agent: nfr
('nfr-scalar-1','Number of users and YoY growth documented?',
  'nfr','nfr','SCALABILITY_PERFORMANCE',
  'Scalability & Performance',9,'important',false,'high',false,NULL),

('nfr-scalar-2','Concurrent user count defined?',
  'nfr','nfr','SCALABILITY_PERFORMANCE',
  'Scalability & Performance',10,'important',false,'high',false,NULL),

('nfr-scalar-3','TPS / API calls per unit of time specified?',
  'nfr','nfr','SCALABILITY_PERFORMANCE',
  'Scalability & Performance',11,'important',false,'high',false,NULL),

('nfr-scalar-4','Response time target < 3 seconds defined and evidenced?',
  'nfr','nfr','SCALABILITY_PERFORMANCE',
  'Scalability & Performance',12,'important',false,'high',false,NULL),

('nfr-scalar-5','Long-running use cases identified and catered for?',
  'nfr','nfr','SCALABILITY_PERFORMANCE',
  'Scalability & Performance',13,'advisory',false,'medium',true,NULL),

('nfr-scalar-6','Batch and scheduled jobs — peak and off-peak load considered?',
  'nfr','nfr','SCALABILITY_PERFORMANCE',
  'Scalability & Performance',14,'advisory',false,'medium',true,NULL),

-- Security NFRs — agent: security  (MANDATORY GREEN)
('nfr-sec-1',   'Authentication and authorisation scheme implemented?',
  'nfr','security','AUTHN_AUTHZ',
  'Security NFRs',15,'mandatory_green',true,'blocker',false,NULL),

('nfr-sec-2',   'RBAC / IAM model configured?',
  'nfr','security','RBAC_IAM',
  'Security NFRs',16,'mandatory_green',true,'blocker',false,NULL),

('nfr-sec-3',   'Key Vault used for all application secrets?',
  'nfr','security','KEY_VAULT_SECRETS',
  'Security NFRs',17,'mandatory_green',true,'blocker',false,NULL),

('nfr-sec-4',   'PKI / Encryption implemented (at rest and in transit)?',
  'nfr','security','PKI_ENCRYPTION',
  'Security NFRs',18,'mandatory_green',true,'blocker',false,NULL),

('nfr-sec-5',   'Certificate management in place?',
  'nfr','security','PKI_ENCRYPTION',
  'Security NFRs',19,'mandatory_green',true,'blocker',false,NULL),

('nfr-sec-6',   'VAPT and endpoint protection evidence submitted?',
  'nfr','security','VAPT_EVIDENCE',
  'Security NFRs',20,'mandatory_green',true,'blocker',false,
  'Blank evidence with non_compliant is an automatic BLOCKER'),

('nfr-sec-7',   'Standards and legal compliance verified?',
  'nfr','security','REGULATORY_COMPLIANCE',
  'Security NFRs',21,'mandatory_green',true,'blocker',false,NULL),

('nfr-sec-8',   'Integration security controls implemented?',
  'nfr','security','AUTHN_AUTHZ',
  'Security NFRs',22,'mandatory_green',true,'blocker',false,NULL)

ON CONFLICT (question_code, schema_version) DO NOTHING;

-- ============================================================
-- WHAT TO DO WITH EXISTING CHECKLIST DATA
-- ============================================================
-- The stored report_json.form_data.domain_data.*.checklist
-- objects are key → answer pairs, e.g.:
--   { "app-soft-3": "non_compliant", "app-soft-3_evidence": "" }
-- They need NO migration — they stay exactly as-is.
-- The question_registry is looked up JOIN-free at context-
-- build time by the backend; the stored answers are enriched
-- server-side before the LLM call. See CONTEXT BUILDER notes.
--
-- For HISTORICAL reviews already submitted before this
-- registry existed, the context builder will still enrich
-- them correctly because all question codes are stable.
-- The only reviews that cannot be re-assessed are those
-- where the SA never answered a now-mandatory question —
-- those will show as "not_answered" and the agent will
-- flag them as findings at the appropriate severity.
-- ============================================================

COMMIT;
