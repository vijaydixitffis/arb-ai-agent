import React, { useState, useEffect } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { Button } from '../components/ui/Button'
import { Input } from '../components/ui/Input'
import { Textarea } from '../components/ui/Textarea'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { ChevronLeft, ChevronRight, Save, Send, Upload } from 'lucide-react'
import { api } from '../services/api'

const STEPS = [
  { id: 1, title: 'Solution Context', description: 'Project overview and stakeholders' },
  { id: 2, title: 'General', description: 'Generic metrics and cross-cutting concerns' },
  { id: 3, title: 'Business', description: 'Business capabilities and processes' },
  { id: 4, title: 'Application', description: 'Tech stack and patterns' },
  { id: 5, title: 'Integration', description: 'APIs and integration catalogue' },
  { id: 6, title: 'Data', description: 'Classification and lifecycle' },
  { id: 7, title: 'Infra-Technology', description: 'Environments and platform' },
  { id: 8, title: 'Engineering & DevSecOps', description: 'CI/CD and quality gates' },
  { id: 9, title: 'NFRs (Quality of Service)', description: 'Performance and reliability' },
]

const ARTEFACT_TYPES = [
  { value: 't-doc', label: 'Doc', description: 'Document / Report' },
  { value: 't-diag', label: 'Diagram', description: 'Architecture diagram' },
  { value: 't-xls', label: 'Sheet', description: 'Spreadsheet / Register' },
  { value: 't-deck', label: 'Deck', description: 'Presentation' },
  { value: 't-log', label: 'Log', description: 'Log / Tracker' },
]

const ARTEFACTS_BY_DOMAIN = {
  general: [
    { name: 'Architecture Principles Doc', type: 't-doc' },
    { name: 'RAID Log', type: 't-log' },
    { name: 'TCO / Budget Sheet', type: 't-xls' },
    { name: 'Roadmap Deck', type: 't-deck' },
    { name: 'Standards & Policies Doc', type: 't-doc' },
    { name: 'End User Feedback Report', type: 't-doc' },
  ],
  business: [
    { name: 'Business Case / Problem Statement', type: 't-doc' },
    { name: 'Business Requirements Doc (BRD)', type: 't-doc' },
    { name: 'Domain Model Diagram', type: 't-diag' },
    { name: 'Business NFRs Register', type: 't-xls' },
    { name: 'Operating Model Doc', type: 't-doc' },
    { name: 'Business Continuity Plan', type: 't-doc' },
  ],
  application: [
    { name: 'High Level Design (HLD)', type: 't-diag' },
    { name: 'App Architecture Diagram', type: 't-diag' },
    { name: 'Architecture Decision Records (ADRs)', type: 't-doc' },
    { name: 'Tech Debt Register', type: 't-xls' },
    { name: 'Runbooks & Ops Docs', type: 't-doc' },
  ],
  integration: [
    { name: 'Integration Catalogue (Sheet)', type: 't-xls' },
    { name: 'API / Interface Catalog', type: 't-doc' },
  ],
  data: [
    { name: 'Data Architecture Diagram', type: 't-diag' },
    { name: 'Data Classification Register', type: 't-xls' },
    { name: 'Data Governance Doc', type: 't-doc' },
  ],
  infrastructure: [
    { name: 'Infra Architecture Diagram', type: 't-diag' },
    { name: 'Capacity Plan (Sheet)', type: 't-xls' },
    { name: 'Platform Lifecycle Register', type: 't-xls' },
    { name: 'Infra Security Controls Doc', type: 't-doc' },
    { name: 'Automation & IaaC Runbook', type: 't-doc' },
  ],
  devsecops: [
    { name: 'CI-CD Pipeline Diagram', type: 't-diag' },
    { name: 'DevOps Metrics Dashboard / Sheet', type: 't-xls' },
    { name: 'Threat Model Document', type: 't-doc' },
    { name: 'SW Quality Metrics Report', type: 't-xls' },
    { name: 'Secure Code Review Report', type: 't-doc' },
  ],
  nfr: [
    { name: 'NFR Requirements Sheet', type: 't-xls' },
    { name: 'HA & DR Plan', type: 't-doc' },
    { name: 'Security Controls Register', type: 't-xls' },
    { name: 'Performance Baseline Report', type: 't-doc' },
  ],
}

