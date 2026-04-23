-- Add seq_number column to domains table
ALTER TABLE domains ADD COLUMN seq_number INTEGER default 0;

-- Update seq_number for existing domains based on their current order
UPDATE domains SET seq_number = 1 WHERE slug = 'general';
UPDATE domains SET seq_number = 2 WHERE slug = 'business';
UPDATE domains SET seq_number = 3 WHERE slug = 'application';
UPDATE domains SET seq_number = 4 WHERE slug = 'integration';
UPDATE domains SET seq_number = 5 WHERE slug = 'data';
UPDATE domains SET seq_number = 6 WHERE slug = 'security';
UPDATE domains SET seq_number = 7 WHERE slug = 'infrastructure';
UPDATE domains SET seq_number = 8 WHERE slug = 'devsecops';
UPDATE domains SET seq_number = 9 WHERE slug = 'nfr';

-- Make seq_number NOT NULL after updating existing records
ALTER TABLE domains ALTER COLUMN seq_number SET NOT NULL;

-- Add index on seq_number for performance
CREATE INDEX idx_domains_seq_number ON domains(seq_number);
