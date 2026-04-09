# Enterprise Architecture Principles Knowledge Base

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
- [ ] Is the solution's end-user experience (UX) considered in the architecture?
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

---

### G-03 — Think Globally, Act Locally

**Statement**
Solutions must be designed in the context of the broader enterprise architecture landscape, while being implemented in a way that is practical for the local domain or platform.

**Rationale**
Local optimisations without global awareness lead to duplication, fragmentation, and integration debt. Conversely, global mandates without local pragmatism stall delivery. Balance is essential.

**Implications**
- All solutions must be reviewed against the enterprise platform map and integration catalogue to identify overlaps, redundancies, or reuse opportunities.
- Local deviations from enterprise standards must be explicitly justified and time-bound.
- Shared services and platforms must be preferred over bespoke local implementations where equivalent capability exists.
- Cross-platform impact must always be assessed.

**Items to Verify in Review**
- [ ] Has the solution been reviewed against the enterprise capability map for duplication or reuse?
- [ ] Are any deviations from enterprise standards documented with rationale and a remediation timeline?
- [ ] Has cross-platform and downstream consumer impact been assessed?
- [ ] Does the solution contribute to or consume from shared platforms appropriately?
- [ ] Is the solution aligned with the enterprise north star / target architecture?

---

### G-04 — Design For Reliability

**Statement**
Every system must be designed with reliability as a first-class concern. Reliability includes availability, recoverability, fault tolerance, and predictable performance under normal and adverse conditions.

**Rationale**
Unreliable systems erode customer trust, generate operational overhead, and create financial and reputational risk. Reliability must be engineered in, not bolted on.

**Implications**
- All solutions must define and evidence HA targets (e.g. 99.9%, 99.99%), DR objectives (RPO, RTO), and failure mode analysis.
- Single points of failure must be identified and eliminated or mitigated.
- Circuit breakers, retries with backoff, timeouts, and graceful degradation patterns must be applied.
- Chaos engineering or fault injection testing must be considered for critical platforms.

**Items to Verify in Review**
- [ ] Are HA targets (Four Nines / Five Nines) defined and evidenced?
- [ ] Are RPO and RTO objectives documented and tested?
- [ ] Has a single point of failure (SPOF) analysis been conducted?
- [ ] Are resilience patterns (circuit breakers, retries, timeouts, bulkheads) implemented?
- [ ] Is there a DR test plan and evidence of recent DR test execution?
- [ ] Are SLOs and error budgets defined and monitored?

---

### G-05 — Treat Data As An Asset

**Statement**
Data is a strategic enterprise asset that must be governed, protected, and made accessible in a controlled manner. Every solution must demonstrate responsible stewardship of the data it creates, consumes, or transforms.

**Rationale**
Ungoverned data leads to inconsistency, regulatory risk, and inability to derive business insight. Treating data as an asset requires deliberate lifecycle management, quality standards, and clear ownership.

**Implications**
- All data entities must have documented ownership, classification, and lifecycle policies.
- Data sharing must be managed through approved interfaces (APIs, events, data products) — never direct database access across domain boundaries.
- Data quality standards must be defined and monitored.
- Data lineage must be traceable from source to consumption.

**Items to Verify in Review**
- [ ] Are data entities classified (Public, Internal, Confidential, Restricted)?
- [ ] Are data owners and stewards identified?
- [ ] Is data shared only via approved interfaces (API, event, data product)?
- [ ] Is data lineage documented and traceable?
- [ ] Are data retention and disposal policies defined and applied?
- [ ] Is master data management (MDM) strategy addressed where applicable?

---

### G-06 — Secure From Start

**Statement**
Security must be embedded into the architecture from the earliest design stage, not added after delivery. Every solution must adopt a "shift-left" security posture across all architecture domains.

**Rationale**
Retrofitting security is exponentially more expensive and risky than designing it in. Security vulnerabilities discovered post-deployment cause regulatory penalties, data breaches, and loss of customer trust.

**Implications**
- Threat modelling must be performed during design.
- All solutions must comply with enterprise security standards (AuthN/AuthZ, encryption, key management, VAPT).
- Security gates must be embedded in the CI/CD pipeline (SAST, DAST, SCA).
- Security is a blocking criterion for ARB approval — a Red security score cannot be waived.

**Items to Verify in Review**
- [ ] Has a threat model been documented and reviewed?
- [ ] Are authentication and authorisation mechanisms compliant with enterprise standards (OAuth 2.0, RBAC, OIDC)?
- [ ] Is data encrypted in transit (TLS 1.2+) and at rest?
- [ ] Are secrets managed via approved vaults (no hardcoded credentials)?
- [ ] Are SAST/DAST/SCA gates integrated into the CI/CD pipeline with passing results?
- [ ] Is VAPT evidence available and current (within 12 months)?
- [ ] Are regulatory and legal compliance requirements (GDPR, SOX, etc.) addressed?

---

### G-07 — Reuse, Buy Needed, Build For Competition

**Statement**
Before building custom solutions, teams must evaluate reuse of existing enterprise capabilities, then procurement of commercial products, and only build bespoke when neither option meets the need or when building delivers strategic differentiation.

**Rationale**
Custom build is expensive to develop and maintain. Reuse and buy strategies reduce time-to-market, lower total cost of ownership, and leverage enterprise investment. Bespoke build should be reserved for capabilities that differentiate BNY in the market.

**Implications**
- A documented build-vs-buy-vs-reuse analysis must accompany all significant new capability proposals.
- Platform and shared service catalogues must be consulted before any new capability is funded.
- Third-party products must be evaluated for vendor health, EoS/EoL roadmap, licensing, and integration fit.
- Custom builds must have a clear strategic justification linking to competitive advantage.

**Items to Verify in Review**
- [ ] Is a build-vs-buy-vs-reuse analysis documented?
- [ ] Has the enterprise capability catalogue been reviewed for existing solutions?
- [ ] If buying, has vendor assessment (EoS, licensing, support, integration) been conducted?
- [ ] If building, is the strategic differentiation rationale documented?
- [ ] Are all third-party dependencies listed in the SBOM with version, license, and EoS dates?

---

### G-08 — Drive For Ease of Use

**Statement**
Systems must be designed for ease of use for all consumers — end users, developers, and operations teams. Complexity must be hidden behind simple, well-designed interfaces.

**Rationale**
Difficult-to-use systems are adopted reluctantly, used incorrectly, and generate support overhead. Ease of use drives adoption, reduces errors, and lowers operational cost.

**Implications**
- APIs must be designed following consumer-centric design principles (resource-oriented, consistent naming, versioned, well-documented).
- Developer experience (DX) must be considered for platform APIs — onboarding docs and conformance tests are mandatory.
- Operational runbooks and self-service tooling must be provided.
- Usability metrics must be defined and monitored.

**Items to Verify in Review**
- [ ] Are APIs designed following enterprise API design standards (resource-oriented, versioned, consistent)?
- [ ] Is API documentation complete, accurate, and published to the enterprise catalogue?
- [ ] Are onboarding guides and conformance tests available for consuming teams?
- [ ] Are operational runbooks and self-service tooling provided?
- [ ] Are usability and developer experience metrics defined?

---

### G-09 — Engineer Solution With Strong Design Foundations

**Statement**
All solutions must be built on proven architectural patterns, sound engineering principles, and documented design decisions. Ad-hoc or undocumented architectural choices are not acceptable.

**Rationale**
Poor foundations lead to technical debt, fragility, and high cost of change. Strong design foundations reduce long-term maintenance burden and enable future evolution.

**Implications**
- Architecture Decision Records (ADRs) must be created for all significant decisions.
- Approved patterns from the enterprise pattern library must be applied wherever applicable.
- Documentation currency (diagrams, ADRs, runbooks) must be maintained and kept up to date.
- Technical debt must be explicitly identified, tracked, and have a remediation plan.

**Items to Verify in Review**
- [ ] Are ADRs created for all significant architectural decisions?
- [ ] Are enterprise-approved patterns applied and referenced?
- [ ] Are architecture diagrams (context, component, sequence, data flow) current and accurate?
- [ ] Is technical debt explicitly inventoried with a remediation plan and target dates?
- [ ] Is documentation ownership established and a refresh cadence defined?

---

### G-10 — Anticipate And Plan For Change

**Statement**
Architecture must accommodate future change. Systems should be designed with extensibility, configurability, and evolvability as core qualities so that future business and technology changes do not require wholesale rearchitecting.

**Rationale**
Business requirements, technology choices, and regulatory landscapes change continuously. Brittle architectures that cannot absorb change become liabilities.

