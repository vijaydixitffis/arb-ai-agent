# Integration Architecture Principles Knowledge Base

> **Purpose**: This document serves as the authoritative knowledge base of Integration Architecture principles used by the Pre-ARB AI Agent for compliance validation, alignment checks, and architecture review scoring. Each principle follows a structured format to enable precise LLM retrieval and assessment.
>
> **Structure per principle**: Statement · Rationale · Implications · Items to Verify in Review
>
> **Categories**: General · API-Based · File-Based · Message-Based · Security · Governance · Operations

---

## CATEGORY 1: GENERAL PRINCIPLES

---

### INT-01 — API Gateway Mediation

**Statement**
All external and cross-domain integrations must be mediated through the enterprise API Gateway. Direct peer-to-peer integrations between services are prohibited unless an explicit waiver is granted.

**Rationale**
API Gateway provides centralized control, security, monitoring, and governance for all integrations. Direct peer-to-point integrations create security blind spots, prevent consistent policy enforcement, and increase operational complexity.

**Implications**
- All APIs exposed to external consumers or other domains must be registered and published through the API Gateway.
- Internal cross-domain integrations must also route through the API Gateway or an approved integration platform.
- Peer-to-peer integrations require documented justification and EA waiver approval.
- API Gateway policies (rate limiting, authentication, routing) must be applied consistently.

**Items to Verify in Review**
- [ ] Are all integrations routed through the enterprise API Gateway?
- [ ] Is the API Gateway registered in the integration catalogue with provider and consumer details?
- [ ] Are there any peer-to-peer integrations? If so, is an EA waiver documented?
- [ ] Are API Gateway policies (rate limits, auth, routing) configured and tested?
- [ ] Is the integration catalogue complete and up-to-date?

---

### INT-02 — Standard Protocols and Formats

**Statement**
All integrations must use standard, enterprise-approved protocols and data formats. Proprietary or custom protocols are prohibited unless no standard alternative exists and an exception is approved.

**Rationale**
Standard protocols ensure interoperability, reduce integration complexity, and enable tooling support. Custom protocols increase maintenance burden and create vendor lock-in.

**Implications**
- REST/HTTP for synchronous APIs must follow OpenAPI/Swagger standards.
- Asynchronous integrations must use approved message brokers (Kafka, RabbitMQ) with standard message formats.
- gRPC may be used for high-performance internal microservice communication.
- Data exchange formats must be JSON (REST) or Protobuf (gRPC) — XML is deprecated.

**Items to Verify in Review**
- [ ] Are REST APIs documented with OpenAPI/Swagger specifications?
- [ ] Are message formats following enterprise standards (Avro, Protobuf, JSON Schema)?
- [ ] Are any custom protocols used? If so, is there documented justification?
- [ ] Is XML avoided in new integrations?
- [ ] Are protocol choices aligned with enterprise integration standards?

---

### INT-03 — Integration Catalogue Completeness

**Statement**
All integrations must be registered in the enterprise integration catalogue with complete metadata including provider, consumer, data flows, frequency, and SLA.

**Rationale**
The integration catalogue is the single source of truth for the enterprise integration landscape. Incomplete catalogues lead to unknown dependencies, impact analysis failures, and security risks.

**Implications**
- Every integration must have a catalogue entry before go-live.
- Catalogue must include: provider system, consumer system, API endpoint, data schema, frequency, SLA, owner.
- Catalogue must be kept current — stale entries must be removed or updated.
- Changes to integrations must trigger catalogue updates.

**Items to Verify in Review**
- [ ] Is every integration registered in the enterprise integration catalogue?
- [ ] Are catalogue entries complete (provider, consumer, data flows, frequency, SLA, owner)?
- [ ] Is the integration catalogue current (no stale or orphaned entries)?
- [ ] Are integration changes reflected in catalogue updates?
- [ ] Is there an owner assigned to each integration?

---

### INT-04 — Consumer-Driven Contract Testing

**Statement**
All integrations must implement consumer-driven contract testing to ensure provider changes do not break consumers. Tests must be automated and run in CI/CD pipelines.

**Rationale**
Provider changes often break consumers in unpredictable ways. Consumer-driven contracts shift validation left, catching compatibility issues before deployment and reducing integration failures.

**Implications**
- Consumers must define contract expectations (request/response schemas, error codes).
- Providers must validate against consumer contracts before deploying changes.
- Contract tests must be automated and integrated into CI/CD pipelines.
- Contract violations must block provider deployments unless explicitly waived.

**Items to Verify in Review**
- [ ] Are consumer contracts defined for all integrations?
- [ ] Are contract tests automated and integrated into CI/CD?
- [ ] Do providers validate against consumer contracts before deployment?
- [ ] Is there a process for handling contract violations?
- [ ] Are contract changes communicated to all affected consumers?

---

### INT-05 — Idempotency