const CHECKLIST_ITEMS = {
  general: {
    'End User Voices': [
      { id: 'gen-euv-1', question: 'Top 10 concerns/issues impacting end users identified?' },
      { id: 'gen-euv-2', question: 'End user wish list aspirations documented?' },
      { id: 'gen-euv-3', question: 'Support tickets and incidents analyzed?' },
    ],
    'Strategy Impact': [
      { id: 'gen-strat-1', question: 'Change in business priority assessed?' },
      { id: 'gen-strat-2', question: 'Change in business model considered?' },
      { id: 'gen-strat-3', question: 'Change in target operating model evaluated?' },
      { id: 'gen-strat-4', question: 'Alignment to target architecture/roadmap verified?' },
    ],
    'Documentation': [
      { id: 'gen-doc-1', question: 'Adherence to architecture principles (Business, App, Data, Tech)?' },
      { id: 'gen-doc-2', question: 'Adherence to patterns, standards, policies?' },
      { id: 'gen-doc-3', question: 'Level of documentation adequate?' },
    ],
    'Process Adherence': [
      { id: 'gen-proc-1', question: 'Adherence to PtX process?' },
      { id: 'gen-proc-2', question: 'RAID logs and decision logs maintained?' },
      { id: 'gen-proc-3', question: 'Roadmap alignment verified?' },
      { id: 'gen-proc-4', question: 'Consolidation, Federation, Standardization considered?' },
    ],
    'Economics': [
      { id: 'gen-eco-1', question: 'Total cost of ownership calculated (Development, Maintenance, Operations)?' },
      { id: 'gen-eco-2', question: 'Budget alignment verified?' },
      { id: 'gen-eco-3', question: 'Opportunities for cost optimization identified?' },
    ],
  },
  business: {
    'What': [
      { id: 'bus-what-1', question: 'Business use cases, capabilities impacted documented?' },
      { id: 'bus-what-2', question: 'Growth/change plans defined?' },
      { id: 'bus-what-3', question: 'Domain model established?' },
      { id: 'bus-what-4', question: 'Service/Contract/Functions documented?' },
    ],
    'Business NFRs': [
      { id: 'bus-nfr-1', question: 'Security - User password specs/expiry/resets/locks defined?' },
      { id: 'bus-nfr-2', question: 'Performance & Scalability - Business functions/transaction metrics defined?' },
      { id: 'bus-nfr-3', question: 'Business continuity plan established?' },
      { id: 'bus-nfr-4', question: 'Analytics/Monetization considered?' },
    ],
    'Why': [
      { id: 'bus-why-1', question: 'Why this capability, app or service justified?' },
      { id: 'bus-why-2', question: 'Entry-exit criteria for business functions/metrics defined?' },
      { id: 'bus-why-3', question: 'Business case relevance or updates documented?' },
      { id: 'bus-why-4', question: 'Business level product lifecycle and roadmap alignment verified?' },
    ],
    'Who': [
      { id: 'bus-who-1', question: 'Actors, Users, Systems and entities involved/impacted identified?' },
      { id: 'bus-who-2', question: 'Roles, User groups involved/impacted documented?' },
      { id: 'bus-who-3', question: 'User geo/regions - Multi-time zones considered?' },
      { id: 'bus-who-4', question: 'Multilingual support required?' },
      { id: 'bus-who-5', question: 'Multi-currency support required?' },
    ],
    'Others': [
      { id: 'bus-oth-1', question: 'Operation Time - 24/7, Weekdays etc. defined?' },
      { id: 'bus-oth-2', question: 'Business change management plan established?' },
      { id: 'bus-oth-3', question: 'Target operating model defined?' },
      { id: 'bus-oth-4', question: 'Continuity plan documented?' },
      { id: 'bus-oth-5', question: 'Reporting and monetization strategy defined?' },
    ],
  },
  application: {
    'Metadata & Lifecycle': [
      { id: 'app-meta-1', question: 'COTS/Bespoke/Legacy classification documented?' },
      { id: 'app-meta-2', question: 'Monolith/Microservices architecture defined?' },
      { id: 'app-meta-3', question: 'Technology stack documented?' },
      { id: 'app-meta-4', question: 'Technology debt identified?' },
      { id: 'app-meta-5', question: 'Planned SW upgrade, platforms upgrade documented?' },
      { id: 'app-meta-6', question: 'Dependent Library EOS tracked?' },
      { id: 'app-meta-7', question: 'End of life, End of Support, License expiry documented?' },
    ],
    'Software Architecture': [
      { id: 'app-soft-1', question: 'Technology choices align to standards; upgrade path and SBOM?' },
      { id: 'app-soft-2', question: 'Versioning and backward compatibility; ADRs?' },
      { id: 'app-soft-3', question: 'Resilience patterns: timeouts, retries, circuit breakers, idempotency?' },
      { id: 'app-soft-4', question: 'Documentation currency: diagrams, ADRs, runbooks, ownership established?' },
    ],
    'Others (Application)': [
      { id: 'app-oth-1', question: 'Usability metrics defined?' },
      { id: 'app-oth-2', question: 'Audits/Logging implemented?' },
      { id: 'app-oth-3', question: 'Monitoring, Alerts configured?' },
      { id: 'app-oth-4', question: 'TCO – 3yrs, 5yrs calculated?' },
      { id: 'app-oth-5', question: 'Integrations – QoS defined?' },
      { id: 'app-oth-6', question: 'Distributed Cache required?' },
      { id: 'app-oth-7', question: 'Notifications/Events implemented?' },
      { id: 'app-oth-8', question: 'Scheduled Jobs/Batches documented?' },
    ],
  },
  integration: {
    'Interface Catalog': [
      { id: 'int-cat-1', question: 'Interface Catalog documented (SR, Provider, Consumer)?' },
      { id: 'int-cat-2', question: 'Pattern, Type, Method defined (API, File, MSG, Event)?' },
      { id: 'int-cat-3', question: 'Interaction style specified (Async/Batch/Sync/Real-time)?' },
      { id: 'int-cat-4', question: 'Frequency documented?' },
      { id: 'int-cat-5', question: 'Data flows described?' },
    ],
    'Interface Checks': [
      { id: 'int-check-1', question: 'Interface Catalog, Events, SLAs, Versioning (API, Files, MSGs)?' },
      { id: 'int-check-2', question: 'Consistent API design: resource modeling, errors, pagination, filtering; security scopes?' },
      { id: 'int-check-3', question: 'Event schemas, registry, compatibility rules; ordering/replay requirements?' },
      { id: 'int-check-4', question: 'Reliability: idempotency, throttling & rate limiting?' },
    ],
    'NFRs': [
      { id: 'int-nfr-1', question: 'Scalability requirements defined?' },
      { id: 'int-nfr-2', question: 'Security requirements specified?' },
      { id: 'int-nfr-3', question: 'Performance metrics defined?' },
      { id: 'int-nfr-4', question: 'Bandwidth requirements documented?' },
      { id: 'int-nfr-5', question: 'HA and Redundancy considered?' },
      { id: 'int-nfr-6', question: 'DR requirements specified?' },
    ],
  },
  data: {
    'Metadata & Lifecycle': [
      { id: 'data-meta-1', question: 'Data classification and ownerships documented?' },
      { id: 'data-meta-2', question: 'Data usage/management RnR defined?' },
      { id: 'data-meta-3', question: 'Data lifecycle established?' },
      { id: 'data-meta-4', question: 'Data sources and data model documentation maintained?' },
      { id: 'data-meta-5', question: 'Technology stack documented?' },
      { id: 'data-meta-6', question: 'EoS, EoL, Version upgrades, Platform upgrades tracked?' },
    ],
  },
  infrastructure: {
    'Metadata & Lifecycle': [
      { id: 'infra-meta-1', question: 'Adequacy of environments, platforms and runtimes assessed?' },
      { id: 'infra-meta-2', question: 'Platform upgrades, EoS, EoL tracked?' },
      { id: 'infra-meta-3', question: 'Demand, capacity requirements, YoY Growth documented?' },
      { id: 'infra-meta-4', question: 'Adequacy of bandwidths for compute, storage and network verified?' },
    ],
    'Security': [
      { id: 'infra-sec-1', question: 'Authentication, AuthZ implemented?' },
      { id: 'infra-sec-2', question: 'RBAC configured?' },
      { id: 'infra-sec-3', question: 'Key Vault used?' },
      { id: 'infra-sec-4', question: 'PKI, Encryption implemented?' },
      { id: 'infra-sec-5', question: 'Certs managed?' },
      { id: 'infra-sec-6', question: 'VAPT, End point protection in place?' },
      { id: 'infra-sec-7', question: 'Standards and Legal compliance verified?' },
      { id: 'infra-sec-8', question: 'Integration security implemented?' },
    ],
    'Others': [
      { id: 'infra-oth-1', question: 'Automation, IaaC implemented?' },
      { id: 'infra-oth-2', question: 'Audits/Logging configured?' },
      { id: 'infra-oth-3', question: 'Monitoring, Alerts set up?' },
      { id: 'infra-oth-4', question: 'TCO – 3yrs, 5yrs calculated?' },
      { id: 'infra-oth-5', question: 'Integrations – QoS defined?' },
      { id: 'infra-oth-6', question: 'Distributed Cache required?' },
      { id: 'infra-oth-7', question: 'Notifications/Events implemented?' },
      { id: 'infra-oth-8', question: 'Scheduled Jobs/Batches documented?' },
    ],
  },
  devsecops: {
    'DevOps': [
      { id: 'devops-1', question: '12 Factor compliance verified?' },
      { id: 'devops-2', question: 'Version control and branching strategy defined?' },
      { id: 'devops-3', question: 'CI-CD pipeline, toolset established?' },
      { id: 'devops-4', question: 'Identity access mgmt. configured?' },
      { id: 'devops-5', question: 'Secrets & Config mgmt. implemented?' },
      { id: 'devops-6', question: 'Build and packaging automated?' },
      { id: 'devops-7', question: 'Deployment strategy & release mgmt. defined?' },
      { id: 'devops-8', question: 'Templatization, IaaC implemented?' },
    ],
    'SecOps': [
      { id: 'secops-1', question: 'Threat models and mitigations documented?' },
      { id: 'secops-2', question: 'Secure code reviews conducted?' },
      { id: 'secops-3', question: 'Static code analysis – SAST integrated?' },
      { id: 'secops-4', question: 'DAST implemented?' },
      { id: 'secops-5', question: 'VAPT completed?' },
      { id: 'secops-6', question: 'Environments hardening applied?' },
      { id: 'secops-7', question: 'SW Hardening implemented?' },
      { id: 'secops-8', question: 'Metrics reporting in place?' },
    ],
    'Engineering Excellence & SW Quality': [
      { id: 'engex-1', question: 'Static code analysis implemented?' },
      { id: 'engex-2', question: 'LLD reviews conducted?' },
      { id: 'engex-3', question: 'Code reviews mandatory?' },
      { id: 'engex-4', question: 'Test plans reviews done?' },
      { id: 'engex-5', question: 'Defect tracking metrics defined?' },
      { id: 'engex-6', question: 'Automation testing implemented?' },
      { id: 'engex-7', question: 'API Testing conducted?' },
      { id: 'engex-8', question: 'Performance testing done?' },
      { id: 'engex-9', question: 'SW Quality metrics reporting in place?' },
    ],
  },
  nfr: {
    'Scalability & Performance': [
      { id: 'nfr-scalar-1', question: 'Number of users, YoY growth documented?' },
      { id: 'nfr-scalar-2', question: 'Number of concurrent users defined?' },
      { id: 'nfr-scalar-3', question: 'TPS / API calls per unit specified?' },
      { id: 'nfr-scalar-4', question: 'Response time (< 3 Sec)?' },
      { id: 'nfr-scalar-5', question: 'Long running use cases identified?' },
      { id: 'nfr-scalar-6', question: 'Batch / Scheduled jobs – peak-off peak considered?' },
    ],
    'HA & Resilience': [
      { id: 'nfr-ha-1', question: 'Any Single point of Failures?' },
      { id: 'nfr-ha-2', question: 'HA – Four 9s, Five 9s?' },
      { id: 'nfr-ha-3', question: 'Failover mechanism defined?' },
      { id: 'nfr-ha-4', question: 'DR, RPO, RTO documented?' },
      { id: 'nfr-ha-5', question: 'Error handling implemented?' },
      { id: 'nfr-ha-6', question: 'Self healing?' },
      { id: 'nfr-ha-7', question: 'Cache – Sync configured?' },
      { id: 'nfr-ha-8', question: 'Reliability, Extensibility, Maintainability considered?' },
    ],
    'Security': [
      { id: 'nfr-sec-1', question: 'Authentication, Authorization implemented?' },
      { id: 'nfr-sec-2', question: 'RBAC, IAM configured?' },
      { id: 'nfr-sec-3', question: 'Key Vault used?' },
      { id: 'nfr-sec-4', question: 'PKI, Encryption implemented?' },
      { id: 'nfr-sec-5', question: 'Certs managed?' },
      { id: 'nfr-sec-6', question: 'VAPT, End point protection in place?' },
      { id: 'nfr-sec-7', question: 'Standards and Legal compliance verified?' },
      { id: 'nfr-sec-8', question: 'Integration security implemented?' },
    ],
  },
}