**Implications**
- Systems must support versioning and backward compatibility for all interfaces.
- Configuration must be externalised and environment-agnostic.
- Dependency on specific infrastructure or vendor technology must be minimised through abstraction layers.
- A technology roadmap including EoS/EoL dates for all components must be maintained.

**Items to Verify in Review**
- [ ] Are all interfaces versioned with backward compatibility policies documented?
- [ ] Is configuration externalised (no hardcoded environment values)?
- [ ] Are EoS/EoL dates tracked for all platform dependencies, libraries, and infrastructure?
- [ ] Is there a technology refresh roadmap?
- [ ] Is the solution designed to absorb regulatory or business model changes without full rearchitecting?

---

## CATEGORY 2: BUSINESS PRINCIPLES

---

### B-01 — Customer-Centricity

**Statement**
Business architecture must be driven by deep understanding of customer needs, journeys, and outcomes. Every capability, process, and system must be traceable back to customer value.

**Rationale**
Customer-centric organisations outperform competitors on retention, satisfaction, and revenue growth. Architecture that is not rooted in customer insight risks misallocating investment.

**Implications**
- Customer journey maps must inform capability design.
- Business use cases must be validated against real customer needs or market research.
- End-user voices (support tickets, usability feedback, NPS) must be considered as inputs to architecture decisions.
- Metrics must include customer satisfaction and business outcome measures.

**Items to Verify in Review**
- [ ] Is the customer journey and impacted user population documented?
- [ ] Are customer feedback channels (support, NPS, usability testing) referenced in the business case?
- [ ] Are business use cases validated against actual customer needs?
- [ ] Do success metrics include customer-facing KPIs?

---

### B-02 — Regulatory Compliance

**Statement**
All business processes, data handling, and technology solutions must comply with applicable regulatory, legal, and internal policy requirements by design, not by exception.

**Rationale**
Non-compliance exposes the organisation to financial penalties, reputational damage, and operational restrictions. Compliance must be proactively engineered, not reactively applied.

**Implications**
- Regulatory requirements (GDPR, SOX, MiFID II, Basel III, etc.) must be identified and mapped to architecture controls at design time.
- Compliance evidence must be continuously generated and audit-ready.
- Legal and compliance teams must be engaged for any capability handling regulated data or processes.
- Regulatory change management must be a defined part of the architecture lifecycle.

**Items to Verify in Review**
- [ ] Are applicable regulatory frameworks identified and documented?
- [ ] Are regulatory controls mapped to architecture components?
- [ ] Is compliance evidence (audit logs, access controls, data handling records) generated and accessible?
- [ ] Has legal and compliance sign-off been obtained where required?
- [ ] Is there a process for incorporating regulatory changes into the architecture?

---

### B-03 — Operational Efficiency

**Statement**
Architecture must reduce operational overhead, automate manual processes, and optimise total cost of ownership (TCO). Efficiency gains must be measurable.

**Rationale**
Inefficient operations increase cost, introduce errors, and divert resources from innovation. Architecture plays a key role in enabling operational excellence through automation, standardisation, and self-service.

**Implications**
- Automation must be applied to repetitive operational tasks (deployment, testing, monitoring, scaling).
- TCO analysis (development, operations, support, licensing) must accompany significant investment decisions.
- Shared services and platform investments must demonstrate economies of scale.
- Operational runbooks must exist and be kept current.

**Items to Verify in Review**
- [ ] Is a TCO analysis (3-year or 5-year) documented?
- [ ] Are manual operational processes identified and automation plans defined?
- [ ] Are monitoring, alerting, and self-healing capabilities in place?
- [ ] Is the solution aligned with shared platform services to avoid duplication of operational overhead?
- [ ] Are operational runbooks available and maintained?

---

### B-04 — Agility and Flexibility

**Statement**
Business and technology architecture must be flexible enough to support rapid changes in business strategy, operating model, and market conditions without requiring full system replacement.

**Rationale**
Markets and business priorities change rapidly. Rigid architectures cannot adapt without significant cost and delay. Agility is a structural property that must be designed in.

**Implications**
- Loosely coupled, modular architectures are preferred over tightly integrated monoliths.
- Business rules and configuration must be externalised to allow change without code deployment.
- Interfaces must be stable and versioned to allow independent evolution of components.
- Teams must be empowered to deploy independently without coordinating with other teams.

**Items to Verify in Review**
- [ ] Is the architecture sufficiently decoupled to allow independent component evolution?
- [ ] Are business rules and configuration externalised?
- [ ] Are interfaces stable and versioned to support independent deployment?
- [ ] Can teams deploy components independently?
- [ ] Is there evidence of architecture adaptability (e.g., how a past business change was absorbed)?

---

### B-05 — Risk Management

**Statement**
Architecture must identify, assess, and mitigate risks across all dimensions — technology, security, operational, regulatory, and vendor. Risk must be a first-class concern, not an afterthought.

**Rationale**
Unmanaged architectural risk becomes operational incidents, regulatory failures, or strategic misalignment. Proactive risk identification and mitigation is cheaper than reactive remediation.

**Implications**
- A RAID log (Risks, Assumptions, Issues, Dependencies) must be maintained for all significant initiatives.
- Risk decisions must be documented in ADRs with accepted risk, mitigations, and owners.
- High-severity risks (security, DR, regulatory) require documented mitigation and sign-off before approval.
- Risk appetite must be explicitly stated for decisions involving trade-offs.

**Items to Verify in Review**
- [ ] Is a RAID log maintained and current?
- [ ] Are significant risks documented in ADRs with mitigations and owners?
- [ ] Are high-severity risks (security, DR, regulatory) explicitly signed off?
- [ ] Is risk appetite documented for key architectural trade-offs?
- [ ] Are vendor and third-party risks assessed (concentration risk, EoS, support SLAs)?

---

### B-06 — Data-Driven Decision Making

**Statement**
Architectural and business decisions must be supported by data and evidence. Anecdote, assumption, and intuition are insufficient justification for significant investment or change.

**Rationale**
Evidence-based decisions reduce the likelihood of costly mistakes and improve accountability. Data-driven architectures also enable continuous learning and improvement.

**Implications**
- Business cases must be supported by quantitative evidence (usage data, cost data, performance benchmarks).
- Architecture reviews must be evidence-based — promises of future compliance are insufficient.
- Observability must be built into solutions to generate the data needed for future decisions.
- A/B testing and experimentation capabilities should be considered for customer-facing features.

**Items to Verify in Review**
- [ ] Is the business case supported by quantitative data?
- [ ] Is NFR evidence based on actual measurements, not estimates?
- [ ] Are observability capabilities (metrics, logs, traces) built into the solution?
- [ ] Is there a defined mechanism for collecting post-deployment performance data?
- [ ] Are decisions made in the review based on evidence, not promises?

---

### B-07 — Innovation

**Statement**
Architecture must enable and accelerate innovation by providing a stable platform foundation on which new capabilities can be rapidly built, tested, and deployed.

**Rationale**
Innovation drives competitive advantage. Architectures that are too rigid, complex, or costly to change inhibit innovation. The platform must be an enabler, not a barrier.

**Implications**
- Platform teams must publish stable, well-documented APIs and event streams that enable consuming teams to innovate independently.
- Sandbox and non-production environments must be available for experimentation.
- Proof-of-concept and innovation governance must be lightweight and time-boxed.
- Emerging technology adoption must be governed through the enterprise technology radar.

**Items to Verify in Review**
- [ ] Does the solution expose stable interfaces enabling downstream innovation?
- [ ] Are sandbox/experimentation environments available?
- [ ] Is the technology choice aligned with the enterprise technology radar?
- [ ] Is the solution designed to accommodate future capability extensions without rearchitecting?

---

### B-08 — Collaboration and Integration

**Statement**
Architecture must promote collaboration across business domains, technology teams, and external partners through well-defined integration patterns and shared platforms.

**Rationale**
Siloed architectures create duplication, integration debt, and poor cross-domain experience. Collaboration architectures enable ecosystem thinking and shared value creation.

**Implications**
- All inter-domain integrations must be catalogued and use approved integration patterns.
- Shared data and event platforms must be preferred over point-to-point integrations.
- Consumer teams must be engaged during platform design (shift-left consumer involvement).
- Cross-team architectural decisions must follow the governance process with documented outcomes.

**Items to Verify in Review**
- [ ] Are all integrations catalogued with provider, consumer, pattern, frequency, and data flows documented?
- [ ] Are approved integration patterns (API, event, file, message) applied?
- [ ] Have consuming teams been engaged in the design process?
- [ ] Are shared platforms used in preference to point-to-point integrations?
- [ ] Is there a cross-team governance process for shared interface changes?

---

### B-09 — Customer Privacy

**Statement**
Customer personal data must be handled with the highest standards of privacy, consent, and transparency. Privacy must be designed into every system that collects, stores, processes, or transmits personal data.

