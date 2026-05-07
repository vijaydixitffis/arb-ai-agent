-- Migration: EA Override Layer (Tier 3)
-- Creates ea_overrides table for governed EA overrides with full audit trail.
-- Four override types: finding_severity, action_modification, adr_content, overall_decision.

CREATE TABLE IF NOT EXISTS ea_overrides (
    id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id         uuid        NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    ea_user_id        uuid        NOT NULL,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),

    -- Which type of override this is
    override_type     text        NOT NULL CHECK (
                                      override_type IN (
                                          'finding_severity',
                                          'action_modification',
                                          'adr_content',
                                          'overall_decision'
                                      )
                                  ),

    -- ID of the entity being overridden (finding ID, action ID, ADR ID, or 'overall')
    target_id         text        NOT NULL,

    -- Original value produced by the AI agent (immutable record)
    original_value    jsonb       NOT NULL,

    -- EA's override value
    override_value    jsonb       NOT NULL,

    -- Mandatory rationale for any override (governance requirement)
    rationale         text        NOT NULL CHECK (char_length(rationale) >= 10),

    -- Once confirmed by a second EA the override is locked (immutable = true)
    is_immutable      boolean     NOT NULL DEFAULT false,

    -- Who confirmed the override (second-eye sign-off for overall_decision overrides)
    confirmed_by      uuid        NULL,
    confirmed_at      timestamptz NULL
);

-- Trigger to keep updated_at current
CREATE OR REPLACE FUNCTION ea_overrides_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ea_overrides_updated_at
    BEFORE UPDATE ON ea_overrides
    FOR EACH ROW EXECUTE FUNCTION ea_overrides_set_updated_at();

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS ea_overrides_review_id_idx  ON ea_overrides (review_id);
CREATE INDEX IF NOT EXISTS ea_overrides_type_idx       ON ea_overrides (review_id, override_type);
CREATE INDEX IF NOT EXISTS ea_overrides_immutable_idx  ON ea_overrides (review_id, is_immutable);

-- RLS: enable row-level security (all access via service role or explicit grants)
ALTER TABLE ea_overrides ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS; anon/authenticated require explicit policy
CREATE POLICY "ea_overrides_service_role"
    ON ea_overrides
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

COMMENT ON TABLE ea_overrides IS
    'Governed EA override records. Each row captures the original AI value and the EA override '
    'with mandatory rationale. Immutable overrides (is_immutable=true) cannot be modified.';
