-- Migration 003: Seed MD Files
-- This migration seeds the md_files table with knowledge base documents
-- Note: Content field should be populated with actual MD file content from knowledge-base/

-- ============================================================================
-- INSERT MD FILES
-- ============================================================================

-- EA Principles (General domain)
INSERT INTO md_files (filename, storage_path, domain_tags, content, token_estimate, priority, file_size_bytes) VALUES
(
  'ea-principles.md',
  'knowledge-base/ea-principles.md',
  ARRAY['general', 'business', 'security', 'application', 'data', 'infrastructure', 'devsecops'],
  '# Enterprise Architecture Principles Knowledge Base

> **Purpose**: This document serves as the authoritative knowledge base of Enterprise Architecture (EA) principles used by the Pre-ARB AI Agent for compliance validation, alignment checks, and architecture review scoring. Each principle follows a structured format to enable precise LLM retrieval and assessment.
>
> **Structure per principle**: Statement · Rationale · Implications · Items to Verify in Review
>
> **Categories**: General · Business · Security · Application · Software · Data · Infrastructure

---

## CATEGORY 1: GENERAL PRINCIPLES

---

### G-01 — Focus On Customer

**Statement**
All architecture decisions must ultimately serve the end customer. Systems, platforms, and solutions should be designed with measurable customer outcomes as the primary success criterion.

**Rationale**
Technology exists to enable business value. Without a customer-centric lens, architecture risks becoming internally optimised but externally irrelevant. Aligning all design choices to customer needs ensures investment translates to tangible outcomes.

**Implications**
- Solution architects must articulate how the proposed change improves customer experience, reduces friction, or enables new customer capabilities.
- Trade-offs between internal efficiency and customer-facing quality should favour the customer unless a compelling case is made.
- KPIs and success metrics must include at least one customer-facing measurement (e.g. response time, availability, usability score).
- UX and accessibility requirements must be addressed during design, not as afterthoughts.

**Items to Verify in Review**
- [ ] Is there a documented customer problem statement or business use case driving this initiative?
- [ ] Are success metrics defined, including at least one customer-facing KPI?
- [ ] Has customer or end-user impact been assessed for any breaking changes or service degradation?
- [ ] Is the solution''s end-user experience (UX) considered in the architecture?
- [ ] Have support ticket trends or incident insights been reviewed to validate the problem being solved?

---

### G-02 — Bias For Action

**Statement**
Architecture should enable rapid, reversible decisions and iterative delivery. Prefer done-and-improvable over perfect-but-delayed, while maintaining safeguards for irreversible choices.

**Rationale**
Over-engineering and analysis paralysis slow delivery and reduce business agility. Architectures that support incremental delivery allow faster value realisation and course correction based on real feedback.

**Implications**
- Solutions should be decomposed into deliverable increments with clear transition states toward the target architecture.
- "Big bang" architecture changes must be justified; phased approaches are preferred.
- Reversible decisions (e.g. feature flags, blue-green deployments) should be preferred over irreversible ones.
- Teams must demonstrate a working architecture through prototypes or proofs-of-concept before full investment.

**Items to Verify in Review**
- [ ] Is a phased delivery plan with intermediate milestones documented?
- [ ] Are irreversible architectural decisions explicitly called out with documented rationale?
- [ ] Are there mechanisms for rollback or course correction (feature flags, versioned APIs, blue-green deployments)?
- [ ] Has the team validated key architectural assumptions through spikes or proofs-of-concept?
- [ ] Is the architecture roadmap aligned with the business delivery timeline?

[... Additional principles truncated for seed - full content should be loaded from knowledge-base/ea-principles.md]',
  15000,
  1,
  85700
) ON CONFLICT (filename) DO NOTHING;