**Statement**
All integration endpoints must be idempotent. Repeating the same request multiple times must not cause duplicate processing or inconsistent state.

**Rationale**
Network failures, timeouts, and retries are common. Without idempotency, retries cause duplicate transactions, data corruption, and financial inconsistencies.

**Implications**
- All write operations (POST, PUT, DELETE) must be designed with idempotency in mind.
- Idempotency keys must be supported for all state-changing operations.
- GET requests must be truly idempotent (no side effects).
- Idempotency must be tested as part of integration testing.

**Items to Verify in Review**
- [ ] Are all write operations idempotent?
- [ ] Are idempotency keys supported for state-changing operations?
- [ ] Are GET operations side-effect free?
- [ ] Is idempotency tested and documented?
- [ ] Are retry policies defined and safe?

---

## CATEGORY 2: API-BASED INTEGRATIONS

---

### API-01 — RESTful Design

**Statement**
REST APIs must follow RESTful design principles including resource-oriented URLs, proper HTTP methods, status codes, and HATEOAS where applicable.

**Rationale**
RESTful design ensures consistency, predictability, and ease of use. Deviating from REST principles confuses consumers and increases integration complexity.

**Implications**
- URLs must be resource-oriented (nouns, not verbs).
- HTTP methods must be used correctly (GET for read, POST for create, PUT/PATCH for update, DELETE for delete).
- HTTP status codes must be semantically correct (200 for success, 400 for client error, 500 for server error).
- Responses must include appropriate metadata (pagination, links, timestamps).

**Items to Verify in Review**
- [ ] Are URLs resource-oriented (no verbs in URLs)?
- [ ] Are HTTP methods used correctly?
- [ ] Are HTTP status codes semantically correct?
- [ ] Do responses include appropriate metadata (pagination, links)?
- [ ] Is the API design consistent across all endpoints?

---

### API-02 — Versioning Strategy

**Statement**
All APIs must be versioned using a clear, documented strategy. Breaking changes require a new version. Backward compatibility must be maintained for at least one major version.

**Rationale**
APIs evolve over time. Without versioning, changes break consumers unpredictably. Versioning provides stability and enables controlled evolution.

**Implications**
- API version must be included in the URL (e.g., /api/v1/resource) or header.
- Breaking changes must increment the major version.
- Non-breaking changes may increment the minor version.
- Previous major versions must be supported for a minimum deprecation period (typically 12 months).
- Deprecation notices must be communicated to all consumers.

**Items to Verify in Review**
- [ ] Is API versioning strategy documented and applied?
- [ ] Are breaking changes handled through new major versions?
- [ ] Is backward compatibility maintained for at least one previous version?
- [ ] Are deprecation timelines defined and communicated?
- [ ] Are consumers notified of version changes?

---

### API-03 — Consistent Error Handling

**Statement**
All APIs must use consistent error response formats, error codes, and error messages. Errors must be actionable and include sufficient context for debugging.

**Rationale**
Inconsistent error handling frustrates consumers, complicates integration, and increases support overhead. Standardized error formats enable automated error handling.

**Implications**
- Error responses must follow enterprise error schema (code, message, details, request_id).
- Error codes must be documented and stable.
- Error messages must be actionable and include context (what happened, why, how to fix).
- HTTP status codes must align with error semantics.
- Request IDs must be included for traceability.

**Items to Verify in Review**
- [ ] Do error responses follow the enterprise error schema?
- [ ] Are error codes documented and stable?
- [ ] Are error messages actionable and include context?
- [ ] Do HTTP status codes align with error semantics?
- [ ] Are request IDs included for traceability?

---

### API-04 — Rate Limiting and Throttling

**Statement**
All APIs must implement rate limiting and throttling to protect against abuse, ensure fair resource allocation, and prevent cascading failures.

**Rationale**
Without rate limiting, a single consumer can degrade service for all. Rate limiting protects system stability and ensures equitable access.

**Implications**
- Rate limits must be defined per API endpoint (requests per minute/hour).
- Rate limits must be communicated to consumers via headers (X-RateLimit-Limit, X-RateLimit-Remaining).
- Throttling must return HTTP 429 with Retry-After header.
- Rate limits must be configurable per consumer tier.
- Rate limiting must be implemented at the API Gateway.

**Items to Verify in Review**
- [ ] Are rate limits defined and implemented for all endpoints?
- [ ] Are rate limits communicated via response headers?
- [ ] Does throttling return HTTP 429 with Retry-After?
- [ ] Are rate limits configurable per consumer?
- [ ] Is rate limiting implemented at the API Gateway?

---

### API-05 — Pagination

**Statement**
List endpoints that may return large datasets must implement pagination. Default page sizes must be reasonable, and maximum page sizes must be enforced.

**Rationale**
Unpaginated lists cause performance issues, timeouts, and excessive memory consumption. Pagination enables efficient data retrieval.

