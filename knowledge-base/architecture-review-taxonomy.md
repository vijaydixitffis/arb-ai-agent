# Architecture Review Board (ARB) – Taxonomy

> Parsed from architecture review slides covering all architecture views.

---

## 1. Architecture Review Areas – Generic Metrics

### End User Voices
- Top 10 concerns / issues that impact end users
- Wish list aspirations of end users – usability, training
- Support tickets, incidents analysis and insights

### Strategy Impact
- Change in business priority
- Change in business model
- Change in target operating model
- Alignment to target architecture / roadmap

### Documentation
- Adherence to architecture principals – Business, App, Data, Tech
- Adherence to patterns, standards, policies
- Level of documentation

### Process Adherence
- Adherence to PtX process
- RAID logs and decision logs
- Roadmap alignment
- Consolidation, Federation, Standardization

### Economics
- Total cost of ownership
  - Development
  - Maintenance, Support
  - Operations
  - Infra + License + Others
- Budget alignment
- Opportunities for cost optimization

---

## 2. Business Architecture

### What
- Business use cases, capabilities impacted
- Growth / change plans
- Domain model
- Service / Contract / Functions

### Business NFRs
- Security – User password specs / expiry / resets / locks
- Performance & Scalability – Business functions / transaction metrics
- Business continuity
- Analytics / Monetization

### Why
- Why this capability, app or service
- Entry-exit criteria for business functions / metrics
- Business case – relevance or updates
- Business level product lifecycle and Roadmap alignment

### Who
- Actors, Users, Systems and entities involved / impacted
- Roles, User groups involved / impacted
- User geo / regions – Multi-time zones
- Multilingual?
- Multi currency?

### Others
- Operation Time – 24/7, Weekdays etc.
- Business change management
- Target operating model
- Continuity plan
- Reporting and monetization

---

## 3. Application Architecture

### Metadata & Lifecycle
- COTS / Bespoke / Legacy
- Monolith / Microservices
- Technology stack
- Any technology debt?
- Planned SW upgrade, platforms upgrade?
- Dependent Library EOS
- End of life, End of Support, License expiry

### Software Architecture
- Technology choices align to standards; upgrade path and SBOM
- Versioning and backward compatibility; ADRs
- Resilience patterns: timeouts, retries, circuit breakers, idempotency
- Documentation currency: diagrams, ADRs, runbooks, ownership established

### Integration
- Interface Catalog, Events, SLAs, Versioning (API, Files, MSGs)
- Consistent API design: resource modeling, errors, pagination, filtering; security scopes
- Event schemas, registry, compatibility rules; ordering / replay requirements
- Reliability: idempotency, throttling & rate limiting

### Others (Application)
- Usability metrics
- Audits / Logging
- Monitoring, Alerts
- TCO – 3yrs, 5yrs
- Integrations – QoS
- Distributed Cache?
- Notifications / Events?
- Scheduled Jobs / Batches

---

## 4. Integration Catalogue

| Field | Description |
|---|---|
| SR | Serial / Reference number |
| Provider | Providing system / service |
| Consumer | Consuming system / service |
| Pattern, Type, Method | API, File, MSG, Event |
| Async / Batch / Sync / Real-time | Interaction style |
| Frequency | How often |
| What data flows | Data description |
| NFRs | Scalability, Security, Performance, Bandwidth, HA, Redundancy, DR |

---

## 5. NFRs (Quality of Service)

### Scalability & Performance
- Number of users, YoY growth?
- Number of concurrent users
- TPS / API calls per unit
- Response time (< 3 Sec?)
- Long running use cases?
- Batch / Scheduled jobs – peak-off peak?

### HA & Resilience
- Any Single point of Failures?
- HA – Four 9s, Five 9s?
- Failover
- DR, RPO, RTO
- Error handling
- Self healing?
- Cache – Sync
- Reliability, Extensibility, Maintainability

### Security
- Authentication, Authorization
- RBAC, IAM
- Key Vault
- PKI, Encryption
- Certs
- VAPT, End point protection
- Standards and Legal compliance
- Integration security

---

## 6. Data Architecture

### Metadata & Lifecycle
- Data classification and ownerships
- Data usage / mgmt. RnR
- Data lifecycle
- Data sources and data model documentation
- Technology stack
- EoS, EoL, Version upgrades, Platform upgrades etc.

---

## 7. Infra-Technology Architecture

### Metadata & Lifecycle
- Adequacy of environments, platforms and runtimes
- Platform upgrades, EoS, EoL
- Demand, capacity requirements, YoY Growth
- Adequacy of bandwidths for compute, storage and network

### Security
- Authentication, AuthZ
- RBAC
- Key Vault
- PKI, Encryption
- Certs
- VAPT, End point protection
- Standards and Legal compliance
- Integration security

### Others
- Automation, IaaC
- Audits / Logging
- Monitoring, Alerts
- TCO – 3yrs, 5yrs
- Integrations – QoS
- Distributed Cache?
- Notifications / Events?
- Scheduled Jobs / Batches

---

## 8. Engineering & DevSecOps

### DevOps
- 12 Factor compliance
- Version control and branching strategy
- CI-CD pipeline, toolset
- Identity access mgmt.
- Secrets & Config mgmt.
- Build and packaging
- Deployment strategy & release mgmt.
- Templatization, IaaC

### SecOps
- Threat models and mitigations
- Secure code reviews
- Static code analysis – SAST
- DAST
- VAPT
- Environments hardening
- SW Hardening
- Metrics reporting

### Engineering Excellence & SW Quality
- Static code analysis
- LLD reviews
- Code reviews
- Test plans reviews
- Defect tracking metrics
- Automation testing
- API Testing
- Performance testing
- SW Quality metrics reporting