**Rationale**
Privacy is both a regulatory requirement and a competitive differentiator. Customers expect organisations to handle their data responsibly. Privacy failures erode trust and attract regulatory action.

**Implications**
- Privacy Impact Assessments (PIAs) must be conducted for any system handling personal data.
- Data minimisation principles must be applied — collect only what is needed, retain only as long as required.
- Consent mechanisms must be implemented where required by regulation.
- Data subject rights (access, correction, deletion) must be supported by the architecture.

**Items to Verify in Review**
- [ ] Has a Privacy Impact Assessment (PIA) been conducted?
- [ ] Is personal data minimised (collect only what is necessary)?
- [ ] Are retention and disposal policies defined and enforced?
- [ ] Are data subject rights (DSAR, right to erasure) supported?
- [ ] Are consent mechanisms implemented where required?
- [ ] Is personal data isolated from non-personal data where possible?

---

### B-10 — Sustainability

**Statement**
Architecture must consider environmental sustainability by optimising resource consumption, minimising waste, and preferring energy-efficient technology choices.

**Rationale**
Sustainable architecture reduces environmental impact, lowers operational cost, and meets growing regulatory and investor expectations around ESG (Environmental, Social, Governance).

**Implications**
- Cloud resource utilisation must be optimised (right-sizing, auto-scaling, spot instances).
- Redundant or idle resources must be decommissioned.
- Technology choices must consider energy efficiency (e.g., serverless, managed services).
- Sustainability metrics (carbon footprint, energy usage) should be tracked for significant platforms.

**Items to Verify in Review**
- [ ] Is cloud resource utilisation optimised (right-sizing, auto-scaling)?
- [ ] Are idle or redundant resources identified for decommission?
- [ ] Is energy efficiency considered in technology and hosting choices?
- [ ] Are sustainability metrics tracked for the platform?

---

## CATEGORY 3: SECURITY PRINCIPLES

---

### S-01 — Defense in Depth

**Statement**
Security must be implemented in multiple independent layers so that the failure of any single control does not result in a security breach. No single point of security failure is acceptable.

**Rationale**
No security control is infallible. Layered defences ensure that an attacker who bypasses one control is stopped by another. This reduces blast radius and attack surface.

**Implications**
- Security controls must exist at network, application, data, and identity layers.
- Network segmentation, firewalls, WAFs, and DDoS protection must be implemented.
- Encryption must be applied at transit and at rest, independently.
- Monitoring and anomaly detection must operate across all layers.

**Items to Verify in Review**
- [ ] Are security controls implemented at multiple layers (network, application, data, identity)?
- [ ] Is network segmentation applied (VNets, NSGs, private endpoints)?
- [ ] Are WAF and DDoS protections in place for internet-facing components?
- [ ] Is encryption applied independently at transit (TLS 1.2+) and at rest (AES-256)?
- [ ] Is anomaly detection and alerting active across all security layers?

---

### S-02 — Least Privilege

**Statement**
All identities (users, services, applications) must be granted the minimum permissions necessary to perform their required functions, for the minimum required duration.

**Rationale**
Excessive privileges increase the impact of a compromise. Least privilege limits the blast radius of a security incident and reduces the risk of accidental or malicious misuse.

**Implications**
- RBAC must be implemented with granular, role-specific permissions.
- Service accounts must have scoped permissions and must not use shared credentials.
- Just-in-time (JIT) access must be used for privileged operations.
- Permission reviews must be conducted regularly.

**Items to Verify in Review**
- [ ] Is RBAC implemented with granular, role-appropriate permissions?
- [ ] Are service accounts scoped to minimum required permissions?
- [ ] Is just-in-time (JIT) access used for privileged operations?
- [ ] Are there no shared credentials or overly broad permissions?
- [ ] Is there a regular access review process?
- [ ] Are privileged identity management (PIM) controls in place?

---

### S-03 — Data Encryption

**Statement**
All sensitive data must be encrypted both in transit and at rest using approved, current encryption standards. Encryption key management must follow enterprise key vault standards.

**Rationale**
Unencrypted data is vulnerable to interception, exfiltration, and regulatory non-compliance. Encryption is a non-negotiable baseline control for all systems handling sensitive or regulated data.

**Implications**
- TLS 1.2 or higher is mandatory for all data in transit.
- AES-256 or equivalent is required for data at rest.
- Encryption keys must be managed via an approved key management service (e.g., Azure Key Vault).
- Key rotation policies must be defined and automated.

**Items to Verify in Review**
- [ ] Is TLS 1.2+ enforced for all data in transit?
- [ ] Is data at rest encrypted using AES-256 or equivalent?
- [ ] Are encryption keys managed via Azure Key Vault (or approved equivalent)?
- [ ] Is key rotation automated and documented?
- [ ] Are database encryption (TDE) and backup encryption enabled?
- [ ] Is there no use of deprecated or weak encryption algorithms (MD5, SHA-1, DES)?

---

### S-04 — Identity and Access Management

**Statement**
All access to systems, data, and APIs must be authenticated and authorised through a centralised, enterprise-approved identity and access management platform.

**Rationale**
Fragmented identity management creates security gaps, audit failures, and operational complexity. Centralised IAM enables consistent policy enforcement, auditability, and rapid response to identity-related threats.

**Implications**
- Azure Active Directory (AAD) must be used as the identity provider for all enterprise systems.
- Multi-factor authentication (MFA) must be enforced for all human users.
- Service-to-service authentication must use managed identities or certificates, never shared secrets.
- All access must be logged and available for audit.

**Items to Verify in Review**
- [ ] Is Azure AD (or enterprise-approved IdP) used for all authentication?
- [ ] Is MFA enforced for all human user access?
- [ ] Are managed identities or certificates used for service-to-service authentication?
- [ ] Is all access logged and audit-ready?
- [ ] Are conditional access policies applied based on risk?
- [ ] Is SSO implemented to avoid credential sprawl?

---

### S-05 — Security by Design

**Statement**
Security requirements must be defined, designed, and validated during architecture and design phases — not discovered during testing or post-production deployment.

**Rationale**
Security defects are 30x more expensive to fix in production than in design. Embedding security in the design process reduces cost, risk, and time to remediation.

**Implications**
- Threat modelling (STRIDE or equivalent) must be completed during design.
- Security user stories and acceptance criteria must be defined in the backlog.
- Security architecture must be reviewed before development begins.
- Secure coding standards must be documented and enforced through tooling.

**Items to Verify in Review**
- [ ] Has a threat model (STRIDE or equivalent) been completed?
- [ ] Are security requirements documented as user stories with acceptance criteria?
- [ ] Has the security architecture been reviewed before development started?
- [ ] Are secure coding standards applied and enforced (OWASP Top 10)?
- [ ] Are SAST results clean (no critical or high findings)?

---

### S-06 — Continuous Monitoring

**Statement**
All systems must be continuously monitored for security threats, anomalies, and policy violations. Security monitoring must be real-time, automated, and integrated with incident response.

**Rationale**
Threats evolve continuously. Static, periodic monitoring is insufficient. Real-time monitoring enables rapid detection and response, minimising the window of exposure.

**Implications**
- Security Information and Event Management (SIEM) must be connected to all system components.
- Alerting thresholds must be defined for all critical security events.
- Security monitoring dashboards must be available to the security operations team.
- Log retention must meet regulatory requirements (minimum 12 months online, 7 years archived).

**Items to Verify in Review**
- [ ] Is SIEM integration implemented for all system components?
- [ ] Are security alerting thresholds defined and tested?
- [ ] Is log retention policy meeting regulatory requirements?
- [ ] Are security dashboards available to SecOps?
- [ ] Are there automated responses to known threat patterns?
- [ ] Is user and entity behaviour analytics (UEBA) applied for privileged access?

---

### S-07 — Incident Response

**Statement**
All systems must have a documented, tested incident response plan that enables rapid detection, containment, eradication, and recovery from security incidents.

**Rationale**
Security incidents are inevitable. The speed and effectiveness of response determines the business impact. Untested incident response plans fail when they are needed most.

**Implications**
- An incident response playbook must exist and be maintained for each system.
- Runbooks for common security scenarios (data breach, ransomware, DDoS) must be available.
- Incident response must be tested through tabletop exercises at minimum annually.
- Recovery time objectives (RTO) must be defined and validated for security incident scenarios.

**Items to Verify in Review**
- [ ] Is an incident response playbook documented and accessible?
- [ ] Are runbooks available for common security scenarios?
- [ ] Has incident response been tested within the last 12 months?
- [ ] Are RTO objectives defined for security incident recovery?
- [ ] Are contact escalation paths documented and current?

---