**Implications**
- List endpoints must support pagination parameters (page, page_size or offset, limit).
- Default page size must be between 10-50 items.
- Maximum page size must be enforced (typically 100-500 items).
- Pagination metadata must include total count, total pages, and links to next/previous pages.
- Cursor-based pagination must be considered for large, real-time datasets.

**Items to Verify in Review**
- [ ] Do list endpoints implement pagination?
- [ ] Are default and maximum page sizes defined and enforced?
- [ ] Is pagination metadata included in responses?
- [ ] Is cursor-based pagination used for large datasets where appropriate?
- [ ] Are pagination parameters validated?

---

### API-06 — OpenAPI Documentation

**Statement**
All APIs must be documented using OpenAPI/Swagger specifications. Documentation must be complete, accurate, and published to the enterprise API catalogue.

**Rationale**
Complete API documentation enables self-service integration, reduces support overhead, and ensures accurate consumer understanding of API contracts.

**Implications**
- OpenAPI/Swagger spec must be complete (endpoints, methods, schemas, examples, authentication).
- Documentation must be auto-generated from code where possible.
- Documentation must be published to the enterprise API catalogue.
- Documentation must be kept current with code changes.
- Consumer guides and examples must be provided.

**Items to Verify in Review**
- [ ] Is OpenAPI/Swagger spec complete and accurate?
- [ ] Is documentation auto-generated from code?
- [ ] Is documentation published to the enterprise API catalogue?
- [ ] Is documentation kept current with code changes?
- [ ] Are consumer guides and examples available?

---

## CATEGORY 3: FILE-BASED INTEGRATIONS

---

### FILE-01 — Standard File Formats

**Statement**
File-based integrations must use standard, enterprise-approved file formats. Custom or proprietary file formats are prohibited unless no standard alternative exists and an exception is approved.

**Rationale**
Standard file formats ensure interoperability, reduce parsing complexity, and enable tooling support. Custom formats increase maintenance burden and create vendor lock-in.

**Implications**
- CSV must follow enterprise CSV standards (encoding, delimiters, headers, date formats).
- JSON must follow enterprise JSON schema standards.
- XML must follow enterprise XML schema definitions (XSD).
- Flat files must use fixed-width or delimited formats with documented specifications.
- File encoding must be UTF-8 unless legacy requirements mandate otherwise.

**Items to Verify in Review**
- [ ] Are file formats standard and enterprise-approved?
- [ ] Do CSV files follow enterprise standards (encoding, delimiters, headers)?
- [ ] Are JSON files validated against enterprise schemas?
- [ ] Are XML files validated against XSD schemas?
- [ ] Is file encoding UTF-8 or documented exception?

---

### FILE-02 — File Naming Conventions

**Statement**
All files used in integrations must follow enterprise file naming conventions including timestamps, system identifiers, and clear purpose indicators.

**Rationale**
Consistent file naming enables automated processing, prevents file collisions, and simplifies troubleshooting. Ad-hoc naming causes operational issues.

**Implications**
- File names must include: source system, target system, timestamp, file type identifier.
- Timestamps must use ISO 8601 format (YYYYMMDDHHMMSS).
- File names must not contain spaces or special characters (use underscores or hyphens).
- File extensions must match the actual file format.
- File naming conventions must be documented and enforced.

**Items to Verify in Review**
- [ ] Do file names follow enterprise naming conventions?
- [ ] Do file names include source system, target system, timestamp?
- [ ] Are timestamps in ISO 8601 format?
- [ ] Do file names avoid spaces and special characters?
- [ ] Are file naming conventions documented?

---

### FILE-03 — File Size and Volume Limits

**Statement**
File-based integrations must define and enforce file size limits and volume thresholds. Large files must be split into manageable chunks.

**Rationale**
Unlimited file sizes cause processing failures, timeouts, and system instability. Size limits ensure reliable processing and predictable resource usage.

**Implications**
- Maximum file size must be defined (typically 100MB-1GB depending on use case).
- Files exceeding limits must be rejected with clear error messages.
- Large datasets must be split into multiple files with sequence numbers.
- File volume limits must be defined (max files per day/hour).
- File size and volume must be monitored and alerted.

**Items to Verify in Review**
- [ ] Are maximum file size limits defined and enforced?
- [ ] Are large files rejected with clear error messages?
- [ ] Are large datasets split into multiple files?
- [ ] Are file volume limits defined and enforced?
- [ ] Are file size and volume monitored?

---

### FILE-04 — File Validation

**Statement**
All files must be validated before processing. Validation must check format, schema, completeness, and data quality. Invalid files must be rejected with detailed error reports.

**Rationale**
Processing invalid files causes data corruption, system errors, and manual cleanup. Validation ensures only valid files enter the processing pipeline.

