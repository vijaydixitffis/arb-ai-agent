-- Mock ARB Submission Data for Testing
-- This script creates a mock review with all domain checklists but no artifacts

-- ============================================================================
-- Insert Mock Review with Complete Checklists (No Artifacts)
-- ============================================================================
INSERT INTO reviews (
  id,
  solution_name,
  scope_tags,
  artifact_path,
  artifact_filename,
  artifact_file_type,
  artifact_file_size_bytes,
  sa_user_id,
  status,
  llm_model,
  report_json,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'Customer 360 Platform - Mock Submission',
  ARRAY['general', 'business', 'application', 'integration', 'data', 'security', 'infrastructure', 'devsecops', 'nfr'],
  '', -- No artifact uploaded
  '',
  '',
  0,
  'mock-sa-user-id',
  'submitted', -- Status: submitted (ready to be marked as ready for review)
  'gpt-4o',
  '{
    "form_data": {
      "project_name": "Customer 360 Platform",
      "problem_statement": "Need a unified platform to aggregate customer data from multiple systems for 360-degree view",
      "stakeholders": ["Sales", "Marketing", "Customer Service", "Finance"],
      "business_drivers": ["Customer Retention", "Revenue Growth", "Operational Efficiency"],
      "growth_plans": "Scale to 10M customers, expand to 5 new markets",
      "target_audience": "Enterprise customers in retail and financial sectors",
      "business_checklist": {
        "business_strategy": "aligned",
        "stakeholder_analysis": "complete",
        "value_proposition": "documented"
      },
      "application_checklist": {
        "architecture_diagram": "provided",
        "technology_stack": "documented",
        "component_design": "complete",
        "api_design": "documented"
      },
      "integration_checklist": {
        "external_apis": "identified",
        "data_flow": "documented",
        "error_handling": "defined",
        "security_protocols": "specified"
      },
      "data_checklist": {
        "data_model": "designed",
        "data_flow": "documented",
        "storage_strategy": "defined",
        "privacy_compliance": "addressed"
      },
      "security_checklist": {
        "authentication": "designed",
        "authorization": "defined",
        "encryption": "planned",
        "audit_logging": "included"
      },
      "infrastructure_checklist": {
        "deployment_strategy": "defined",
        "scalability_plan": "documented",
        "monitoring": "planned",
        "disaster_recovery": "designed"
      },
      "devsecops_checklist": {
        "ci_cd_pipeline": "designed",
        "security_scanning": "included",
        "infrastructure_as_code": "planned",
        "compliance_checks": "defined"
      },
      "nfr_criteria": [
        {
          "category": "Performance",
          "criteria": "Response Time",
          "target_value": "< 200ms",
          "actual_value": "Not measured"
        },
        {
          "category": "Scalability",
          "criteria": "Concurrent Users",
          "target_value": "100,000",
          "actual_value": "Not measured"
        },
        {
          "category": "Availability",
          "criteria": "Uptime",
          "target_value": "99.9%",
          "actual_value": "Not measured"
        }
      ]
    }
  }'::jsonb,
  NOW(),
  NOW()
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- Insert Mock Draft Review (Incomplete Checklists)
-- ============================================================================
INSERT INTO reviews (
  id,
  solution_name,
  scope_tags,
  artifact_path,
  artifact_filename,
  artifact_file_type,
  artifact_file_size_bytes,
  sa_user_id,
  status,
  llm_model,
  report_json,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'E-commerce Platform - Incomplete Draft',
  ARRAY['general', 'business', 'application'],
  '', -- No artifact uploaded
  '',
  '',
  0,
  'mock-sa-user-id',
  'draft', -- Status: draft (incomplete)
  'gpt-4o',
  '{
    "form_data": {
      "project_name": "E-commerce Platform",
      "problem_statement": "Need a modern e-commerce platform",
      "business_checklist": {
        "business_strategy": "incomplete"
      },
      "application_checklist": {}
    }
  }'::jsonb,
  NOW(),
  NOW()
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- Verification Query
-- ============================================================================
-- Run this to verify the mock data was inserted:
-- SELECT id, solution_name, status, scope_tags, artifact_path 
-- FROM reviews 
-- WHERE solution_name LIKE '%Mock%' OR solution_name LIKE '%Incomplete%'
-- ORDER BY created_at DESC;
