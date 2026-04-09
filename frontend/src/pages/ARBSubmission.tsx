import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { Button } from '../components/ui/Button'
import { Input } from '../components/ui/Input'
import { Textarea } from '../components/ui/Textarea'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { ChevronLeft, ChevronRight, Save, Send, Upload } from 'lucide-react'
import { api } from '../services/api'

const STEPS = [
  { id: 1, title: 'Solution Context', description: 'Project overview and stakeholders' },
  { id: 2, title: 'Application Architecture', description: 'Tech stack and patterns' },
  { id: 3, title: 'Integration Architecture', description: 'APIs and integration catalogue' },
  { id: 4, title: 'Data Architecture', description: 'Classification and lifecycle' },
  { id: 5, title: 'Security Architecture', description: 'AuthN/AuthZ and compliance' },
  { id: 6, title: 'Infrastructure Architecture', description: 'Environments and platform' },
  { id: 7, title: 'DevSecOps', description: 'CI/CD and quality gates' },
  { id: 8, title: 'NFR Assessment', description: 'Performance and reliability' },
]

const CHECKLIST_ITEMS = {
  application: [
    { id: 'app-1', question: 'Technology stack from approved catalogue?' },
    { id: 'app-2', question: 'Microservices architecture with clear boundaries?' },
    { id: 'app-3', question: 'Circuit breaker pattern implemented?' },
    { id: 'app-4', question: 'API versioning with backward compatibility?' },
    { id: 'app-5', question: 'SBOM generated and maintained?' },
  ],
  integration: [
    { id: 'int-1', question: 'RESTful API design principles followed?' },
    { id: 'int-2', question: 'OpenAPI/Swagger documentation maintained?' },
    { id: 'int-3', question: 'Event schemas with proper versioning?' },
    { id: 'int-4', question: 'Integration catalogue maintained?' },
    { id: 'int-5', question: 'Rate limiting implemented for public APIs?' },
  ],
  data: [
    { id: 'data-1', question: 'Data classification policy applied?' },
    { id: 'data-2', question: 'Data model documentation maintained?' },
    { id: 'data-3', question: 'PII encrypted at rest and in transit?' },
    { id: 'data-4', question: 'Data lifecycle with retention policies?' },
    { id: 'data-5', question: 'EoL/EoS tracking for data stores?' },
  ],
  security: [
    { id: 'sec-1', question: 'OAuth 2.0/OIDC with Azure AD?' },
    { id: 'sec-2', question: 'RBAC with principle of least privilege?' },
    { id: 'sec-3', question: 'VAPT completed before production?' },
    { id: 'sec-4', question: 'TLS 1.3 for encrypted communications?' },
    { id: 'sec-5', question: 'Secrets stored in Azure Key Vault?' },
  ],
  infrastructure: [
    { id: 'inf-1', question: 'IaC with Terraform or CloudFormation?' },
    { id: 'inf-2', question: 'Multi-environment strategy defined?' },
    { id: 'inf-3', question: 'Platform upgrades with rollback procedures?' },
    { id: 'inf-4', question: 'Capacity planning with 12-18 month forecast?' },
    { id: 'inf-5', question: 'DR with defined RPO/RTO?' },
  ],
  devsecops: [
    { id: 'dev-1', question: 'CI/CD with automated testing and scanning?' },
    { id: 'dev-2', question: 'Code reviews mandatory for PRs?' },
    { id: 'dev-3', question: 'Test coverage at least 80%?' },
    { id: 'dev-4', question: 'Blue-green or canary deployments?' },
    { id: 'dev-5', question: 'Quality gates defined and enforced?' },
  ],
}