**Implications**
- Files must be validated for format (CSV, JSON, XML structure).
- Files must be validated against schema (field names, data types, required fields).
- Files must be validated for completeness (record counts, checksums).
- Validation errors must be detailed (line number, field name, error description).
- Invalid files must be quarantined and reported to source system.

**Items to Verify in Review**
- [ ] Are files validated for format before processing?
- [ ] Are files validated against schema?
- [ ] Are files validated for completeness (checksums, record counts)?
- [ ] Are validation errors detailed and actionable?
- [ ] Are invalid files quarantined and reported?

---

### FILE-05 — Secure File Transfer

**Statement**
All file transfers must use secure protocols (SFTP, HTTPS, AS2). Unencrypted file transfers (FTP, HTTP) are prohibited for any data beyond public information.

**Rationale**
Unencrypted file transfers expose data to interception and tampering. Secure protocols protect data in transit and ensure integrity.

**Implications**
- File transfers must use SFTP, HTTPS, or AS2 for all non-public data.
- FTP and unencrypted HTTP are prohibited.
- File integrity must be verified (checksums, digital signatures).
- Transfer logs must be maintained for audit.
- Failed transfers must be retried with appropriate backoff.

**Items to Verify in Review**
- [ ] Are file transfers using secure protocols (SFTP, HTTPS, AS2)?
- [ ] Are FTP and unencrypted HTTP avoided?
- [ ] Is file integrity verified (checksums, signatures)?
- [ ] Are transfer logs maintained for audit?
- [ ] Are failed transfers retried with backoff?

---

### FILE-06 — File Archival and Retention

**Statement**
Processed files must be archived according to data retention policies. Archive location, retention period, and disposal process must be defined.

**Rationale**
Files must be retained for audit, reconciliation, and regulatory compliance. Unmanaged file accumulation creates storage costs and compliance risk.

**Implications**
- Archive location must be defined (cold storage, archive tier).
- Retention period must align with data classification (e.g., 7 years for regulated data).
- Archive must be immutable (write-once, read-many).
- Disposal process must be automated and documented.
- Archive access must be logged and audited.

**Items to Verify in Review**
- [ ] Is archive location defined and configured?
- [ ] Are retention periods aligned with data classification?
- [ ] Is archive immutable (write-once, read-many)?
- [ ] Is disposal process automated and documented?
- [ ] Is archive access logged and audited?

---

## CATEGORY 4: MESSAGE-BASED INTEGRATIONS

---

### MSG-01 — Standard Message Formats

**Statement**
Message-based integrations must use standard, enterprise-approved message formats. Message schemas must be defined, versioned, and published to the enterprise schema registry.

**Rationale**
Standard message formats ensure interoperability, enable schema evolution, and reduce integration complexity. Custom formats create maintenance burden.

**Implications**
- Message schemas must be defined using Avro, Protobuf, or JSON Schema.
- Schemas must be registered in the enterprise schema registry.
- Schemas must be versioned with backward compatibility policies.
- Schema changes must follow evolution rules (additive changes preferred).
- Schema documentation must be complete and accessible.

**Items to Verify in Review**
- [ ] Are message schemas defined using enterprise-approved formats?
- [ ] Are schemas registered in the enterprise schema registry?
- [ ] Are schemas versioned with backward compatibility policies?
- [ ] Do schema changes follow evolution rules?
- [ ] Is schema documentation complete and accessible?

---

### MSG-02 — Message Broker Selection

**Statement**
Message-based integrations must use enterprise-approved message brokers (Kafka, RabbitMQ). Broker selection must align with use case requirements (throughput, latency, ordering guarantees).

**Rationale**
Standard message brokers reduce operational complexity, enable shared infrastructure, and ensure support availability. Custom broker choices increase TCO.

**Implications**
- Kafka must be used for high-throughput, streaming use cases.
- RabbitMQ must be used for traditional messaging and routing scenarios.
- Broker selection must be justified against use case requirements.
- Broker configuration must follow enterprise standards.
- Broker capacity must be provisioned appropriately.

**Items to Verify in Review**
- [ ] Is the message broker enterprise-approved?
- [ ] Is broker selection justified against use case requirements?
- [ ] Does broker configuration follow enterprise standards?
- [ ] Is broker capacity appropriately provisioned?
- [ ] Are broker alternatives considered and documented?

---

### MSG-03 — Topic/Queue Naming Conventions

**Statement**
All topics and queues must follow enterprise naming conventions including environment, domain, purpose, and version indicators.

**Rationale**
Consistent naming enables automated discovery, prevents collisions, and simplifies operations. Ad-hoc naming causes confusion and errors.

**Implications**
- Topic/queue names must follow pattern: {environment}.{domain}.{purpose}.{version}
- Names must be lowercase with hyphens or underscores as separators.
- Names must be descriptive and avoid abbreviations.
- Naming conventions must be documented and enforced.
- Reserved prefixes must be avoided (e.g., internal, system).