export default function ARBSubmission() {
  const navigate = useNavigate()
  const location = useLocation()
  const user = useAuthStore((state) => state.user)
  const [currentStep, setCurrentStep] = useState(1)
  const [submissionId, setSubmissionId] = useState<string | null>(null)
  const [selectedSubsection, setSelectedSubsection] = useState<string | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [ptxGate, setPtxGate] = useState<string>('')
  const [architectureDisposition, setArchitectureDisposition] = useState<string>('')

  useEffect(() => {
    if (location.state) {
      setPtxGate(location.state.ptxGate || '')
      setArchitectureDisposition(location.state.architectureDisposition || '')
    }
  }, [location.state])
  const [artefacts, setArtefacts] = useState<Record<string, Array<{ name: string; type: string; fileName: string; file: File | null }>>>({
    general: [],
    business: [],
    application: [],
    integration: [],
    data: [],
    infrastructure: [],
    devsecops: [],
    nfr: [],
  })
  const [newArtefact, setNewArtefact] = useState<{ domain: string; name: string; type: string; fileName: string; file: File | null }>({
    domain: '',
    name: '',
    type: '',
    fileName: '',
    file: null,
  })
  const [formData, setFormData] = useState({
    project_name: '',
    problem_statement: '',
    stakeholders: [] as string[],
    business_drivers: [] as string[],
    growth_plans: '',
    // Domain sections
    general_checklist: {} as Record<string, string>,
    general_evidence: {} as Record<string, string>,
    business_checklist: {} as Record<string, string>,
    business_evidence: {} as Record<string, string>,
    application_checklist: {} as Record<string, string>,
    application_evidence: {} as Record<string, string>,
    integration_checklist: {} as Record<string, string>,
    integration_evidence: {} as Record<string, string>,
    data_checklist: {} as Record<string, string>,
    data_evidence: {} as Record<string, string>,
    infrastructure_checklist: {} as Record<string, string>,
    infrastructure_evidence: {} as Record<string, string>,
    devsecops_checklist: {} as Record<string, string>,
    devsecops_evidence: {} as Record<string, string>,
    nfr_checklist: {} as Record<string, string>,
    nfr_evidence: {} as Record<string, string>,
    nfr_criteria: [] as Array<{ category: string; criteria: string; target_value: string; actual_value: string; score: number; evidence?: string }>,
  })

  const handleNext = () => {
    if (currentStep < STEPS.length) {
      setCurrentStep(currentStep + 1)
    }
  }

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1)
    }
  }

  const handleSaveDraft = async () => {
    try {
      const submissionData = {
        ...formData,
        solution_architect_id: user?.id,
        status: 'draft',
      }

      if (submissionId) {
        await api.updateSubmission(submissionId, submissionData)
      } else {
        const result = await api.createSubmission(submissionData)
        setSubmissionId(result.id)
      }
      alert('Draft saved successfully')
    } catch (error) {
      console.error('Error saving draft:', error)
      alert('Failed to save draft')
    }
  }

  const handleSubmit = async () => {
    try {
      const submissionData = {
        ...formData,
        solution_architect_id: user?.id,
        status: 'submitted',
      }

      if (submissionId) {
        await api.updateSubmission(submissionId, submissionData)
        await api.submitSubmission(submissionId)
      } else {
        const result = await api.createSubmission(submissionData)
        await api.submitSubmission(result.id)
      }

      // Trigger AI agent review
      await api.runARBReview({ submission_id: submissionId || '', domain_sections: formData })

      navigate('/dashboard')
    } catch (error) {
      console.error('Error submitting:', error)
      alert('Failed to submit')
    }
  }

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || !submissionId) return

    try {
      const file = e.target.files[0]
      await api.uploadArtefact(submissionId, file)
      alert('File uploaded successfully')
    } catch (error) {
      console.error('Error uploading file:', error)
      alert('Failed to upload file')
    }
  }

  const calculateProgress = () => {
    const completedSteps = [1, 2, 3, 4, 5, 6, 7, 8, 9].filter(
      (step) => step <= currentStep
    ).length
    return Math.round((completedSteps / STEPS.length) * 100)
  }

  const getArtefactIcon = (type: string) => {
    const icons: Record<string, string> = {
      't-doc': '📄',
      't-diag': '🗺️',
      't-xls': '📊',
      't-deck': '🗺️',
      't-log': '📋',
    }
    return icons[type] || '📄'
  }

  const getArtefactTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      't-doc': 'Doc',
      't-diag': 'Diagram',
      't-xls': 'Sheet',
      't-deck': 'Deck',
      't-log': 'Log',
    }
    return labels[type] || type
  }

  const renderStepContent = () => {
    switch (currentStep) {
      case 1:
        return (
          <div className="space-y-6">
            {(ptxGate || architectureDisposition) && (
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {ptxGate && (
                    <div>
                      <label className="block text-sm font-medium text-blue-900 mb-1">PTX Gate</label>
                      <p className="text-sm text-blue-800">{ptxGate}</p>
                    </div>
                  )}
                  {architectureDisposition && (
                    <div>
                      <label className="block text-sm font-medium text-blue-900 mb-1">Architecture Disposition</label>
                      <p className="text-sm text-blue-800">{architectureDisposition}</p>
                    </div>
                  )}
                </div>
              </div>
            )}
            <div>
              <label className="block text-sm font-medium mb-2">Project Name</label>
              <Input
                value={formData.project_name}
                onChange={(e) => setFormData({ ...formData, project_name: e.target.value })}
                placeholder="Enter project name"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Problem Statement</label>
              <Textarea
                value={formData.problem_statement}
                onChange={(e) => setFormData({ ...formData, problem_statement: e.target.value })}
                placeholder="Describe the problem this solution addresses"
                rows={4}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Stakeholders</label>
              <Textarea
                value={formData.stakeholders.join('\n')}
                onChange={(e) => setFormData({ ...formData, stakeholders: e.target.value.split('\n').filter(s => s.trim()) })}
                placeholder="List key stakeholders (one per line)"
                rows={4}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Business Drivers</label>
              <Textarea
                value={formData.business_drivers.join('\n')}
                onChange={(e) => setFormData({ ...formData, business_drivers: e.target.value.split('\n').filter(s => s.trim()) })}
                placeholder="List business drivers (one per line)"
                rows={4}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Growth Plans</label>
              <Textarea
                value={formData.growth_plans}
                onChange={(e) => setFormData({ ...formData, growth_plans: e.target.value })}
                placeholder="Describe growth plans and scalability requirements"
                rows={3}
              />
            </div>
          </div>
        )
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
        const domainMap: Record<number, { subsections: Record<string, typeof CHECKLIST_ITEMS.general['End User Voices']>; prefix: string }> = {
          2: { subsections: CHECKLIST_ITEMS.general, prefix: 'general' },
          3: { subsections: CHECKLIST_ITEMS.business, prefix: 'business' },
          4: { subsections: CHECKLIST_ITEMS.application, prefix: 'application' },
          5: { subsections: CHECKLIST_ITEMS.integration, prefix: 'integration' },
          6: { subsections: CHECKLIST_ITEMS.data, prefix: 'data' },
          7: { subsections: CHECKLIST_ITEMS.infrastructure, prefix: 'infrastructure' },
          8: { subsections: CHECKLIST_ITEMS.devsecops, prefix: 'devsecops' },
        }
        const domain = domainMap[currentStep]
        return (
          <div className="space-y-6">
            {/* Artefact Upload Section */}
            <div>
              <label className="block text-sm font-medium mb-4">Artefacts</label>
              <div className="bg-gray-50 rounded-lg p-4 mb-4">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <div>
                    <label className="block text-xs font-medium mb-1">Artefact Name</label>
                    <select
                      className="w-full px-3 py-2 border rounded-md text-sm"
                      value={newArtefact.name}
                      onChange={(e) => {
                        const selectedArtefact = ARTEFACTS_BY_DOMAIN[domain.prefix as keyof typeof ARTEFACTS_BY_DOMAIN]?.find(
                          (a: any) => a.name === e.target.value
                        )
                        setNewArtefact({
                          ...newArtefact,
                          name: e.target.value,
                          type: selectedArtefact?.type || '',
                          domain: domain.prefix,
                        })
                      }}
                    >
                      <option value="">Select artefact</option>
                      {ARTEFACTS_BY_DOMAIN[domain.prefix as keyof typeof ARTEFACTS_BY_DOMAIN]?.map((artefact: any) => (
                        <option key={artefact.name} value={artefact.name}>
                          {artefact.name}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-medium mb-1">Artefact Type</label>
                    <select
                      className="w-full px-3 py-2 border rounded-md text-sm"
                      value={newArtefact.type}
                      onChange={(e) => setNewArtefact({ ...newArtefact, type: e.target.value })}
                    >
                      <option value="">Select type</option>
                      {ARTEFACT_TYPES.map((type) => (
                        <option key={type.value} value={type.value}>
                          {type.label}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-medium mb-1">File Name</label>
                    <Input
                      placeholder="Enter file name"
                      value={newArtefact.fileName}
                      onChange={(e) => setNewArtefact({ ...newArtefact, fileName: e.target.value })}
                      className="text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium mb-1">Upload File</label>
                    <input
                      type="file"
                      onChange={(e) => {
                        const file = e.target.files?.[0] || null
                        setNewArtefact({ ...newArtefact, file, fileName: file?.name || newArtefact.fileName })
                      }}
                      className="w-full px-3 py-2 border rounded-md text-sm"
                    />
                  </div>
                </div>
                <Button
                  onClick={() => {
                    if (newArtefact.name && newArtefact.type && newArtefact.fileName) {
                      setArtefacts({
                        ...artefacts,
                        [domain.prefix]: [...artefacts[domain.prefix], newArtefact],
                      })
                      setNewArtefact({ domain: '', name: '', type: '', fileName: '', file: null })
                    }
                  }}
                  className="mt-3"
                  size="sm"
                >
                  Add Artefact
                </Button>
              </div>

              {/* Uploaded Artefacts List */}
              {artefacts[domain.prefix]?.length > 0 && (
                <div className="space-y-2">
                  <label className="block text-xs font-medium">Uploaded Artefacts</label>
                  {artefacts[domain.prefix].map((artefact, index) => (
                    <div key={index} className="flex items-center justify-between bg-white border rounded-md p-3">
                      <div className="flex items-center gap-3">
                        <span className="text-lg">{getArtefactIcon(artefact.type)}</span>
                        <div>
                          <p className="text-sm font-medium">{artefact.name}</p>
                          <p className="text-xs text-muted-foreground">{artefact.fileName}</p>
                        </div>
                      </div>
                      <span className="text-xs px-2 py-1 rounded-full bg-gray-100">{getArtefactTypeLabel(artefact.type)}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="mt-8 border-t pt-6">
              <label className="block text-sm font-medium mb-4">Compliance Checklist</label>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {Object.entries(domain.subsections).map(([subsectionName, questions], index) => {
                  const colors = [
                    'from-blue-50 to-blue-100 border-blue-200 hover:border-blue-400',
                    'from-purple-50 to-purple-100 border-purple-200 hover:border-purple-400',
                    'from-green-50 to-green-100 border-green-200 hover:border-green-400',
                    'from-orange-50 to-orange-100 border-orange-200 hover:border-orange-400',
                    'from-pink-50 to-pink-100 border-pink-200 hover:border-pink-400',
                    'from-cyan-50 to-cyan-100 border-cyan-200 hover:border-cyan-400',
                  ]
                  const colorClass = colors[index % colors.length]

                  return (
                    <div
                      key={subsectionName}
                      onClick={() => {
                        setSelectedSubsection(subsectionName)
                        setIsDialogOpen(true)
                      }}
                      className={`bg-gradient-to-br ${colorClass} border rounded-xl p-5 cursor-pointer hover:shadow-lg hover:scale-105 transition-all duration-200`}
                    >
                      <div className="flex items-start justify-between mb-3">
                        <h4 className="font-semibold text-gray-800">{subsectionName}</h4>
                        <div className="w-8 h-8 rounded-full bg-white/50 flex items-center justify-center">
                          <span className="text-sm font-bold text-gray-600">{questions.length}</span>
                        </div>
                      </div>
                      <p className="text-xs text-gray-600">questions</p>
                      <div className="mt-3 flex items-center text-xs text-gray-500">
                        <span className="mr-2">Click to expand</span>
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            {isDialogOpen && selectedSubsection && (
              <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto">
                  <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold">{selectedSubsection}</h3>
                    <button
                      onClick={() => setIsDialogOpen(false)}
                      className="text-gray-500 hover:text-gray-700"
                    >
                      ✕
                    </button>
                  </div>
                  <div className="space-y-6">
                    {domain.subsections[selectedSubsection].map((question) => {
                      const options = ['compliant', 'non_compliant', 'partial', 'na']
                      const optionLabels = ['Yes', 'No', 'Partial', 'NA']
                      const currentIndex = options.indexOf(formData[`${domain.prefix}_checklist` as keyof typeof formData]?.[question.id] as string) || 0

                      return (
                        <div key={question.id} className="border rounded-lg p-4">
                          <p className="font-medium mb-4">{question.question}</p>
                          <div className="mb-4">
                            <div className="relative">
                              <input
                                type="range"
                                min="0"
                                max="3"
                                step="1"
                                value={currentIndex}
                                onChange={(e) => {
                                  setFormData({
                                    ...formData,
                                    [`${domain.prefix}_checklist`]: {
                                      ...formData[`${domain.prefix}_checklist` as keyof typeof formData],
                                      [question.id]: options[parseInt(e.target.value)],
                                    },
                                  })
                                }}
                                className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
                              />
                              <div className="flex justify-between mt-2 text-xs text-gray-600">
                                {optionLabels.map((label, index) => (
                                  <span key={label} className={currentIndex === index ? 'font-bold text-primary' : ''}>
                                    {label}
                                  </span>
                                ))}
                              </div>
                            </div>
                          </div>
                          <Input
                            placeholder="Evidence notes"
                            value={formData[`${domain.prefix}_evidence` as keyof typeof formData]?.[question.id] || ''}
                            onChange={(e) => {
                              setFormData({
                                ...formData,
                                [`${domain.prefix}_evidence`]: {
                                  ...formData[`${domain.prefix}_evidence` as keyof typeof formData],
                                  [question.id]: e.target.value,
                                },
                              })
                            }}
                            className="text-sm"
                          />
                        </div>
                      )
                    })}
                  </div>
                </div>
              </div>
            )}
          </div>
        )
      case 9:
        const nfrDomain = { subsections: CHECKLIST_ITEMS.nfr, prefix: 'nfr' }
        return (
          <div className="space-y-6">
            {/* Artefact Upload Section */}
            <div>
              <label className="block text-sm font-medium mb-4">Artefacts</label>
              <div className="bg-gray-50 rounded-lg p-4 mb-4">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <div>
                    <label className="block text-xs font-medium mb-1">Artefact Name</label>
                    <select
                      className="w-full px-3 py-2 border rounded-md text-sm"
                      value={newArtefact.name}
                      onChange={(e) => {
                        const selectedArtefact = ARTEFACTS_BY_DOMAIN['nfr']?.find(
                          (a: any) => a.name === e.target.value
                        )
                        setNewArtefact({
                          ...newArtefact,
                          name: e.target.value,
                          type: selectedArtefact?.type || '',
                          domain: 'nfr',
                        })
                      }}
                    >
                      <option value="">Select artefact</option>
                      {ARTEFACTS_BY_DOMAIN['nfr']?.map((artefact: any) => (
                        <option key={artefact.name} value={artefact.name}>
                          {artefact.name}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-medium mb-1">Artefact Type</label>
                    <select
                      className="w-full px-3 py-2 border rounded-md text-sm"
                      value={newArtefact.type}
                      onChange={(e) => setNewArtefact({ ...newArtefact, type: e.target.value })}
                    >
                      <option value="">Select type</option>
                      {ARTEFACT_TYPES.map((type) => (
                        <option key={type.value} value={type.value}>
                          {type.label}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-medium mb-1">File Name</label>
                    <Input
                      placeholder="Enter file name"
                      value={newArtefact.fileName}
                      onChange={(e) => setNewArtefact({ ...newArtefact, fileName: e.target.value })}
                      className="text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium mb-1">Upload File</label>
                    <input
                      type="file"
                      onChange={(e) => {
                        const file = e.target.files?.[0] || null
                        setNewArtefact({ ...newArtefact, file, fileName: file?.name || newArtefact.fileName })
                      }}
                      className="w-full px-3 py-2 border rounded-md text-sm"
                    />
                  </div>
                </div>
                <Button
                  onClick={() => {
                    if (newArtefact.name && newArtefact.type && newArtefact.fileName) {
                      setArtefacts({
                        ...artefacts,
                        nfr: [...artefacts.nfr, newArtefact],
                      })
                      setNewArtefact({ domain: '', name: '', type: '', fileName: '', file: null })
                    }
                  }}
                  className="mt-3"
                  size="sm"
                >
                  Add Artefact
                </Button>
              </div>

              {/* Uploaded Artefacts List */}
              {artefacts.nfr?.length > 0 && (
                <div className="space-y-2">
                  <label className="block text-xs font-medium">Uploaded Artefacts</label>
                  {artefacts.nfr.map((artefact, index) => (
                    <div key={index} className="flex items-center justify-between bg-white border rounded-md p-3">
                      <div className="flex items-center gap-3">
                        <span className="text-lg">{getArtefactIcon(artefact.type)}</span>
                        <div>
                          <p className="text-sm font-medium">{artefact.name}</p>
                          <p className="text-xs text-muted-foreground">{artefact.fileName}</p>
                        </div>
                      </div>
                      <span className="text-xs px-2 py-1 rounded-full bg-gray-100">{getArtefactTypeLabel(artefact.type)}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="mt-8 border-t pt-6">
              <label className="block text-sm font-medium mb-4">NFRs (Quality of Service)</label>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {Object.entries(nfrDomain.subsections).map(([subsectionName, questions], index) => {
                  const colors = [
                    'from-red-50 to-red-100 border-red-200 hover:border-red-400',
                    'from-yellow-50 to-yellow-100 border-yellow-200 hover:border-yellow-400',
                    'from-indigo-50 to-indigo-100 border-indigo-200 hover:border-indigo-400',
                  ]
                  const colorClass = colors[index % colors.length]

                  return (
                    <div
                      key={subsectionName}
                      onClick={() => {
                        setSelectedSubsection(subsectionName)
                        setIsDialogOpen(true)
                      }}
                      className={`bg-gradient-to-br ${colorClass} border rounded-xl p-5 cursor-pointer hover:shadow-lg hover:scale-105 transition-all duration-200`}
                    >
                      <div className="flex items-start justify-between mb-3">
                        <h4 className="font-semibold text-gray-800">{subsectionName}</h4>
                        <div className="w-8 h-8 rounded-full bg-white/50 flex items-center justify-center">
                          <span className="text-sm font-bold text-gray-600">{questions.length}</span>
                        </div>
                      </div>
                      <p className="text-xs text-gray-600">questions</p>
                      <div className="mt-3 flex items-center text-xs text-gray-500">
                        <span className="mr-2">Click to expand</span>
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            {isDialogOpen && selectedSubsection && (
              <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto">
                  <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold">{selectedSubsection}</h3>
                    <button
                      onClick={() => setIsDialogOpen(false)}
                      className="text-gray-500 hover:text-gray-700"
                    >
                      ✕
                    </button>
                  </div>
                  <div className="space-y-6">
                    {nfrDomain.subsections[selectedSubsection].map((question) => {
                      const options = ['compliant', 'non_compliant', 'partial', 'na']
                      const optionLabels = ['Yes', 'No', 'Partial', 'NA']
                      const currentIndex = options.indexOf(formData[`${nfrDomain.prefix}_checklist` as keyof typeof formData]?.[question.id] as string) || 0

                      return (
                        <div key={question.id} className="border rounded-lg p-4">
                          <p className="font-medium mb-4">{question.question}</p>
                          <div className="mb-4">
                            <div className="relative">
                              <input
                                type="range"
                                min="0"
                                max="3"
                                step="1"
                                value={currentIndex}
                                onChange={(e) => {
                                  setFormData({
                                    ...formData,
                                    [`${nfrDomain.prefix}_checklist`]: {
                                      ...formData[`${nfrDomain.prefix}_checklist` as keyof typeof formData],
                                      [question.id]: options[parseInt(e.target.value)],
                                    },
                                  })
                                }}
                                className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
                              />
                              <div className="flex justify-between mt-2 text-xs text-gray-600">
                                {optionLabels.map((label, index) => (
                                  <span key={label} className={currentIndex === index ? 'font-bold text-primary' : ''}>
                                    {label}
                                  </span>
                                ))}
                              </div>
                            </div>
                          </div>
                          <Input
                            placeholder="Evidence notes"
                            value={formData[`${nfrDomain.prefix}_evidence` as keyof typeof formData]?.[question.id] || ''}
                            onChange={(e) => {
                              setFormData({
                                ...formData,
                                [`${nfrDomain.prefix}_evidence`]: {
                                  ...formData[`${nfrDomain.prefix}_evidence` as keyof typeof formData],
                                  [question.id]: e.target.value,
                                },
                              })
                            }}
                            className="text-sm"
                          />
                        </div>
                      )
                    })}
                  </div>
                </div>
              </div>
            )}
          </div>
        )
      default:
        return null
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <Button variant="ghost" onClick={() => navigate('/dashboard')}>
              <ChevronLeft className="w-4 h-4" />
            </Button>
            <h1 className="text-2xl font-bold">New EA Review Request</h1>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-sm text-muted-foreground">
              Progress: {calculateProgress()}%
            </div>
            <Button variant="outline" onClick={handleSaveDraft}>
              <Save className="w-4 h-4 mr-2" />
              Save Draft
            </Button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {/* Stepper */}
        <div className="mb-8">
          <div className="flex gap-2">
            {STEPS.map((step) => (
              <button
                key={step.id}
                onClick={() => setCurrentStep(step.id)}
                title={step.description}
                className={`px-3 py-1.5 rounded-lg font-medium text-xs transition-all whitespace-nowrap ${
                  step.id === currentStep
                    ? 'bg-primary text-primary-foreground shadow-md'
                    : step.id < currentStep
                    ? 'bg-primary/20 text-primary border border-primary/30'
                    : 'bg-white text-gray-600 border border-gray-300 hover:border-primary/50'
                }`}
              >
                {step.title}
              </button>
            ))}
          </div>
        </div>

        {/* Step Content */}
        <Card>
          <CardHeader>
            <CardTitle>{STEPS[currentStep - 1].title}</CardTitle>
            <p className="text-muted-foreground">{STEPS[currentStep - 1].description}</p>
          </CardHeader>
          <CardContent>
            {renderStepContent()}
          </CardContent>
        </Card>

        {/* Navigation */}
        <div className="flex justify-between mt-6">
          <Button
            variant="outline"
            onClick={handlePrevious}
            disabled={currentStep === 1}
          >
            <ChevronLeft className="w-4 h-4 mr-2" />
            Previous
          </Button>
          {currentStep === STEPS.length ? (
            <Button onClick={handleSubmit}>
              <Send className="w-4 h-4 mr-2" />
              Submit for Review
            </Button>
          ) : (
            <Button onClick={handleNext}>
              Next
              <ChevronRight className="w-4 h-4 ml-2" />
            </Button>
          )}
        </div>
      </main>
    </div>
  )
}
