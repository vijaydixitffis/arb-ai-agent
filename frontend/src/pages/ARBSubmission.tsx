import { useState, useEffect } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { useMetadataStore } from '../stores/metadataStore'
import { Button } from '../components/ui/Button'
import { Input } from '../components/ui/Input'
import { Textarea } from '../components/ui/Textarea'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { ChevronLeft, ChevronRight, Send } from 'lucide-react'
import ARBHeader from '../components/ARB/ARBHeader'

export default function ARBSubmission() {
  const navigate = useNavigate()
  const location = useLocation()
  const user = useAuthStore((state) => state.user)
  const { steps, loadDomainMetadata, checklistSubsectionsByDomain, loadMetadata, artefactTypes, artefactTemplatesByDomain, stepToDomainMapping, questionOptionsByQuestion } = useMetadataStore()
  const [currentStep, setCurrentStep] = useState(1)
  const [isLoading, setIsLoading] = useState(true)
  const [submissionId, setSubmissionId] = useState<string | null>(null)
  const [selectedSubsection, setSelectedSubsection] = useState<string | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [ptxGate, setPtxGate] = useState<string>('')
  const [architectureDisposition, setArchitectureDisposition] = useState<string>('')

  useEffect(() => {
    const loadInitialData = async () => {
      await loadMetadata()
      setIsLoading(false)
    }
    loadInitialData()
  }, [])

  useEffect(() => {
    if (location.state) {
      setPtxGate(location.state.ptxGate || '')
      setArchitectureDisposition(location.state.architectureDisposition || '')
    }
  }, [location.state])

  useEffect(() => {
    // Load domain-specific metadata when entering a domain step
    if (currentStep >= 2 && currentStep <= 9) {
      const domainSlug = stepToDomainMapping[currentStep]
      if (domainSlug && !checklistSubsectionsByDomain[domainSlug]) {
        loadDomainMetadata(domainSlug)
      }
    }
  }, [currentStep, checklistSubsectionsByDomain, loadDomainMetadata, stepToDomainMapping])
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
    if (currentStep < steps.length) {
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
        // Mock update - replace with Supabase query when ready
        // await api.updateSubmission(submissionId, submissionData)
      } else {
        // Mock create - replace with Supabase query when ready
        // const result = await api.createSubmission(submissionData)
        // setSubmissionId(result.id)
        setSubmissionId('mock-submission-id')
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
        // Mock update - replace with Supabase query when ready
        // await api.updateSubmission(submissionId, submissionData)
        // await api.submitSubmission(submissionId)
      } else {
        // Mock create - replace with Supabase query when ready
        // const result = await api.createSubmission(submissionData)
        // await api.submitSubmission(result.id)
        setSubmissionId('mock-submission-id')
      }

      // Mock AI agent review - replace with Supabase query when ready
      // await api.runARBReview({ submission_id: submissionId || '', domain_sections: formData })

      navigate('/dashboard')
    } catch (error) {
      console.error('Error submitting:', error)
      alert('Failed to submit')
    }
  }

  const calculateProgress = () => {
    const completedSteps = steps.map((step: any) => step.step_order).filter(
      (step) => step <= currentStep
    ).length
    return Math.round((completedSteps / steps.length) * 100)
  }

  const getArtefactIcon = (type: string) => {
    const artefactType = artefactTypes.find((t: any) => t.value === type)
    return artefactType?.icon || '📎'
  }

  const getArtefactTypeLabel = (type: string) => {
    const artefactType = artefactTypes.find((t: any) => t.value === type)
    return artefactType?.label || type
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
        const domainSlug = stepToDomainMapping[currentStep]
        const subsections = checklistSubsectionsByDomain[domainSlug] || []
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
                        const selectedArtefact = artefactTemplatesByDomain[domainSlug]?.find(
                          (a: any) => a.name === e.target.value
                        )
                        setNewArtefact({
                          ...newArtefact,
                          name: e.target.value,
                          type: selectedArtefact?.artefact_type?.value || '',
                          domain: domainSlug,
                        })
                      }}
                    >
                      <option value="">Select artefact</option>
                      {artefactTemplatesByDomain[domainSlug]?.map((artefact: any) => (
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
                      {artefactTypes.map((type: any) => (
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
                        [domainSlug]: [...artefacts[domainSlug], newArtefact],
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
              {artefacts[domainSlug]?.length > 0 && (
                <div className="space-y-2">
                  <label className="block text-xs font-medium">Uploaded Artefacts</label>
                  {artefacts[domainSlug].map((artefact, index) => (
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
                {subsections.map((subsection: any, index: number) => {
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
                      key={subsection.id}
                      onClick={() => {
                        setSelectedSubsection(subsection.name)
                        setIsDialogOpen(true)
                      }}
                      className={`bg-gradient-to-br ${colorClass} border rounded-xl p-5 cursor-pointer hover:shadow-lg hover:scale-105 transition-all duration-200`}
                    >
                      <div className="flex items-start justify-between mb-3">
                        <h4 className="font-semibold text-gray-800">{subsection.name}</h4>
                        <div className="w-8 h-8 rounded-full bg-white/50 flex items-center justify-center">
                          <span className="text-sm font-bold text-gray-600">{subsection.questions?.length || 0}</span>
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
                    {subsections.find((s: any) => s.name === selectedSubsection)?.questions?.map((question: any) => {
                      const options = questionOptionsByQuestion[question.question_code]?.map((o: any) => o.value) || ['compliant', 'non_compliant', 'partial', 'na']
                      const optionLabels = questionOptionsByQuestion[question.question_code]?.map((o: any) => o.label) || ['Yes', 'No', 'Partial', 'NA']
                      const currentIndex = options.indexOf((formData as any)[`${domainSlug}_checklist`]?.[question.question_code] as string) || 0

                      return (
                        <div key={question.id} className="border rounded-lg p-4">
                          <p className="font-medium mb-4">{question.question_text}</p>
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
                                    [`${domainSlug}_checklist`]: {
                                      ...(formData as any)[`${domainSlug}_checklist`],
                                      [question.question_code]: options[parseInt(e.target.value)],
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
                            value={(formData as any)[`${domainSlug}_evidence`]?.[question.question_code] || ''}
                            onChange={(e) => {
                              setFormData({
                                ...formData,
                                [`${domainSlug}_evidence`]: {
                                  ...(formData as any)[`${domainSlug}_evidence`],
                                  [question.question_code]: e.target.value,
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
        const nfrSubsections = checklistSubsectionsByDomain['nfr'] || []
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
                        const selectedArtefact = artefactTemplatesByDomain['nfr']?.find(
                          (a: any) => a.name === e.target.value
                        )
                        setNewArtefact({
                          ...newArtefact,
                          name: e.target.value,
                          type: selectedArtefact?.artefact_type?.value || '',
                          domain: 'nfr',
                        })
                      }}
                    >
                      <option value="">Select artefact</option>
                      {artefactTemplatesByDomain['nfr']?.map((artefact: any) => (
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
                      {artefactTypes.map((type: any) => (
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
                {nfrSubsections.map((subsection: any, index: number) => {
                  const colors = [
                    'from-red-50 to-red-100 border-red-200 hover:border-red-400',
                    'from-yellow-50 to-yellow-100 border-yellow-200 hover:border-yellow-400',
                    'from-indigo-50 to-indigo-100 border-indigo-200 hover:border-indigo-400',
                  ]
                  const colorClass = colors[index % colors.length]

                  return (
                    <div
                      key={subsection.id}
                      onClick={() => {
                        setSelectedSubsection(subsection.name)
                        setIsDialogOpen(true)
                      }}
                      className={`bg-gradient-to-br ${colorClass} border rounded-xl p-5 cursor-pointer hover:shadow-lg hover:scale-105 transition-all duration-200`}
                    >
                      <div className="flex items-start justify-between mb-3">
                        <h4 className="font-semibold text-gray-800">{subsection.name}</h4>
                        <div className="w-8 h-8 rounded-full bg-white/50 flex items-center justify-center">
                          <span className="text-sm font-bold text-gray-600">{subsection.questions?.length || 0}</span>
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
                    {nfrSubsections.find((s: any) => s.name === selectedSubsection)?.questions?.map((question: any) => {
                      const options = questionOptionsByQuestion[question.question_code]?.map((o: any) => o.value) || ['compliant', 'non_compliant', 'partial', 'na']
                      const optionLabels = questionOptionsByQuestion[question.question_code]?.map((o: any) => o.label) || ['Yes', 'No', 'Partial', 'NA']
                      const currentIndex = options.indexOf((formData as any)[`nfr_checklist`]?.[question.question_code] as string) || 0

                      return (
                        <div key={question.id} className="border rounded-lg p-4">
                          <p className="font-medium mb-4">{question.question_text}</p>
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
                                    [`nfr_checklist`]: {
                                      ...(formData as any)[`nfr_checklist`],
                                      [question.question_code]: options[parseInt(e.target.value)],
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
                            value={(formData as any)[`nfr_evidence`]?.[question.question_code] || ''}
                            onChange={(e) => {
                              setFormData({
                                ...formData,
                                [`nfr_evidence`]: {
                                  ...(formData as any)[`nfr_evidence`],
                                  [question.question_code]: e.target.value,
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

  if (isLoading || !steps || steps.length === 0) {
    return <div className="flex items-center justify-center min-h-screen">Loading...</div>
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <ARBHeader
        currentStep={currentStep}
        setCurrentStep={setCurrentStep}
        progress={calculateProgress()}
        onSaveDraft={handleSaveDraft}
      />

      <main className="max-w-7xl mx-auto px-4 py-8">
        {/* Step Content */}
        <Card>
          <CardHeader>
            <CardTitle>{steps[currentStep - 1].title}</CardTitle>
            <p className="text-muted-foreground">{steps[currentStep - 1].description}</p>
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
          {currentStep === steps.length ? (
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