**Items to Verify in Review**
- [ ] Do topic/queue names follow enterprise naming conventions?
- [ ] Are names descriptive and avoid abbreviations?
- [ ] Are naming conventions documented?
- [ ] Are reserved prefixes avoided?
- [ ] Is naming enforced through governance?

---

### MSG-04 — Message Ordering

**Statement**
Message ordering requirements must be explicitly defined. Where ordering is required, appropriate mechanisms (partitioning, sequence IDs) must be implemented.

**Rationale**
Not all use cases require ordered processing. Unnecessary ordering constraints reduce throughput and increase complexity. Explicit requirements ensure appropriate design.

**Implications**
- Ordering requirements must be documented per topic/queue.
- Where ordering is required, partition keys must be used appropriately.
- Sequence IDs must be used where partitioning is insufficient.
- Ordering guarantees must be tested and validated.
- Consumers must handle out-of-order messages where ordering is not guaranteed.

**Items to Verify in Review**
- [ ] Are ordering requirements documented per topic/queue?
- [ ] Are partition keys used where ordering is required?
- [ ] Are sequence IDs used where partitioning is insufficient?
- [ ] Are ordering guarantees tested?
- [ ] Do consumers handle out-of-order messages appropriately?

---

### MSG-05 — Dead Letter Queues

**Statement**
All message consumers must implement dead letter queues (DLQ) for messages that cannot be processed. DLQ processing must be monitored and have defined remediation procedures.

**Rationale**
Without DLQs, failed messages are lost or cause infinite retry loops. DLQs enable error recovery, debugging, and data loss prevention.

**Implications**
- DLQs must be configured for all consumers.
- DLQ must include original message, error details, retry count, timestamp.
- DLQ must be monitored for size and alert thresholds.
- DLQ processing procedures must be defined (reprocess, manual investigation, discard).
- DLQ messages must have defined retention and disposal policies.

**Items to Verify in Review**
- [ ] Are DLQs configured for all consumers?
- [ ] Do DLQs include error details and retry information?
- [ ] Are DLQs monitored and alerted?
- [ ] Are DLQ processing procedures defined?
- [ ] Are DLQ retention and disposal policies defined?

---

### MSG-06 — Exactly-Once Semantics

**Statement**
Where data duplication is unacceptable, message-based integrations must implement exactly-once semantics using idempotent consumers or transactional messaging.

**Rationale**
At-least-once delivery can cause duplicate processing. Exactly-once semantics ensure data integrity for critical business operations.

**Implications**
- Idempotent consumers must be preferred where possible.
- Transactional messaging must be used where idempotency is not feasible.
- Duplicate detection must be implemented using unique message IDs.
- Exactly-once semantics must be tested and validated.
- Performance impact of exactly-once mechanisms must be assessed.

**Items to Verify in Review**
- [ ] Are consumers idempotent where possible?
- [ ] Is transactional messaging used where idempotency is not feasible?
- [ ] Is duplicate detection implemented?
- [ ] Are exactly-once semantics tested?
- [ ] Is performance impact assessed?

---

## CATEGORY 5: SECURITY PRINCIPLES

---

### SEC-01 — Authentication and Authorization

**Statement**
All integrations must authenticate using enterprise-approved mechanisms (OAuth 2.0, JWT, mTLS). Authorization must be implemented using RBAC with least privilege.

**Rationale**
Unauthenticated integrations are security risks. Consistent auth/authz ensures that only authorized systems can access data and functions.

**Implications**
- External integrations must use OAuth 2.0 with client credentials or JWT.
- Internal integrations must use service accounts with scoped permissions or mTLS.
- Authorization must be RBAC-based with principle of least privilege.
- Tokens must have reasonable expiration (no permanent tokens).
- Token refresh must be handled securely.

**Items to Verify in Review**
- [ ] Are all integrations authenticated using enterprise-approved mechanisms?
- [ ] Is authorization RBAC-based with least privilege?
- [ ] Are token expirations reasonable and not permanent?
- [ ] Is token refresh handled securely?
- [ ] Are credentials managed via approved vaults (no hardcoded secrets)?

---

### SEC-02 — Mutual TLS (mTLS)

**Statement**
High-security integrations (financial, regulated data, cross-domain) must implement mutual TLS for both authentication and encryption in addition to standard TLS.

**Rationale**
mTLS provides stronger authentication by validating both client and server identities. It prevents man-in-the-middle attacks and is required for high-security scenarios.

**Implications**
- mTLS must be implemented for financial, regulated, or cross-domain integrations.
- Certificates must be issued by enterprise PKI.
- Certificate rotation must be automated.
- Certificate revocation must be checked (CRL or OCSP).
- mTLS must be configured at the API Gateway.