export default function ARBSubmission() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const [currentStep, setCurrentStep] = useState(1)
  const [submissionId, setSubmissionId] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    project_name: '',
    problem_statement: '',
    stakeholders: '',
    business_drivers: '',
    growth_plans: '',
    // Domain sections
    application_checklist: {} as Record<string, string>,
    application_evidence: {} as Record<string, string>,
    integration_checklist: {} as Record<string, string>,
    integration_evidence: {} as Record<string, string>,
    data_checklist: {} as Record<string, string>,
    data_evidence: {} as Record<string, string>,
    security_checklist: {} as Record<string, string>,
    security_evidence: {} as Record<string, string>,
    infrastructure_checklist: {} as Record<string, string>,
    infrastructure_evidence: {} as Record<string, string>,
    devsecops_checklist: {} as Record<string, string>,
    devsecops_evidence: {} as Record<string, string>,
    // NFR
    nfr_scores: {} as Record<string, number>,
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
    const completedSteps = [1, 2, 3, 4, 5, 6, 7, 8].filter(
      (step) => step <= currentStep
    ).length
    return Math.round((completedSteps / STEPS.length) * 100)
  }

  const renderStepContent = () => {
    switch (currentStep) {
      case 1:
        return (
          <div className="space-y-6">
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
                value={formData.stakeholders}
                onChange={(e) => setFormData({ ...formData, stakeholders: e.target.value })}
                placeholder="List key stakeholders (one per line)"
                rows={4}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Business Drivers</label>
              <Textarea
                value={formData.business_drivers}
                onChange={(e) => setFormData({ ...formData, business_drivers: e.target.value })}
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
        const domainMap: Record<number, { checklist: typeof CHECKLIST_ITEMS.application; prefix: string }> = {
          2: { checklist: CHECKLIST_ITEMS.application, prefix: 'application' },
          3: { checklist: CHECKLIST_ITEMS.integration, prefix: 'integration' },
          4: { checklist: CHECKLIST_ITEMS.data, prefix: 'data' },
          5: { checklist: CHECKLIST_ITEMS.security, prefix: 'security' },
          6: { checklist: CHECKLIST_ITEMS.infrastructure, prefix: 'infrastructure' },
          7: { checklist: CHECKLIST_ITEMS.devsecops, prefix: 'devsecops' },
        }
        const domain = domainMap[currentStep]
        return (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium mb-2">Upload Artefacts</label>
              <div className="border-2 border-dashed rounded-lg p-8 text-center">
                <Upload className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground mb-2">
                  Upload architecture diagrams, HLD documents, etc.
                </p>
                <p className="text-xs text-muted-foreground mb-4">
                  PDF, DOCX, PNG, SVG (Max 50MB)
                </p>
                <Input type="file" multiple onChange={handleFileUpload} />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium mb-4">Compliance Checklist</label>
              <div className="space-y-4">
                {domain.checklist.map((item) => (
                  <div key={item.id} className="border rounded-lg p-4">
                    <p className="font-medium mb-3">{item.question}</p>
                    <div className="flex gap-2 mb-3">
                      {['compliant', 'non_compliant', 'partial', 'na'].map((option) => (
                        <label key={option} className="flex items-center gap-2">
                          <input
                            type="radio"
                            name={`${domain.prefix}-${item.id}`}
                            value={option}
                            checked={formData[`${domain.prefix}_checklist` as keyof typeof formData]?.[item.id] === option}
                            onChange={(e) => {
                              setFormData({
                                ...formData,
                                [`${domain.prefix}_checklist`]: {
                                  ...formData[`${domain.prefix}_checklist` as keyof typeof formData],
                                  [item.id]: e.target.value,
                                },
                              })
                            }}
                          />
                          <span className="text-sm capitalize">{option.replace('_', ' ')}</span>
                        </label>
                      ))}
                    </div>
                    <Input
                      placeholder="Evidence notes"
                      value={formData[`${domain.prefix}_evidence` as keyof typeof formData]?.[item.id] || ''}
                      onChange={(e) => {
                        setFormData({
                          ...formData,
                          [`${domain.prefix}_evidence`]: {
                            ...formData[`${domain.prefix}_evidence` as keyof typeof formData],
                            [item.id]: e.target.value,
                          },
                        })
                      }}
                      className="text-sm"
                    />
                  </div>
                ))}
              </div>
            </div>

            {currentStep === 3 && (
              <div>
                <label className="block text-sm font-medium mb-2">Integration Catalogue</label>
                <div className="border rounded-lg p-4">
                  <p className="text-sm text-muted-foreground mb-4">
                    Add integration catalogue items or upload Excel/CSV file
                  </p>
                  <Button variant="outline" size="sm" className="mb-4">
                    <Upload className="w-4 h-4 mr-2" />
                    Upload Excel/CSV
                  </Button>
                  <div className="text-sm text-muted-foreground">
                    Editable rows for integration catalogue will be implemented here
                  </div>
                </div>
              </div>
            )}
          </div>
        )
      case 8:
        return (
          <div className="space-y-6">
            <p className="text-muted-foreground">
              Assess non-functional requirements and provide evidence
            </p>
            {['Scalability & Performance', 'HA, Resilience & DR', 'Security NFRs', 'Engineering Quality'].map((category) => (
              <div key={category} className="border rounded-lg p-4">
                <h4 className="font-medium mb-3">{category}</h4>
                <div className="space-y-3">
                  <div>
                    <label className="block text-sm font-medium mb-1">Target Value</label>
                    <Input placeholder="e.g., 99.9% availability" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Actual Value</label>
                    <Input placeholder="e.g., 99.95% achieved" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Score (1-5)</label>
                    <Input type="number" min="1" max="5" placeholder="3" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Evidence</label>
                    <Textarea placeholder="Provide evidence or notes" rows={2} />
                  </div>
                </div>
              </div>
            ))}
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
            <h1 className="text-2xl font-bold">New ARB Submission</h1>
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

      <main className="max-w-4xl mx-auto px-4 py-8">
        {/* Stepper */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            {STEPS.map((step, index) => (
              <React.Fragment key={step.id}>
                <div className="flex flex-col items-center flex-1">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center font-medium ${
                      step.id <= currentStep
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-gray-200 text-gray-600'
                    }`}
                  >
                    {step.id}
                  </div>
                  <div className="text-xs mt-2 text-center hidden sm:block">
                    <div className="font-medium">{step.title}</div>
                    <div className="text-muted-foreground">{step.description}</div>
                  </div>
                </div>
                {index < STEPS.length - 1 && (
                  <div
                    className={`flex-1 h-1 mx-2 ${
                      step.id < currentStep ? 'bg-primary' : 'bg-gray-200'
                    }`}
                  />
                )}
              </React.Fragment>
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
