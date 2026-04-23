import { supabase } from './supabase'

// Helper function to ensure Supabase is available
const ensureSupabase = () => {
  if (!supabase) {
    throw new Error('Supabase is not configured. Please set VITE_BACKEND_TYPE=supabase and provide Supabase credentials.')
  }
  return supabase
}

export interface Step {
  id: string
  step_order: number
  title: string
  description: string
  icon: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Domain {
  id: string
  slug: string
  name: string
  description: string
  color: string
  icon: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface ArtefactType {
  id: string
  value: string
  label: string
  description: string
  icon: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface ArtefactTemplate {
  id: string
  domain_id: string
  artefact_type_id: string
  name: string
  description: string
  is_required: boolean
  is_active: boolean
  sort_order: number
  created_at: string
  updated_at: string
  artefact_type?: ArtefactType
}

export interface ChecklistSubsection {
  id: string
  domain_id: string
  name: string
  description: string
  color_theme: string
  sort_order: number
  is_active: boolean
  created_at: string
  updated_at: string
  questions?: ChecklistQuestion[]
}

export interface ChecklistQuestion {
  id: string
  subsection_id: string
  question_code: string
  question_text: string
  question_type: string
  help_text: string
  is_required: boolean
  sort_order: number
  is_active: boolean
  created_at: string
  updated_at: string
  options?: QuestionOption[]
}

export interface QuestionOption {
  id: string
  question_id: string
  option_value: string
  option_label: string
  description: string
  color_code: string
  sort_order: number
  is_active: boolean
  created_at: string
}

export interface EAPrinciple {
  id: string
  principle_code: string
  principle_name: string
  category: string
  statement: string
  rationale: string
  implications: string
  items_to_verify: string[]
  arb_weight: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface PrincipleDomain {
  id: string
  principle_id: string
  domain_id: string
  relevance_score: number
  created_at: string
}

export interface FormField {
  id: string
  step_id: string
  field_name: string
  field_label: string
  field_type: string
  placeholder: string
  is_required: boolean
  validation_rules: Record<string, any>
  options: Record<string, any>
  sort_order: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export const metadataService = {
  async getSteps(): Promise<Step[]> {
    const { data, error } = await ensureSupabase()
      .from('submission_steps')
      .select('*')
      .eq('is_active', true)
      .order('step_order')
    
    if (error) throw error
    return data
  },

  async getDomains(): Promise<Domain[]> {
    const { data, error } = await ensureSupabase()
      .from('domains')
      .select('*')
      .eq('is_active', true)
      .order('slug')
    
    if (error) throw error
    return data
  },

  async getDomainsForStep(stepId: string): Promise<Domain[]> {
    const { data, error } = await ensureSupabase()
      .from('domain_steps')
      .select('domains(*)')
      .eq('step_id', stepId)
      .eq('is_active', true)
    
    if (error) throw error
    return data.map((ds: any) => ds.domains).filter(Boolean)
  },

  async getStepToDomainMapping(): Promise<Record<number, string>> {
    const { data: stepsData, error: stepsError } = await ensureSupabase()
      .from('submission_steps')
      .select('id, step_order')
      .eq('is_active', true)
      .order('step_order')
    
    if (stepsError) throw stepsError

    const { data: domainStepsData, error: domainStepsError } = await ensureSupabase()
      .from('domain_steps')
      .select('step_id, domains(slug)')
      .eq('is_active', true)
    
    if (domainStepsError) throw domainStepsError

    const mapping: Record<number, string> = {}
    domainStepsData.forEach((ds: any) => {
      const step = stepsData.find((s: any) => s.id === ds.step_id)
      if (step && ds.domains) {
        mapping[step.step_order] = ds.domains.slug
      }
    })

    return mapping
  },

  async getArtefactTypes(): Promise<ArtefactType[]> {
    const { data, error } = await ensureSupabase()
      .from('artefact_types')
      .select('*')
      .eq('is_active', true)
      .order('value')
    
    if (error) throw error
    return data
  },

  async getArtefactTemplates(domainId: string): Promise<ArtefactTemplate[]> {
    const { data, error } = await ensureSupabase()
      .from('artefact_templates')
      .select('*')
      .eq('is_active', true)
      .order('value')
    
    if (error) throw error
    return data
  },

  async getChecklistSubsections(domainSlug: string): Promise<ChecklistSubsection[]> {
    const { data: domainData, error: domainError } = await ensureSupabase()
      .from('domains')
      .select('id')
      .eq('slug', domainSlug)
      .single()
    
    if (domainError) throw domainError
    
    const { data: subsections, error: subsectionsError } = await ensureSupabase()
      .from('checklist_subsections')
      .select('*')
      .eq('domain_id', domainData.id)
      .eq('is_active', true)
      .order('sort_order')
    
    if (subsectionsError) throw subsectionsError
    
    const subsectionIds = subsections.map((s: any) => s.id)
    const { data: questions, error: questionsError } = await ensureSupabase()
      .from('checklist_questions')
      .select('*')
      .in('subsection_id', subsectionIds)
      .eq('is_active', true)
      .order('sort_order')
    
    if (questionsError) throw questionsError
    
    const { data: questionOptions, error: optionsError } = await ensureSupabase()
      .from('question_options')
      .select('*')
      .eq('is_active', true)
      .order('sort_order')
    
    if (optionsError) throw optionsError
    
    const optionsByQuestion = questionOptions.reduce((acc: any, option: any) => {
      if (!acc[option.question_id]) {
        acc[option.question_id] = []
      }
      acc[option.question_id].push(option)
      return acc
    }, {})
    
    const questionsBySubsection = questions.reduce((acc: any, question: any) => {
      if (!acc[question.subsection_id]) {
        acc[question.subsection_id] = []
      }
      acc[question.subsection_id].push({
        ...question,
        options: optionsByQuestion[question.id]?.sort((a: any, b: any) => a.sort_order - b.sort_order) || []
      })
      return acc
    }, {})
    
    return subsections.map((cs: any) => ({
      ...cs,
      questions: questionsBySubsection[cs.id]?.sort((a: any, b: any) => a.sort_order - b.sort_order) || []
    }))
  },

  async getPTXGates(): Promise<{ value: string; label: string }[]> {
    const { data, error } = await ensureSupabase()
      .from('ptx_gates')
      .select('*')
      .eq('is_active', true)
      .order('slug')
    
    if (error) throw error
    return data
  },

  async getArchitectureDispositions(): Promise<{ value: string; label: string }[]> {
    const { data, error } = await ensureSupabase()
      .from('architecture_dispositions')
      .select('value, label')
      .eq('is_active', true)
      .order('sort_order')
    
    if (error) throw error
    return data
  },

  async getEAPrinciples(): Promise<EAPrinciple[]> {
    const { data, error } = await ensureSupabase()
      .from('ea_principles')
      .select('*')
      .eq('is_active', true)
      .order('category, principle_code')
    
    if (error) throw error
    return data
  },

  async getEAPrinciplesForDomain(domainSlug: string): Promise<EAPrinciple[]> {
    const { data, error } = await ensureSupabase()
      .from('principle_domains')
      .select('ea_principles(*), relevance_score')
      .eq('domains.slug', domainSlug)
      .eq('is_active', true)
      .gt('relevance_score', 0)
      .order('relevance_score', { ascending: false })
    
    if (error) throw error
    return data.map((pd: any) => ({
      ...pd.ea_principles,
      relevance_score: pd.relevance_score
    }))
  },

  async getFormFields(stepId: string): Promise<FormField[]> {
    const { data, error } = await ensureSupabase()
      .from('form_fields')
      .select('*')
      .eq('step_id', stepId)
      .eq('is_active', true)
      .order('sort_order')
    
    if (error) throw error
    return data
  },

  async getQuestionOptions(questionId: string): Promise<QuestionOption[]> {
    const { data, error } = await ensureSupabase()
      .from('question_options')
      .select('*')
      .eq('question_id', questionId)
      .eq('is_active', true)
      .order('sort_order')
    
    if (error) throw error
    return data
  },

  async getAllQuestionOptions(): Promise<QuestionOption[]> {
    const { data, error } = await ensureSupabase()
      .from('question_options')
      .select('*')
      .eq('is_active', true)
      .order('sort_order')
    
    if (error) throw error
    return data
  },

  async getAllMetadata() {
    const [steps, domains, artefactTypes, ptxGates, architectureDispositions, eaPrinciples, questionOptions] = await Promise.all([
      this.getSteps(),
      this.getDomains(),
      this.getArtefactTypes(),
      this.getPTXGates(),
      this.getArchitectureDispositions(),
      this.getEAPrinciples(),
      this.getAllQuestionOptions()
    ])

    return { steps, domains, artefactTypes, ptxGates, architectureDispositions, eaPrinciples, questionOptions }
  }
}