### S-08 — Security Awareness Training

**Statement**
All personnel with access to enterprise systems must complete regular security awareness training. Security responsibilities must be understood by all team members, not just security specialists.

**Rationale**
Human error is the leading cause of security incidents. A security-aware culture reduces susceptibility to phishing, social engineering, and accidental data exposure.

**Implications**
- Security awareness training must be mandatory and tracked for all team members.
- Developers must complete secure development training (OWASP, secure coding) annually.
- Phishing simulation exercises must be conducted regularly.
- Security champions must be embedded in development teams.

**Items to Verify in Review**
- [ ] Has the team completed mandatory security awareness training?
- [ ] Have developers completed secure development training?
- [ ] Is a security champion identified in the team?
- [ ] Are there processes for reporting suspicious activity?

---

### S-09 — Compliance (Security)

**Statement**
All systems must comply with applicable security standards and frameworks (ISO 27001, SOC 2, NIST, PCI-DSS, DORA, etc.) and internal security policies. Compliance must be demonstrable through evidence, not assertion.

**Rationale**
Security compliance frameworks provide proven control frameworks that, when implemented, significantly reduce security risk. Regulatory compliance is also a legal obligation for many system types.

**Implications**
- Applicable compliance frameworks must be identified and controls mapped at design time.
- Compliance evidence must be continuously generated and maintained in an audit-ready state.
- Non-compliant controls must have documented risk acceptance and remediation timelines.
- Third-party and vendor compliance must be assessed and contractually required.

**Items to Verify in Review**
- [ ] Are applicable security compliance frameworks identified?
- [ ] Are controls mapped to framework requirements?
- [ ] Is compliance evidence audit-ready and current?
- [ ] Are vendor/third-party compliance certifications reviewed?
- [ ] Are non-compliant areas documented with risk acceptance and remediation plans?

---

### S-10 — Regular Audits and Assessments

**Statement**
Security controls, configurations, and architectures must be regularly audited and assessed to identify drift, new vulnerabilities, and gaps relative to evolving threat landscapes.

**Rationale**
Technology landscapes change continuously. Security controls that were effective 12 months ago may be insufficient today. Regular assessment is essential to maintaining security posture.

**Implications**
- Vulnerability assessments must be conducted at minimum quarterly, or on every significant change.
- Penetration testing (VAPT) must be conducted at minimum annually for externally facing systems.
- Configuration management and drift detection must be automated.
- Audit findings must be tracked to closure with defined SLAs by severity.

**Items to Verify in Review**
- [ ] Is VAPT evidence available and dated within 12 months?
- [ ] Are vulnerability assessments conducted regularly and findings tracked?
- [ ] Is configuration drift detection automated?
- [ ] Are audit findings tracked with severity-based remediation SLAs?
- [ ] Are penetration test findings from previous cycles closed or formally accepted?

---

## CATEGORY 4: APPLICATION PRINCIPLES

---

### A-01 — Interoperability

**Statement**
Applications must be designed to work seamlessly with other systems through open, standard interfaces and protocols. Proprietary integration mechanisms that create vendor lock-in must be avoided.

**Rationale**
Interoperability enables ecosystem integration, reduces integration cost, and protects the organisation from vendor lock-in. Standards-based interfaces outlast proprietary ones.

**Implications**
- REST APIs, event-driven interfaces, and standard messaging protocols must be preferred.
- Open standards (OpenAPI, AsyncAPI, JSON Schema, FHIR, ISO 20022) must be used.
- Proprietary protocols must be justified with a migration path to standards.
- Integration catalogue must document all interfaces with standard metadata.

**Items to Verify in Review**
- [ ] Are interfaces designed using open standards (OpenAPI, AsyncAPI, JSON Schema)?
- [ ] Are proprietary protocols avoided or justified with migration plans?
- [ ] Is the integration catalogue complete and up to date?
- [ ] Are all interfaces discoverable through the enterprise API catalogue?
- [ ] Is there a versioning strategy preventing breaking changes?

---

### A-02 — Scalability (Application)

**Statement**
Applications must be designed to scale horizontally and vertically to meet demand growth without requiring architectural changes. Scalability must be validated with evidence, not assumed.

**Rationale**
Applications that cannot scale become bottlenecks under growth. Over-provisioning to compensate for poor scalability design is wasteful. Proven scalability requires testing.

**Implications**
- Applications must support horizontal scaling (stateless design, shared-nothing architecture).
- Autoscaling policies must be defined and tested.
- Performance testing (load, stress, soak) must be conducted and results evidenced.
- Scalability targets must be defined in terms of TPS, concurrent users, and data volumes.

**Items to Verify in Review**
- [ ] Is the application designed for horizontal scaling (stateless where possible)?
- [ ] Are autoscaling policies defined and tested?
- [ ] Is performance/load testing evidence available?
- [ ] Are scalability targets (TPS, concurrent users, response time) defined and met?
- [ ] Is there a capacity plan for YoY growth?

---

### A-03 — Modularity

**Statement**
Applications must be composed of loosely coupled, independently deployable modules or services with well-defined responsibilities and interfaces.

**Rationale**
Modular applications are easier to maintain, test, scale, and evolve. Monolithic tight coupling creates change risk, deployment dependencies, and testing complexity.

**Implications**
- Domain-driven design (DDD) bounded contexts must guide service decomposition.
- Each module must have a single, clear responsibility.
- Inter-module communication must be through defined, versioned interfaces.
- Teams must be able to deploy modules independently.

**Items to Verify in Review**
- [ ] Are services/modules decomposed along domain boundaries?
- [ ] Does each module have a clearly defined, single responsibility?
- [ ] Is inter-module communication via versioned, well-documented interfaces?
- [ ] Can modules be deployed independently?
- [ ] Is there a defined ownership model for each module?

---

### A-04 — User-Centric Design

**Statement**
Application interfaces must be designed around the needs, capabilities, and context of the end user. Usability must be validated with real users, not assumed by developers.

**Rationale**
Applications designed without user input are frequently misaligned with actual workflows, causing adoption failure, errors, and support overhead.

**Implications**
- User research and journey mapping must inform UI/UX design.
- Accessibility standards (WCAG 2.1 AA minimum) must be met.
- Usability testing with representative users must be conducted before launch.
- User feedback loops must be embedded in the operating model post-launch.

**Items to Verify in Review**
- [ ] Is user research or journey mapping documented?
- [ ] Do interfaces meet WCAG 2.1 AA accessibility standards?
- [ ] Has usability testing been conducted with representative users?
- [ ] Are feedback mechanisms embedded for post-launch user input?

---

### A-05 — Cloud Enabled and Native

**Statement**
Applications must be designed to leverage cloud platform capabilities (managed services, autoscaling, serverless, global distribution) rather than replicating on-premises patterns in the cloud.

**Rationale**
Cloud-native patterns unlock elasticity, resilience, and velocity advantages of cloud platforms. "Lift and shift" of on-premises patterns fails to realise cloud value and often introduces new risks.

**Implications**
- Managed cloud services (PaaS, SaaS) must be preferred over IaaS where equivalent capability exists.
- Applications must be containerised or serverless for portability and scaling.
- 12-Factor Application principles must be applied.
- Multi-region and availability zone design must be applied for critical applications.

**Items to Verify in Review**
- [ ] Are cloud-native managed services used in preference to IaaS?
- [ ] Are applications containerised (Docker/Kubernetes) or serverless?
- [ ] Are 12-Factor Application principles applied?
- [ ] Is the application designed for multi-AZ or multi-region where required by availability targets?
- [ ] Are cloud provider lock-in risks assessed and managed?

---

### A-06 — APIs and Microservices

**Statement**
Applications must expose capabilities through well-designed APIs and, where appropriate, adopt a microservices architecture to enable independent deployment, scaling, and evolution of capabilities.