-- EA Standards (Multiple domains)
INSERT INTO md_files (filename, storage_path, domain_tags, content, token_estimate, priority, file_size_bytes) VALUES
(
  'ea-standards.md',
  'knowledge-base/ea-standards.md',
  ARRAY['business', 'application', 'data', 'infrastructure'],
  '# Enterprise Architecture Standards Knowledge Base

> **Purpose**: This document serves as the authoritative standards reference for Enterprise Architecture (EA) used by the ARB AI Agent for compliance validation, architecture review scoring, and technical decision-making. Each standard provides specific, prescriptive requirements that must be followed.
>
> **Structure per standard**: Header · Purpose-Scope · The Standard · Rationale-Context · Compliance-Governance
>
> **Domains**: Business · Data · Application (+Software) · Technology (Cloud and On-prem Infrastructure and Platforms)

---

## DOMAIN 1: BUSINESS ARCHITECTURE STANDARDS

---

### B-STD-01 — Basel III Capital Adequacy Reporting

**Purpose-Scope**
This standard applies to all systems involved in capital adequacy calculations, risk-weighted asset (RWA) computations, and regulatory capital reporting for banking institutions. It ensures compliance with Basel III requirements for capital ratios, leverage ratios, and liquidity coverage ratios.

**The Standard**
- All capital adequacy calculations must use the Basel III standardized approach or internal models approved by the supervisory authority.
- Risk weight mappings must be centrally managed and version-controlled in the Risk Data Warehouse.
- Capital ratio calculations (CET1, Tier 1, Total Capital) must be automated with no manual intervention in the calculation logic.
- RWA calculations must be performed daily with automated reconciliation to the general ledger.
- Liquidity Coverage Ratio (LCR) and Net Stable Funding Ratio (NSFR) must be calculated and reported according to regulatory frequency requirements.
- All capital adequacy data must be retained for a minimum of 7 years in an immutable format.

[... Additional standards truncated for seed - full content should be loaded from knowledge-base/ea-standards.md]',
  10000,
  1,
  56279
) ON CONFLICT (filename) DO NOTHING;

-- Integration Principles
INSERT INTO md_files (filename, storage_path, domain_tags, content, token_estimate, priority, file_size_bytes) VALUES
(
  'integration-principles.md',
  'knowledge-base/integration-principles.md',
  ARRAY['integration'],
  '# Integration Architecture Principles

> **Purpose**: This document defines the principles for integration architecture, ensuring consistent, secure, and manageable integration patterns across the enterprise.

---

### I-01 — API-First Design

**Statement**
All integrations must be designed with APIs as the primary integration mechanism, prioritizing RESTful or GraphQL APIs over point-to-point connections.

**Rationale**
API-first design enables reuse, standardization, and easier testing. It decouples systems and allows for independent evolution.

[... Additional principles truncated for seed - full content should be loaded from knowledge-base/integration-principles.md]',
  8000,
  2,
  43050
) ON CONFLICT (filename) DO NOTHING;

-- Architecture Review Taxonomy
INSERT INTO md_files (filename, storage_path, domain_tags, content, token_estimate, priority, file_size_bytes) VALUES
(
  'architecture-review-taxonomy.md',
  'knowledge-base/architecture-review-taxonomy.md',
  ARRAY['general', 'nfr'],
  '# Architecture Review Taxonomy

> **Purpose**: This document defines the taxonomy and categorization used for architecture reviews.

---

## Review Categories
1. General Architecture
2. Business Architecture
3. Application Architecture
4. Integration Architecture
5. Data Architecture
6. Infrastructure Architecture
7. DevSecOps
8. Non-Functional Requirements

[... Additional content truncated for seed - full content should be loaded from knowledge-base/architecture-review-taxonomy.md]',
  1000,
  2,
  5570
) ON CONFLICT (filename) DO NOTHING;

-- ============================================================================
-- NOTE: The content field above contains truncated versions for the seed.
-- To populate with full content, run the sync-md-files Edge Function or
-- manually update the content field with the actual MD file content from
-- the knowledge-base/ folder.
-- ============================================================================