**Items to Verify in Review**
- [ ] Is mTLS implemented for high-security integrations?
- [ ] Are certificates issued by enterprise PKI?
- [ ] Is certificate rotation automated?
- [ ] Is certificate revocation checked?
- [ ] Is mTLS configured at the API Gateway?

---

### SEC-03 — Input Validation

**Statement**
All integration endpoints must validate input data against schemas before processing. Validation must fail securely (reject invalid data, do not attempt to sanitize).

**Rationale**
Input validation prevents injection attacks, data corruption, and system crashes. Fail-secure validation ensures that invalid data cannot cause unintended behavior.

**Implications**
- Input schemas must be defined (JSON Schema, Protobuf, Avro).
- Validation must reject invalid data with clear error messages.
- Validation must occur before any business logic.
- Schema validation must be automated in CI/CD.
- Schema changes must be versioned and communicated to consumers.

**Items to Verify in Review**
- [ ] Are input schemas defined for all endpoints?
- [ ] Is input validation implemented before business logic?
- [ ] Does validation reject invalid data with clear errors?
- [ ] Is schema validation automated in CI/CD?
- [ ] Are schema changes versioned and communicated?

---

### SEC-04 — Secrets Management

**Statement**
All secrets (API keys, passwords, certificates) used in integrations must be stored in enterprise-approved vaults. Secrets must never be hardcoded in code or configuration files.

**Rationale**
Hardcoded secrets are a major security risk. Vault-based secret management ensures secrets are rotated, audited, and accessible only to authorized services.

**Implications**
- Secrets must be stored in Azure Key Vault or equivalent.
- Secrets must be injected at runtime (not in code or config files).
- Secret rotation must be automated.
- Secret access must be logged and audited.
- Different environments must use different secrets.

**Items to Verify in Review**
- [ ] Are all secrets stored in enterprise-approved vaults?
- [ ] Are secrets injected at runtime (not in code/config)?
- [ ] Is secret rotation automated?
- [ ] Is secret access logged and audited?
- [ ] Are different environments using different secrets?

---

### SEC-05 — Data Classification Handling

**Statement**
Integrations must respect data classification (Public, Internal, Confidential, Restricted). Data must not be transmitted or stored at lower classification levels than its assigned classification.

**Rationale**
Data classification prevents data leakage and ensures compliance with regulatory requirements. Mishandling classified data creates legal and reputational risk.

**Implications**
- Data classification must be defined for all data exchanged via integration.
- Encrypted transport (TLS 1.2+) is mandatory for Confidential and Restricted data.
- Restricted data may require additional controls (dedicated networks, HSM).
- Data classification must be documented in the integration catalogue.
- Data loss prevention (DLP) must be applied where applicable.

**Items to Verify in Review**
- [ ] Is data classification defined for all exchanged data?
- [ ] Is TLS 1.2+ enforced for Confidential and Restricted data?
- [ ] Are additional controls applied for Restricted data?
- [ ] Is data classification documented in the integration catalogue?
- [ ] Is DLP applied where applicable?

---

## CATEGORY 6: GOVERNANCE PRINCIPLES

---

### GOV-01 — Integration Review

**Statement**
All new integrations must undergo integration review by the Integration Architecture team before go-live. Review must assess compliance with integration principles.

**Rationale**
Integration review ensures that new integrations follow enterprise standards, avoid creating technical debt, and are properly documented in the catalogue.

**Implications**
- Integration review must be completed before go-live.
- Review checklist must cover all integration principles.
- Review findings must be addressed before approval.
- Review must be documented with approval sign-off.
- Exceptions must be documented with rationale and owner.

**Items to Verify in Review**
- [ ] Has integration review been completed before go-live?
- [ ] Does the review checklist cover all integration principles?
- [ ] Are review findings addressed?
- [ ] Is review documented with approval sign-off?
- [ ] Are exceptions documented with rationale?

---

### GOV-02 — SLA Definition

**Statement**
All integrations must have defined Service Level Agreements (SLAs) covering availability, latency, throughput, and error rates. SLAs must be monitored and reported.

**Rationale**
SLAs set clear expectations for integration performance and reliability. Without SLAs, performance issues go undetected and impact business operations.

**Implications**
- SLAs must be defined for availability (e.g., 99.9%), latency (p95, p99), throughput, and error rate.
- SLAs must be documented and communicated to consumers.
- SLAs must be monitored continuously.
- SLA breaches must trigger alerts and incident response.
- SLAs must be reviewed and updated annually.

**Items to Verify in Review**
- [ ] Are SLAs defined (availability, latency, throughput, error rate)?
- [ ] Are SLAs documented and communicated to consumers?
- [ ] Are SLAs monitored continuously?
- [ ] Do SLA breaches trigger alerts?
- [ ] Are SLAs reviewed and updated annually?

---

### GOV-03 — Change Management

