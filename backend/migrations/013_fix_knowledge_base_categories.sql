-- Fix knowledge_base table categories to match domain slugs used by domain agents
-- This script maps current categories to proper domain slugs based on content analysis

-- Update ea_principles to 'general' (contains principles for all domains)
UPDATE knowledge_base
SET category = 'general'
WHERE category = 'ea_principles';

-- Update integration_principles to 'integration'
UPDATE knowledge_base
SET category = 'integration'
WHERE category = 'integration_principles';

-- Update architecture_review_taxonomy to 'general'
UPDATE knowledge_base
SET category = 'general'
WHERE category = 'architecture_review_taxonomy';

-- Update ea_standards to 'general' (contains standards applicable across domains)
UPDATE knowledge_base
SET category = 'general'
WHERE category = 'ea_standards';

-- Update ea-patterns entries based on their title/content
UPDATE knowledge_base
SET category = 'application'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%Application%' OR content ILIKE '%application architecture%');

UPDATE knowledge_base
SET category = 'software'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%Software Design%' OR content ILIKE '%software design%');

UPDATE knowledge_base
SET category = 'integration'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%Integration%' OR content ILIKE '%integration architecture%');

UPDATE knowledge_base
SET category = 'api'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%API%' OR content ILIKE '%api architecture%');

UPDATE knowledge_base
SET category = 'data'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%Data%' OR content ILIKE '%data architecture%');

UPDATE knowledge_base
SET category = 'infrastructure'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%Infrastructure%' OR content ILIKE '%infrastructure%');

UPDATE knowledge_base
SET category = 'security'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%Security%' OR content ILIKE '%security architecture%');

UPDATE knowledge_base
SET category = 'devsecops'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%DevSecOps%' OR content ILIKE '%devsecops%');

UPDATE knowledge_base
SET category = 'general'
WHERE category = 'ea-patterns'
  AND (title ILIKE '%Enterprise%' OR title ILIKE '%Cross-Cutting%');

-- Verify the updates
SELECT category, COUNT(*) as count
FROM knowledge_base
GROUP BY category
ORDER BY category;