**Rationale**
API-first design enables ecosystem integration and product thinking. Microservices enable organisational agility by aligning technical boundaries with team boundaries (Conway's Law).

**Implications**
- APIs must follow enterprise API design standards (RESTful, resource-oriented, versioned, documented).
- Microservices must be sized to the team that owns them (two-pizza team principle).
- API gateways must be used for external-facing APIs.
- Service meshes must be considered for complex microservice communication.

**Items to Verify in Review**
- [ ] Do APIs follow enterprise design standards (OpenAPI, versioned, resource-oriented)?
- [ ] Are microservices appropriately sized and team-aligned?
- [ ] Is an API gateway in use for external-facing APIs?
- [ ] Is inter-service communication secure and observable?
- [ ] Are APIs published to the enterprise API catalogue?

---

### A-07 — Data Integrity

**Statement**
Applications must ensure data remains accurate, consistent, and uncorrupted throughout its lifecycle, including during transactions, integrations, and failures.

**Rationale**
Data integrity failures result in incorrect business decisions, financial errors, regulatory non-compliance, and customer harm. Integrity must be enforced at the application and infrastructure levels.

**Implications**
- ACID transaction properties must be maintained for financial and critical data operations.
- Idempotency must be designed into all API and event processing to prevent duplicate processing.
- Input validation must be enforced at all system boundaries.
- Data checksums or hash validation must be used for file and message transfers.

**Items to Verify in Review**
- [ ] Are ACID properties applied for transactional data operations?
- [ ] Is idempotency implemented in APIs and event consumers?
- [ ] Is input validation enforced at all system entry points?
- [ ] Are data checksums or hash validation applied for transfers?
- [ ] Are data consistency strategies documented for distributed scenarios?

---

### A-08 — Compliance (Application)

**Statement**
Applications must comply with applicable regulatory, industry, and internal standards. Compliance must be evidenced through controls, testing, and audit mechanisms built into the application.

**Rationale**
Application-level non-compliance is a direct regulatory and reputational risk. Controls must be embedded in the application, not reliant solely on perimeter defences.

**Implications**
- Applicable compliance frameworks must be mapped to application-level controls.
- Audit logging must capture all significant business events and user actions.
- Data residency requirements must be respected in hosting and replication decisions.
- Third-party components must be assessed for compliance implications (licensing, export controls).

**Items to Verify in Review**
- [ ] Are applicable compliance frameworks mapped to application controls?
- [ ] Is audit logging capturing all significant business and user events?
- [ ] Are data residency requirements documented and enforced?
- [ ] Are third-party components assessed for licensing and compliance?

---

### A-09 — High Availability

**Statement**
Applications must be designed to meet defined availability targets through redundancy, failover, health monitoring, and graceful degradation. Availability targets must be evidenced, not assumed.

**Rationale**
Application downtime has direct financial and reputational consequences. High availability must be an architectural property, not a feature added post-deployment.

**Implications**
- All single points of failure must be eliminated or mitigated.
- Automated health checks and self-healing must be implemented.
- Failover must be automated and tested.
- Degraded mode operation (reduced functionality under partial failure) must be designed.

**Items to Verify in Review**
- [ ] Are availability targets (SLA/SLO) defined and evidenced?
- [ ] Is SPOF analysis documented with mitigations?
- [ ] Is automated failover implemented and tested?
- [ ] Is graceful degradation designed for partial failure scenarios?
- [ ] Are health check endpoints implemented and monitored?

---

### A-10 — Performance Optimization

**Statement**
Applications must meet defined performance targets under normal and peak load conditions. Performance must be measured, optimised, and continuously monitored.

**Rationale**
Poor performance degrades customer experience, increases infrastructure cost, and signals architectural problems. Performance must be treated as a feature, not a non-functional afterthought.

**Implications**
- Response time SLOs must be defined (e.g., P95 < 500ms, P99 < 2s).
- Caching strategies must be applied at appropriate layers.
- Database query optimisation and indexing must be reviewed.
- Performance profiling must be conducted as part of the development process.

**Items to Verify in Review**
- [ ] Are response time SLOs defined (P95, P99 targets)?
- [ ] Is performance test evidence (load, stress, soak) available?
- [ ] Is a caching strategy defined and implemented?
- [ ] Have database queries been profiled and optimised?
- [ ] Is performance monitoring in place with alerting on SLO breach?

---

## CATEGORY 5: SOFTWARE PRINCIPLES

---

### SW-01 — Separation of Concerns

**Statement**
Software must be structured so that distinct concerns (presentation, business logic, data access, integration) are handled by separate, well-defined components with minimal overlap.

**Rationale**
Mixing concerns creates tight coupling, reduces testability, and makes change risky. Clear separation enables independent evolution, testing, and understanding of each component.

**Implications**
- Layered architecture (presentation, application, domain, infrastructure) must be applied.
- Business logic must not be embedded in UI components or database procedures.
- Cross-cutting concerns (logging, security, caching) must be handled through consistent patterns (e.g., middleware, decorators).

**Items to Verify in Review**
- [ ] Is the architecture structured with clear layer separation?
- [ ] Is business logic separated from presentation and data access?
- [ ] Are cross-cutting concerns handled through consistent, reusable patterns?
- [ ] Can each layer be tested independently?

---

### SW-02 — Single Responsibility Principle

**Statement**
Each software component, module, service, or class must have a single, well-defined responsibility. A component should have only one reason to change.

**Rationale**
Components with multiple responsibilities are harder to understand, test, maintain, and evolve. Single responsibility drives cleaner design and reduces the blast radius of changes.

**Implications**
- Services must be scoped to a single domain capability.
- Classes and modules must have narrow, focused interfaces.
- When a component begins accumulating unrelated responsibilities, refactoring must be planned.

**Items to Verify in Review**
- [ ] Does each service/component have a single, documented responsibility?
- [ ] Are interfaces narrow and focused?
- [ ] Is there evidence of regular refactoring to maintain clean boundaries?

---

### SW-03 — Encapsulation

**Statement**
Internal implementation details of a component must be hidden from consumers. Components must expose only what is necessary through well-defined interfaces.

**Rationale**
Exposing internals creates implicit dependencies that make components brittle and difficult to change independently. Encapsulation enables safe internal evolution without breaking consumers.

**Implications**
- Internal data structures, database schemas, and implementation details must not be exposed.
- Public interfaces must be deliberately designed, minimised, and versioned.
- Domain events rather than direct data access must be used for cross-domain communication.

**Items to Verify in Review**
- [ ] Are internal implementation details hidden from consumers?
- [ ] Are public interfaces deliberately designed and documented?
- [ ] Is cross-domain data access via APIs/events rather than direct database access?

---

### SW-04 — Abstraction

**Statement**
Software must use abstraction to hide complexity, isolate dependencies on external systems, and enable interchangeability of implementations without impacting consumers.

**Rationale**
Direct dependencies on infrastructure, third-party services, or implementation details make software brittle and untestable. Abstraction enables decoupling and independent evolution.

**Implications**
- Repository pattern must be used for data access abstraction.
- Adaptor/port pattern must be used for external service integration.
- Infrastructure abstractions must enable switching between cloud providers or services with minimal change.
- Interfaces must be defined in terms of domain concepts, not implementation details.

**Items to Verify in Review**
- [ ] Are data access and external service integrations abstracted?
- [ ] Can infrastructure dependencies be swapped without impacting business logic?
- [ ] Are interfaces defined in domain terms, not implementation terms?
- [ ] Are abstractions testable with mocks or stubs?

---

### SW-05 — Design for Change

**Statement**
Software must be designed with the expectation that requirements will change. Extensibility, configurability, and maintainability must be built-in properties.

**Rationale**
The only certainty in software is that requirements will change. Software that is expensive or risky to change accumulates technical debt and inhibits business agility.

**Implications**
- Open/Closed Principle: software must be open for extension, closed for modification.
- Feature flags and configuration-driven behaviour must be preferred over hard-coded logic.
- Plugin or extension points must be designed for anticipated variation.
- Test coverage must be sufficient to enable confident change.

**Items to Verify in Review**
- [ ] Are extension points designed for anticipated variation?
- [ ] Is behaviour driven by configuration rather than hard-coded logic where appropriate?
- [ ] Is test coverage sufficient to enable safe refactoring?
- [ ] Is the Open/Closed Principle applied in component design?

---

### SW-06 — Portability

**Statement**
Software must be designed to run across different environments (development, test, production, cloud regions) without requiring environment-specific code changes.

**Rationale**
Non-portable software is expensive to deploy, difficult to test, and creates environment-specific defects. Portability is foundational to CI/CD and cloud-native operation.

**Implications**
- 12-Factor App: all configuration must be externalised via environment variables or configuration services.
- Containerisation (Docker) must be used to ensure environmental consistency.
- Infrastructure as Code must be used for environment provisioning.
- No hardcoded environment values (IP addresses, URLs, credentials) are acceptable.

**Items to Verify in Review**
- [ ] Is all configuration externalised (no hardcoded environment values)?
- [ ] Is the application containerised for environment consistency?
- [ ] Is IaC used for environment provisioning?
- [ ] Can the application be deployed to a new environment without code changes?

---

### SW-07 — Loose Coupling

**Statement**
Software components must have minimal dependencies on each other's internal implementation. Dependencies must be on stable interfaces, not concrete implementations.

**Rationale**
Tightly coupled systems cannot be changed, scaled, or tested independently. Loose coupling is the foundation of maintainable, evolvable systems.

**Implications**
- Dependency injection must be used to invert dependencies.
- Asynchronous messaging must be preferred over synchronous calls for non-time-critical integrations.
- Event-driven architecture must be considered for decoupling producers from consumers.
- Consumer-driven contract testing must be used to validate interface compatibility.

**Items to Verify in Review**
- [ ] Is dependency injection used to invert and externalise dependencies?
- [ ] Is asynchronous messaging used where synchronous coupling is unnecessary?
- [ ] Are consumer-driven contract tests in place for critical interfaces?
- [ ] Can components be deployed and scaled independently?

---

### SW-08 — Code Readability

**Statement**
Code must be written to be read by humans first and executed by machines second. Clarity, consistency, and self-documentation are required properties of all production code.

**Rationale**
Code is read 10x more than it is written. Unreadable code is a maintenance liability, onboarding barrier, and source of defects.

**Implications**
- Enterprise coding standards must be documented and enforced through linting tools.
- Meaningful naming conventions must be applied to variables, functions, classes, and services.
- Code review must include readability as an explicit evaluation criterion.
- Comments must explain 'why', not 'what' — the code should explain itself.

**Items to Verify in Review**
- [ ] Are enterprise coding standards documented and enforced through tooling?
- [ ] Are naming conventions consistent and meaningful?
- [ ] Is code review including readability as an explicit criterion?
- [ ] Is cyclomatic complexity within acceptable thresholds?
- [ ] Are static code analysis results (complexity, duplication) within acceptable limits?

---

### SW-09 — Testability

**Statement**
All software must be designed to be testable at unit, integration, and system levels. Test automation must be a first-class citizen of the development process.

**Rationale**
Untestable software cannot be safely changed. Manual testing does not scale. Test automation is the foundation of confident, high-velocity delivery.

**Implications**
- Unit test coverage must meet the defined threshold (typically >80% for critical paths).
- Integration and API tests must be automated and run in CI/CD pipelines.
- End-to-end tests must cover critical business flows.
- Test data management must be addressed for all test environments.

**Items to Verify in Review**
- [ ] Is unit test coverage meeting the defined threshold?
- [ ] Are integration and API tests automated and running in CI/CD?
- [ ] Are end-to-end tests covering critical business flows?
- [ ] Is test data management documented and implemented?
- [ ] Are test results tracked as quality metrics?

---

### SW-10 — Dependency Injection

**Statement**
Dependencies must be injected into components from the outside rather than created internally. Components must not be responsible for constructing their own dependencies.

**Rationale**
Internal dependency construction creates tight coupling, makes testing difficult (dependencies cannot be mocked), and inhibits flexibility. Dependency injection enables testability and extensibility.

**Implications**
- A dependency injection container or framework must be used.
- All external dependencies (databases, message brokers, external services) must be injected.
- Dependencies must be expressed as interfaces, not concrete types.
- Testing must use injected mocks or stubs, not real external dependencies.

**Items to Verify in Review**
- [ ] Is a dependency injection framework in use?
- [ ] Are all external dependencies injected as interfaces?
- [ ] Are unit tests using injected mocks for external dependencies?
- [ ] Is the component dependency graph clean (no circular dependencies)?

---

## CATEGORY 6: DATA PRINCIPLES

---

### D-01 — Quality

**Statement**
Data must meet defined quality standards across accuracy, completeness, consistency, timeliness, and validity. Data quality must be monitored continuously and managed proactively.

**Rationale**
Poor data quality leads to flawed business decisions, regulatory non-compliance, and loss of stakeholder trust. Quality must be managed as a measurable, owned property of data assets.

**Implications**
- Data quality dimensions must be defined for each data domain (accuracy, completeness, timeliness, validity, consistency).
- Data quality rules must be implemented at ingestion and transformation points.
- Data quality dashboards must be published to data owners.
- Data quality SLOs must be defined and breaches must trigger remediation workflows.

**Items to Verify in Review**
- [ ] Are data quality dimensions defined for key data entities?
- [ ] Are data quality rules implemented at ingestion and transformation?
- [ ] Is data quality monitored and surfaced through dashboards?
- [ ] Are data quality SLOs defined and tracked?
- [ ] Is there a data quality issue remediation process?

---

### D-02 — Governance

**Statement**
Data must be governed through defined policies, standards, ownership, and stewardship across its full lifecycle. Data governance must be institutionalised, not ad hoc.

**Rationale**
Ungoverned data creates inconsistency, security risk, regulatory exposure, and inability to derive value. Governance provides the framework for responsible, consistent data management.

**Implications**
- A data governance framework must define ownership, stewardship, classification, and policy enforcement.
- Data must be catalogued in the enterprise data catalogue with metadata.
- Data policies must be enforced through technical controls, not just processes.
- Data governance roles (data owner, data steward, data custodian) must be defined and assigned.

**Items to Verify in Review**
- [ ] Are data governance roles (owner, steward, custodian) defined and assigned?
- [ ] Is data catalogued in the enterprise data catalogue?
- [ ] Are data policies technically enforced?
- [ ] Is there a data governance committee or process for resolving data disputes?

---

### D-03 — Integration (Data)

**Statement**
Data must be integrated across systems using approved, standard patterns that preserve data quality, lineage, and consistency. Direct database-to-database integration is prohibited.

**Rationale**
Uncontrolled data integration creates consistency issues, hidden dependencies, and compliance risk. Governed integration patterns ensure data quality and lineage are maintained.

**Implications**
- Data integration must use approved patterns: API, event stream, data product, or approved ETL platform.
- Direct database access across domain boundaries is prohibited.
- Data integration must be catalogued with source, target, transformation logic, frequency, and data lineage.
- Data contracts must be established between data producers and consumers.

**Items to Verify in Review**
- [ ] Are all data integrations using approved patterns (API, event, data product, ETL)?
- [ ] Is direct cross-domain database access absent?
- [ ] Are data integrations catalogued with lineage documented?
- [ ] Are data contracts established and versioned?

---

### D-04 — Single Source of Truth

**Statement**
Each data entity must have exactly one authoritative source system. All other systems must consume the canonical version from that source rather than maintaining their own copies.

**Rationale**
Multiple authoritative sources for the same data create inconsistency, reconciliation overhead, and conflicting business decisions. A single source of truth enables consistent, trustworthy data.

**Implications**
- The golden record and its authoritative source system must be documented for all key data entities.
- Data replication must be governed (only to approved targets, with freshness SLAs).
- Data consumers must not modify replicated data — they must request changes via the source system.
- Master Data Management (MDM) must be applied for critical shared data entities.

**Items to Verify in Review**
- [ ] Is the authoritative source documented for all key data entities?
- [ ] Is data replication governed with freshness SLAs?
- [ ] Are consumers prevented from modifying replicated data?
- [ ] Is MDM applied for critical shared entities (customer, product, account)?

---

### D-05 — Accessibility (Data)

**Statement**
Data must be accessible to authorised consumers in the right format, at the right time, through approved, self-service mechanisms. Access must be controlled, audited, and easy for authorised users.

**Rationale**
Data that cannot be accessed efficiently creates shadow data stores, manual workarounds, and missed business value. Accessibility must be balanced with governance and security.

**Implications**
- Data must be published through approved channels (APIs, data catalogue, data products, approved analytics platforms).
- Self-service data discovery must be enabled through the enterprise data catalogue.
- Access controls must be granular (row-level, column-level where required).
- Data access must be audited and logged.

**Items to Verify in Review**
- [ ] Is data published through approved channels?
- [ ] Is the enterprise data catalogue populated with metadata and access information?
- [ ] Is access control granular (row/column level where required)?
- [ ] Is data access audited and log retained per policy?
- [ ] Is there a self-service mechanism for authorised users to discover and request access?

---

### D-06 — Retention and Disposal

**Statement**
All data must have defined retention policies based on business, regulatory, and legal requirements. Data must be disposed of securely and completely when retention periods expire.

**Rationale**
Retaining data beyond its required period increases regulatory risk, storage cost, and breach impact. Disposing of data too early violates legal requirements. Policy must govern the balance.

**Implications**
- Retention policies must be defined for each data classification and regulatory obligation.
- Automated data archival and deletion pipelines must be implemented.
- Secure deletion (cryptographic erasure or certified deletion) must be applied.
- Retention and disposal records must be maintained for audit.

**Items to Verify in Review**
- [ ] Are data retention policies defined for each data type and classification?
- [ ] Is automated data archival and deletion implemented?
- [ ] Is secure deletion applied (cryptographic erasure or certified wipe)?
- [ ] Are retention and disposal records maintained?
- [ ] Are legal hold processes defined and implemented?

---

### D-07 — Master Data Management

**Statement**
Critical shared data entities (customer, product, account, counterparty, reference data) must be managed through a defined Master Data Management capability that ensures consistency, accuracy, and single-source governance.

**Rationale**
Inconsistent master data across systems results in duplicate records, reconciliation failures, and incorrect business outcomes. MDM provides the authoritative, trusted version of critical shared data.

**Implications**
- MDM scope must be defined, identifying which entities require MDM treatment.
- MDM matching, merging, and deduplication rules must be documented.
- All systems must consume master data from the MDM hub, not maintain their own copies.
- MDM data quality must be monitored and reported.

**Items to Verify in Review**
- [ ] Are critical shared entities managed through the MDM platform?
- [ ] Are MDM matching and deduplication rules documented?
- [ ] Are all systems consuming from the MDM hub?
- [ ] Is MDM data quality monitored?

---

### D-08 — Analytics

**Statement**
Data architecture must support the analytics and reporting needs of the organisation through a governed, performant, and accessible analytics platform. Analytics must not be bolt-on.

**Rationale**
Data that cannot be analysed cannot generate business value. Analytics capability must be a designed component of the data architecture, not an afterthought.

**Implications**
- Analytics platform architecture (data warehouse, data lakehouse, OLAP) must be defined.
- Data must be modelled and published in a form suitable for analytics consumption.
- Self-service analytics must be enabled for business users through approved tooling.
- Analytics data must be subject to the same governance, quality, and security standards as operational data.

**Items to Verify in Review**
- [ ] Is an analytics platform defined and used for reporting?
- [ ] Is data modelled (dimensional, wide table, or equivalent) for analytics?
- [ ] Is self-service analytics available for business users?
- [ ] Are analytics datasets subject to data governance and quality controls?

---

### D-09 — Lineage

**Statement**
The origin, transformation history, and consumption of all data must be traceable end-to-end. Data lineage must be captured automatically and be available for audit and impact analysis.

**Rationale**
Data lineage is essential for regulatory compliance (BCBS 239, GDPR), debugging data quality issues, impact assessment of changes, and building trust in data. Manual lineage documentation is insufficient.

**Implications**
- Data lineage must be captured automatically through the data pipeline tooling.
- Lineage must include source system, transformation logic, timestamp, and target system.
- Data lineage must be queryable for impact analysis (what downstream data is affected if a source changes?).
- Lineage must be retained for the lifetime of the data plus the regulatory retention period.

**Items to Verify in Review**
- [ ] Is data lineage captured automatically?
- [ ] Does lineage cover source, transformations, and consumption?
- [ ] Is lineage queryable for impact analysis?
- [ ] Is lineage retained per regulatory requirements?
- [ ] Is lineage used as evidence in regulatory compliance reporting?

---

### D-10 — Interoperability (Data)

**Statement**
Data formats, schemas, and standards must be interoperable across systems and with external parties. Proprietary data formats that prevent integration must be avoided.

**Rationale**
Proprietary data formats create integration barriers, limit ecosystem participation, and increase migration cost. Open, standard formats reduce friction and extend the useful life of data assets.

**Implications**
- Open data formats and standards must be preferred (JSON, Parquet, Avro, CSV, XML, ISO standards).
- Schema registries must be used for event and message data to ensure consumer compatibility.
- Data exchange with external parties must use agreed, documented standards.
- Schema evolution must be backward-compatible by default.

**Items to Verify in Review**
- [ ] Are open, standard data formats used?
- [ ] Is a schema registry in use for event data?
- [ ] Are schemas backward-compatible across versions?
- [ ] Is external data exchange using agreed standards?

---

## CATEGORY 7: INFRASTRUCTURE PRINCIPLES

---

### I-01 — Scalability (Infrastructure)

**Statement**
Infrastructure must scale dynamically to meet workload demand without manual intervention. Infrastructure scalability must be validated and must not impose limits on application scalability.

**Rationale**
Static infrastructure provisioning leads to either over-provisioning (wasteful) or under-provisioning (service degradation). Dynamic, elastic infrastructure is foundational to modern operations.

**Implications**
- Horizontal auto-scaling must be configured for all compute workloads.
- Infrastructure capacity limits must be well above peak workload projections.
- Capacity planning reviews must be conducted regularly.
- Infrastructure-as-Code must be used to enable rapid, repeatable provisioning.

**Items to Verify in Review**
- [ ] Is auto-scaling configured and tested for all compute workloads?
- [ ] Is infrastructure capacity above peak workload projections with headroom?
- [ ] Is a capacity planning review process in place?
- [ ] Is IaC used for all infrastructure provisioning?
- [ ] Have infrastructure scaling limits been tested under simulated peak load?

---

### I-02 — Reliability (Infrastructure)

**Statement**
Infrastructure must be designed for high reliability through redundancy, automated failover, and self-healing capabilities. Infrastructure failures must not result in application downtime beyond defined RTO.

**Rationale**
Infrastructure is the foundation of application reliability. Unreliable infrastructure makes application-level reliability impossible to achieve regardless of application design quality.

**Implications**
- All infrastructure components must be deployed across multiple availability zones.
- Automated health checks and self-healing must be implemented at the infrastructure layer.
- Infrastructure monitoring must detect failures faster than they impact users.
- Failover must be tested regularly, not just documented.

**Items to Verify in Review**
- [ ] Are infrastructure components deployed across multiple availability zones?
- [ ] Is automated failover tested and evidenced?
- [ ] Is infrastructure health monitoring in place with alerting?
- [ ] Are self-healing mechanisms (auto-restart, auto-replacement) implemented?
- [ ] Is there evidence of regular failover testing?

---

### I-03 — Standardization

**Statement**
Infrastructure components, configurations, and operating procedures must be standardised across the enterprise. Non-standard infrastructure must be justified and have a migration plan.

**Rationale**
Infrastructure diversity increases operational complexity, skill requirements, security risk, and support cost. Standardisation enables shared tooling, skills, and efficient operations.

**Implications**
- Enterprise-approved infrastructure platforms, OS images, and runtimes must be used.
- Deviation from standards requires ARB approval and a documented migration plan.
- Golden image management must be applied for VM and container base images.
- Configuration standards must be enforced through policy-as-code.

**Items to Verify in Review**
- [ ] Are enterprise-approved infrastructure platforms and runtimes used?
- [ ] Are deviations from standards documented with migration plans?
- [ ] Are golden images used for VM and container base images?
- [ ] Is policy-as-code enforced for infrastructure configuration?

---

### I-04 — Cost Efficiency

**Statement**
Infrastructure must be provisioned and operated at the minimum cost required to meet performance, reliability, and compliance requirements. Waste must be identified and eliminated continuously.

**Rationale**
Infrastructure cost is a significant and growing component of technology spend. Inefficient infrastructure provisioning and operation consumes budget that could fund innovation.

**Implications**
- Right-sizing analysis must be conducted regularly.
- Reserved instances and committed use discounts must be applied for steady-state workloads.
- Unused or idle resources must be identified and decommissioned.
- Cost allocation tagging must be applied to all infrastructure resources.
- FinOps practices must be adopted for cloud cost management.

**Items to Verify in Review**
- [ ] Is a TCO/cost analysis conducted for the infrastructure design?
- [ ] Are right-sizing recommendations applied?
- [ ] Are reserved instances used for predictable workloads?
- [ ] Are idle/unused resources identified for decommission?
- [ ] Is cost allocation tagging applied to all resources?
- [ ] Is there a FinOps review process for cloud spend?

---

### I-05 — Energy Efficiency

**Statement**
Infrastructure must be operated with consideration for energy consumption and environmental impact. Energy-efficient technology choices and operational practices must be preferred.

**Rationale**
Data centres and cloud infrastructure are significant energy consumers. Energy efficiency reduces environmental impact, lowers operating cost, and meets ESG reporting obligations.

**Implications**
- Serverless and managed services must be preferred over always-on compute where workload patterns suit.
- Resource utilisation targets must be set to avoid low-utilisation waste.
- Regions with higher renewable energy mix must be preferred for non-latency-sensitive workloads.
- Energy consumption metrics must be tracked and reported.

**Items to Verify in Review**
- [ ] Are serverless or managed services used where workload patterns allow?
- [ ] Are resource utilisation targets defined and monitored?
- [ ] Is region selection considering renewable energy availability where possible?
- [ ] Are energy consumption or carbon metrics tracked?

---

### I-06 — Cloud Integration

**Statement**
Infrastructure must leverage native cloud integration capabilities, services, and APIs to maximise the value derived from cloud platform investment and minimise custom integration overhead.

**Rationale**
Cloud-native integration services reduce operational overhead, improve reliability through managed SLAs, and accelerate delivery. Replicating on-premises integration patterns in the cloud negates cloud value.

**Implications**
- Cloud-native integration services (Azure Service Bus, Event Grid, API Management, Logic Apps) must be preferred.
- On-premises connectivity must use approved, secure patterns (ExpressRoute, VPN, private endpoints).
- Multi-cloud strategies must be governed to avoid unmanaged cloud sprawl.
- Cloud integration patterns must be documented in the enterprise integration catalogue.

**Items to Verify in Review**
- [ ] Are cloud-native integration services used in preference to custom solutions?
- [ ] Is on-premises connectivity using approved, secure patterns?
- [ ] Is multi-cloud usage governed and justified?
- [ ] Are cloud integration patterns documented in the enterprise catalogue?

---

### I-07 — Automation

**Statement**
All infrastructure provisioning, configuration, deployment, monitoring, and remediation must be automated. Manual infrastructure operations are a source of inconsistency and risk.

**Rationale**
Manual infrastructure operations are slow, error-prone, and impossible to audit accurately. Automation enables consistency, speed, auditability, and the ability to recover rapidly from failure.

**Implications**
- Infrastructure-as-Code (Terraform, Bicep, ARM templates) must be used for all provisioning.
- Configuration-as-Code (Ansible, DSC) must be used for all configuration management.
- Deployment pipelines must fully automate infrastructure changes.
- Runbook automation must replace manual operational procedures wherever possible.

**Items to Verify in Review**
- [ ] Is IaC used for all infrastructure provisioning?
- [ ] Is configuration-as-code used for all configuration management?
- [ ] Is infrastructure change deployed through automated pipelines?
- [ ] Are manual runbooks being progressively replaced with automation?
- [ ] Is there an automation maturity roadmap for operations?

---

### I-08 — Resilience (Infrastructure)

**Statement**
Infrastructure must be designed to continue operating or recover rapidly in the face of component failures, network disruptions, and disaster scenarios. Resilience must be tested, not assumed.

**Rationale**
Infrastructure resilience is the foundation of application availability. Designed and tested resilience prevents business disruption from infrastructure failures.

**Implications**
- Infrastructure must implement redundancy at every critical layer (compute, network, storage).
- Disaster recovery procedures must be documented and tested at least annually.
- Backup and restore must be automated and tested.
- Chaos engineering must be applied to validate resilience under failure conditions.

**Items to Verify in Review**
- [ ] Is redundancy implemented at all critical infrastructure layers?
- [ ] Is DR documented and tested annually (with evidence)?
- [ ] Are backup and restore processes automated and tested?
- [ ] Is chaos engineering or fault injection used to validate resilience?
- [ ] Are RTO and RPO targets defined and validated through testing?

---

### I-09 — No Single Point of Failure

**Statement**
Infrastructure architecture must eliminate all single points of failure. Every critical component must have a redundant counterpart capable of taking over without manual intervention.

**Rationale**
A single failed component should never result in system-wide outage. SPOF elimination is a fundamental reliability engineering practice.

**Implications**
- All critical components (load balancers, databases, queues, compute, network) must be deployed in active-active or active-passive redundant configuration.
- Geographic redundancy must be applied for the highest-criticality systems.
- SPOF analysis must be documented and reviewed as part of every architecture review.
- Single DNS records, single network paths, and single database instances are not acceptable for production systems.

**Items to Verify in Review**
- [ ] Is a SPOF analysis documented for all critical infrastructure components?
- [ ] Are all critical components deployed in redundant configuration?
- [ ] Are active-active or active-passive failover patterns applied?
- [ ] Is geographic redundancy applied for critical systems?
- [ ] Are network paths redundant (multiple uplinks, BGP failover)?

---

### I-10 — Interoperability (Infrastructure)

**Statement**
Infrastructure must support interoperability with existing enterprise platforms, tooling, and future technology choices through the use of open standards, standard APIs, and infrastructure abstraction layers.

**Rationale**
Proprietary infrastructure lock-in increases switching cost and reduces flexibility. Interoperable infrastructure enables technology evolution without full replacement.

**Implications**
- Open infrastructure standards and APIs must be preferred (Kubernetes, Terraform, OpenTelemetry).
- Infrastructure abstraction layers must be used to insulate applications from infrastructure specifics.
- Vendor lock-in risks must be assessed and managed in infrastructure choices.
- Infrastructure interoperability must be tested when integrating with enterprise shared services.

**Items to Verify in Review**
- [ ] Are open infrastructure standards and APIs used?
- [ ] Is infrastructure abstraction applied to insulate applications from infrastructure specifics?
- [ ] Are vendor lock-in risks assessed and documented?
- [ ] Does the infrastructure integrate with enterprise shared services (monitoring, security, identity)?

---

## APPENDIX: PRINCIPLE QUICK REFERENCE

| ID | Principle | Category | ARB Weight |
|---|---|---|---|
| G-01 | Focus On Customer | General | Medium |
| G-02 | Bias For Action | General | Medium |
| G-03 | Think Globally, Act Locally | General | High |
| G-04 | Design For Reliability | General | **Critical** |
| G-05 | Treat Data As An Asset | General | High |
| G-06 | Secure From Start | General | **Critical** |
| G-07 | Reuse, Buy, Build | General | High |
| G-08 | Drive For Ease of Use | General | Medium |
| G-09 | Strong Design Foundations | General | High |
| G-10 | Anticipate And Plan For Change | General | High |
| B-01 | Customer-Centricity | Business | High |
| B-02 | Regulatory Compliance | Business | **Critical** |
| B-03 | Operational Efficiency | Business | Medium |
| B-04 | Agility and Flexibility | Business | High |
| B-05 | Risk Management | Business | **Critical** |
| B-06 | Data-Driven Decision Making | Business | High |
| B-07 | Innovation | Business | Medium |
| B-08 | Collaboration and Integration | Business | High |
| B-09 | Customer Privacy | Business | **Critical** |
| B-10 | Sustainability | Business | Low |
| S-01 | Defense in Depth | Security | **Critical** |
| S-02 | Least Privilege | Security | **Critical** |
| S-03 | Data Encryption | Security | **Critical** |
| S-04 | Identity and Access Management | Security | **Critical** |
| S-05 | Security by Design | Security | **Critical** |
| S-06 | Continuous Monitoring | Security | High |
| S-07 | Incident Response | Security | High |
| S-08 | Security Awareness Training | Security | Medium |
| S-09 | Compliance (Security) | Security | **Critical** |
| S-10 | Regular Audits and Assessments | Security | High |
| A-01 | Interoperability | Application | High |
| A-02 | Scalability | Application | High |
| A-03 | Modularity | Application | High |
| A-04 | User-Centric Design | Application | Medium |
| A-05 | Cloud Enabled and Native | Application | High |
| A-06 | APIs and Microservices | Application | High |
| A-07 | Data Integrity | Application | **Critical** |
| A-08 | Compliance (Application) | Application | **Critical** |
| A-09 | High Availability | Application | **Critical** |
| A-10 | Performance Optimization | Application | High |
| SW-01 | Separation of Concerns | Software | High |
| SW-02 | Single Responsibility Principle | Software | High |
| SW-03 | Encapsulation | Software | Medium |
| SW-04 | Abstraction | Software | Medium |
| SW-05 | Design for Change | Software | High |
| SW-06 | Portability | Software | High |
| SW-07 | Loose Coupling | Software | High |
| SW-08 | Code Readability | Software | Medium |
| SW-09 | Testability | Software | High |
| SW-10 | Dependency Injection | Software | Medium |
| D-01 | Quality | Data | High |
| D-02 | Governance | Data | **Critical** |
| D-03 | Integration | Data | High |
| D-04 | Single Source of Truth | Data | High |
| D-05 | Accessibility | Data | Medium |
| D-06 | Retention and Disposal | Data | **Critical** |
| D-07 | Master Data Management | Data | High |
| D-08 | Analytics | Data | Medium |
| D-09 | Lineage | Data | High |
| D-10 | Interoperability | Data | Medium |
| I-01 | Scalability | Infrastructure | High |
| I-02 | Reliability | Infrastructure | **Critical** |
| I-03 | Standardization | Infrastructure | High |
| I-04 | Cost Efficiency | Infrastructure | Medium |
| I-05 | Energy Efficiency | Infrastructure | Low |
| I-06 | Cloud Integration | Infrastructure | High |
| I-07 | Automation | Infrastructure | High |
| I-08 | Resilience | Infrastructure | **Critical** |
| I-09 | No Single Point of Failure | Infrastructure | **Critical** |
| I-10 | Interoperability | Infrastructure | Medium |

> **ARB Weight Legend**: **Critical** — blocking for approval · **High** — must be addressed · **Medium** — should be addressed · **Low** — noted for improvement

---

*Document Owner: Enterprise Architecture*
*Review Cadence: Annual or on significant regulatory / technology change*
*Version: 1.0*
