-- Fix knowledge_base categories for ea-standards entries.
--
-- Root cause: populate_knowledge_base.py hardcoded category='standards' for all
-- ea-standards.md entries regardless of their principle_id prefix (B-STD-*, D-STD-*, etc.).
-- Domain agents query by domain slug (application, data, …) so category='standards' was
-- unreachable. Migration 013 tried WHERE category='ea_standards' which never matched.
--
-- This migration re-maps standards rows to the correct domain slug using their principle_id
-- prefix, then re-runs populate_knowledge_base.py to load the patterns zip.

BEGIN;

-- Business standards
UPDATE knowledge_base
SET category = 'business'
WHERE category = 'standards'
  AND principle_id LIKE 'B-STD-%';

-- Data standards
UPDATE knowledge_base
SET category = 'data'
WHERE category = 'standards'
  AND principle_id LIKE 'D-STD-%';

-- Infrastructure standards
UPDATE knowledge_base
SET category = 'infrastructure'
WHERE category = 'standards'
  AND principle_id LIKE 'I-STD-%';

-- Security standards
UPDATE knowledge_base
SET category = 'security'
WHERE category = 'standards'
  AND principle_id LIKE 'S-STD-%';

-- Application standards
UPDATE knowledge_base
SET category = 'application'
WHERE category = 'standards'
  AND principle_id LIKE 'A-STD-%';

-- Software standards
UPDATE knowledge_base
SET category = 'software'
WHERE category = 'standards'
  AND principle_id LIKE 'SW-STD-%';

-- General standards (G-STD-* and any remaining un-prefixed)
UPDATE knowledge_base
SET category = 'general'
WHERE category = 'standards'
  AND (principle_id LIKE 'G-STD-%' OR principle_id IS NULL);

COMMIT;

-- Verify
SELECT category, COUNT(*) AS count
FROM knowledge_base
WHERE is_active = TRUE
GROUP BY category
ORDER BY category;