**Statement**
Changes to integration contracts, schemas, or endpoints must follow change management process. Changes must be communicated to all affected consumers with adequate notice.

**Rationale**
Unmanaged integration changes break consumers and cause incidents. Change management ensures smooth evolution and minimal disruption.

**Implications**
- Integration changes must be classified (major, minor, patch).
- Major changes must require consumer sign-off.
- Change notices must be sent to all affected consumers with timeline.
- Deprecation periods must be defined (typically 3-12 months).
- Change history must be maintained and auditable.

**Items to Verify in Review**
- [ ] Are integration changes classified (major, minor, patch)?
- [ ] Do major changes require consumer sign-off?
- [ ] Are change notices sent to affected consumers?
- [ ] Are deprecation periods defined and communicated?
- [ ] Is change history maintained and auditable?

---

### GOV-04 — Documentation

**Statement**
All integrations must be documented in the enterprise API catalogue with complete specifications, examples, and consumer guides. Documentation must be kept current.

**Rationale**
Incomplete or outdated documentation impedes adoption, causes errors, and increases support overhead. Good documentation is essential for integration success.

**Implications**
- API documentation must include: endpoints, methods, schemas, examples, authentication, rate limits.
- Documentation must be auto-generated from OpenAPI/Swagger specs where possible.
- Consumer guides must include onboarding steps and examples.
- Documentation must be reviewed and updated with every change.
- Documentation must be accessible to authorized consumers.

**Items to Verify in Review**
- [ ] Is the integration documented in the enterprise API catalogue?
- [ ] Does documentation include endpoints, methods, schemas, examples?
- [ ] Is documentation auto-generated from specs?
- [ ] Are consumer guides available?
- [ ] Is documentation reviewed and updated with changes?

---

### GOV-05 — Sunset Policy

**Statement**
All integrations must have a defined sunset policy for decommissioning. Sunset timelines must be communicated to consumers, and migration paths must be provided.

**Rationale**
Integrations accumulate over time, creating maintenance burden and security risk. Sunset policy ensures clean decommissioning and migration to modern alternatives.

**Implications**
- Sunset dates must be defined for all integrations.
- Sunset must be communicated to consumers at least 6 months in advance.
- Migration paths must be provided to replacement integrations.
- Consumer migration support must be available.
- Sunset process must be documented and followed.

**Items to Verify in Review**
- [ ] Are sunset dates defined for all integrations?
- [ ] Is sunset communicated to consumers at least 6 months in advance?
- [ ] Are migration paths provided to replacement integrations?
- [ ] Is consumer migration support available?
- [ ] Is sunset process documented and followed?

---

## CATEGORY 6: OPERATIONS PRINCIPLES

---

### OPS-01 — Observability

**Statement**
All integrations must implement observability including metrics, logs, and distributed tracing. Observability data must be centralized and accessible.

**Rationale**
Without observability, integration issues are difficult to diagnose and resolve. Comprehensive observability enables rapid incident response and performance optimization.

**Implications**
- Metrics must be collected (request rate, latency, error rate, throughput).
- Logs must be structured, correlated, and include request IDs.
- Distributed tracing must be implemented for multi-service flows.
- Observability data must be centralized (Prometheus, ELK, Jaeger).
- Dashboards must be available for integration health monitoring.

**Items to Verify in Review**
- [ ] Are metrics collected (request rate, latency, error rate)?
- [ ] Are logs structured and correlated with request IDs?
- [ ] Is distributed tracing implemented?
- [ ] Is observability data centralized?
- [ ] Are monitoring dashboards available?

---

### OPS-02 — Health Checks

**Statement**
All integration endpoints must implement health check endpoints that report service health, dependencies, and configuration status.

**Rationale**
Health checks enable automated monitoring, load balancer routing decisions, and rapid incident detection. Without health checks, service status is opaque.

**Implications**
- Health check endpoint must be available (e.g., /health, /healthz).
- Health check must report overall status (healthy, degraded, unhealthy).
- Health check must include dependency health status.
- Health check must be lightweight and fast (sub-second response).
- Load balancers must use health checks for routing decisions.

**Items to Verify in Review**
- [ ] Is a health check endpoint implemented?
- [ ] Does health check report overall status?
- [ ] Does health check include dependency status?
- [ ] Is health check lightweight and fast?
- [ ] Do load balancers use health checks?

---

### OPS-03 — Deployment Automation

**Statement**
Integration deployments must be automated through CI/CD pipelines with automated testing, validation, and rollback capabilities.

**Rationale**
Manual deployments are error-prone and slow. Automated deployments ensure consistency, reduce errors, and enable rapid rollback if issues occur.

**Implications**
- CI/CD pipeline must be implemented for all integrations.
- Automated tests (unit, integration, contract) must run before deployment.
- Deployment must be automated with approval gates.
- Rollback must be automated and one-command.
- Deployment history must be maintained and auditable.

