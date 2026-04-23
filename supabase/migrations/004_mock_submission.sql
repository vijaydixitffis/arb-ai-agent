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
  created_at
) VALUES (
  gen_random_uuid(),
  'Customer 360 Platform - Mock Submission',
  ARRAY['general', 'business', 'application', 'integration', 'data', 'security', 'infrastructure', 'devsecops', 'nfr'],
  '', -- No artifact uploaded
  '',
  '',
  0,
  '8d0da913-c40d-44fb-b15b-11a64caa47b1',
  'submitted', -- Status: submitted (ready to be marked as ready for review)
  'gpt-4o',
  '{
    "form_data": {
      "project_name": "Customer 360 Platform",
      "problem_statement": "Need a unified platform to aggregate customer data from multiple systems for 360-degree view",
      "stakeholders": ["Sales", "Marketing", "Customer Service", "Finance"],
      "business_drivers": ["Customer Retention", "Revenue Growth", "Operational Efficiency"],
      "growth_plans": "Scale to 10M customers, expand to 5 new markets",
      "domain_data": {
        "general": {
          "checklist": {
            "GEN_001": "compliant",
            "GEN_002": "compliant"
          },
          "evidence": {
            "GEN_001": "Architecture document approved",
            "GEN_002": "Stakeholder analysis complete"
          }
        },
        "business": {
          "checklist": {
            "BUS_001": "aligned",
            "BUS_002": "complete",
            "BUS_003": "documented"
          },
          "evidence": {
            "BUS_001": "Business strategy aligned with company goals",
            "BUS_002": "Stakeholder analysis completed",
            "BUS_003": "Value proposition documented"
          }
        },
        "application": {
          "checklist": {
            "APP_001": "provided",
            "APP_002": "documented",
            "APP_003": "complete",
            "APP_004": "documented"
          },
          "evidence": {
            "APP_001": "Architecture diagram provided",
            "APP_002": "Technology stack documented",
            "APP_003": "Component design complete",
            "APP_004": "API design documented"
          }
        },
        "integration": {
          "checklist": {
            "INT_001": "identified",
            "INT_002": "documented",
            "INT_003": "defined",
            "INT_004": "specified"
          },
          "evidence": {
            "INT_001": "External APIs identified",
            "INT_002": "Data flow documented",
            "INT_003": "Error handling defined",
            "INT_004": "Security protocols specified"
          }
        },
        "data": {
          "checklist": {
            "DAT_001": "designed",
            "DAT_002": "documented",
            "DAT_003": "defined",
            "DAT_004": "addressed"
          },
          "evidence": {
            "DAT_001": "Data model designed",
            "DAT_002": "Data flow documented",
            "DAT_003": "Storage strategy defined",
            "DAT_004": "Privacy compliance addressed"
          }
        },
        "security": {
          "checklist": {
            "SEC_001": "designed",
            "SEC_002": "defined",
            "SEC_003": "planned",
            "SEC_004": "included"
          },
          "evidence": {
            "SEC_001": "Authentication designed",
            "SEC_002": "Authorization defined",
            "SEC_003": "Encryption planned",
            "SEC_004": "Audit logging included"
          }
        },
        "infrastructure": {
          "checklist": {
            "INF_001": "defined",
            "INF_002": "documented",
            "INF_003": "planned",
            "INF_004": "designed"
          },
          "evidence": {
            "INF_001": "Deployment strategy defined",
            "INF_002": "Scalability plan documented",
            "INF_003": "Monitoring planned",
            "INF_004": "Disaster recovery designed"
          }
        },
        "devsecops": {
          "checklist": {
            "DEV_001": "designed",
            "DEV_002": "included",
            "DEV_003": "planned",
            "DEV_004": "defined"
          },
          "evidence": {
            "DEV_001": "CI/CD pipeline designed",
            "DEV_002": "Security scanning included",
            "DEV_003": "Infrastructure as code planned",
            "DEV_004": "Compliance checks defined"
          }
        },
        "nfr": {
          "checklist": {
            "NFR_001": "compliant",
            "NFR_002": "compliant",
            "NFR_003": "compliant"
          },
          "evidence": {
            "NFR_001": "Performance requirements defined",
            "NFR_002": "Scalability requirements documented",
            "NFR_003": "Availability SLA specified"
          }
        }
      },
      "nfr_criteria": [
        {
          "category": "Performance",
          "criteria": "Response Time",
          "target_value": "< 200ms",
          "actual_value": "Not measured",
          "score": 0
        },
        {
          "category": "Scalability",
          "criteria": "Concurrent Users",
          "target_value": "100,000",
          "actual_value": "Not measured",
          "score": 0
        },
        {
          "category": "Availability",
          "criteria": "Uptime",
          "target_value": "99.9%",
          "actual_value": "Not measured",
          "score": 0
        }
      ]
    }
  }'::jsonb,
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
  created_at
) VALUES (
  gen_random_uuid(),
  'E-commerce Platform - Incomplete Draft',
  ARRAY['general', 'business', 'application'],
  '', -- No artifact uploaded
  '',
  '',
  0,
  '8d0da913-c40d-44fb-b15b-11a64caa47b1',
  'draft', -- Status: draft (incomplete)
  'gpt-4o',
  '{
    "form_data": {
      "project_name": "E-commerce Platform",
      "problem_statement": "Need a modern e-commerce platform",
      "stakeholders": [],
      "business_drivers": [],
      "growth_plans": "",
      "domain_data": {
        "general": {
          "checklist": {},
          "evidence": {}
        },
        "business": {
          "checklist": {
            "BUS_001": "incomplete"
          },
          "evidence": {}
        },
        "application": {
          "checklist": {},
          "evidence": {}
        }
      },
      "nfr_criteria": []
    }
  }'::jsonb,
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
