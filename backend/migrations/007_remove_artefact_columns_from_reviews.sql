-- Remove single artefact columns from reviews table
-- These are now handled by the separate artefacts table

ALTER TABLE reviews DROP COLUMN IF EXISTS artifact_path;
ALTER TABLE reviews DROP COLUMN IF EXISTS artifact_filename;
ALTER TABLE reviews DROP COLUMN IF EXISTS artifact_file_type;
ALTER TABLE reviews DROP COLUMN IF EXISTS artifact_file_size_bytes;

-- Add comment to document the change
COMMENT ON TABLE reviews IS 'Reviews table - artefacts now stored in separate artefacts table for multiple artefact support';