**Items to Verify in Review**
- [ ] Is CI/CD pipeline implemented?
- [ ] Do automated tests run before deployment?
- [ ] Is deployment automated with approval gates?
- [ ] Is rollback automated and one-command?
- [ ] Is deployment history maintained?

---

### OPS-04 — Capacity Planning

**Statement**
Integration capacity must be planned and provisioned based on projected load with appropriate headroom. Capacity must be reviewed quarterly and adjusted as needed.

**Rationale**
Insufficient capacity causes performance degradation and outages. Over-provisioning wastes resources. Capacity planning ensures right-sizing and cost efficiency.

**Implications**
- Capacity must be planned based on projected load (peak, average, growth).
- Headroom must be provisioned (typically 2-3x peak load).
- Auto-scaling must be configured where applicable.
- Capacity must be reviewed quarterly and adjusted.
- Capacity alerts must be configured for threshold breaches.

**Items to Verify in Review**
- [ ] Is capacity planned based on projected load?
- [ ] Is appropriate headroom provisioned?
- [ ] Is auto-scaling configured?
- [ ] Is capacity reviewed quarterly?
- [ ] Are capacity alerts configured?

---

### OPS-05 — Incident Response

**Statement**
Integration teams must have documented incident response procedures including runbooks, escalation paths, and communication templates. Drills must be conducted annually.

**Rationale**
Without incident response procedures, incidents are handled inconsistently, recovery is delayed, and communication is poor. Preparedness reduces incident impact.

**Implications**
- Incident response runbooks must be documented and accessible.
- Escalation paths must be defined and communicated.
- Communication templates must be available for stakeholders.
- Incident drills must be conducted annually.
- Post-incident reviews must be conducted for all major incidents.

**Items to Verify in Review**
- [ ] Are incident response runbooks documented?
- [ ] Are escalation paths defined?
- [ ] Are communication templates available?
- [ ] Are incident drills conducted annually?
- [ ] Are post-incident reviews conducted?

---

## APPENDIX: PRINCIPLE QUICK REFERENCE

| ID | Principle | Category | ARB Weight |
|---|---|---|---|
| INT-01 | API Gateway Mediation | General | **Critical** |
| INT-02 | Standard Protocols and Formats | General | High |
| INT-03 | Integration Catalogue Completeness | General | **Critical** |
| INT-04 | Consumer-Driven Contract Testing | General | High |
| INT-05 | Idempotency | General | High |
| API-01 | RESTful Design | API-Based | High |
| API-02 | Versioning Strategy | API-Based | High |
| API-03 | Consistent Error Handling | API-Based | Medium |
| API-04 | Rate Limiting and Throttling | API-Based | High |
| API-05 | Pagination | API-Based | Medium |
| API-06 | OpenAPI Documentation | API-Based | High |
| FILE-01 | Standard File Formats | File-Based | High |
| FILE-02 | File Naming Conventions | File-Based | Medium |
| FILE-03 | File Size and Volume Limits | File-Based | High |
| FILE-04 | File Validation | File-Based | **Critical** |
| FILE-05 | Secure File Transfer | File-Based | **Critical** |
| FILE-06 | File Archival and Retention | File-Based | Medium |
| MSG-01 | Standard Message Formats | Message-Based | High |
| MSG-02 | Message Broker Selection | Message-Based | High |
| MSG-03 | Topic/Queue Naming Conventions | Message-Based | Medium |
| MSG-04 | Message Ordering | Message-Based | Medium |
| MSG-05 | Dead Letter Queues | Message-Based | High |
| MSG-06 | Exactly-Once Semantics | Message-Based | High |
| SEC-01 | Authentication and Authorization | Security | **Critical** |
| SEC-02 | Mutual TLS (mTLS) | Security | High |
| SEC-03 | Input Validation | Security | **Critical** |
| SEC-04 | Secrets Management | Security | **Critical** |
| SEC-05 | Data Classification Handling | Security | **Critical** |
| GOV-01 | Integration Review | Governance | **Critical** |
| GOV-02 | SLA Definition | Governance | High |
| GOV-03 | Change Management | Governance | High |
| GOV-04 | Documentation | Governance | Medium |
| GOV-05 | Sunset Policy | Governance | Medium |
| OPS-01 | Observability | Operations | High |
| OPS-02 | Health Checks | Operations | High |
| OPS-03 | Deployment Automation | Operations | High |
| OPS-04 | Capacity Planning | Operations | Medium |
| OPS-05 | Incident Response | Operations | High |

> **ARB Weight Legend**: **Critical** — blocking for approval · **High** — must be addressed · **Medium** — should be addressed · **Low** — noted for improvement

---

*Document Owner: Enterprise Architecture - Integration*
*Review Cadence: Annual or on significant regulatory / technology change*
*Version: 1.0*
