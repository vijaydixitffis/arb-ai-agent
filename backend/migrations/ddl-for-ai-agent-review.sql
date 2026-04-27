-- ============================================================
-- TABLE: reviews
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id                   uuid                     NOT NULL DEFAULT gen_random_uuid(),
  created_at           timestamp with time zone          DEFAULT now(),
  submitted_at         timestamp with time zone,
  reviewed_at          timestamp with time zone,
  sa_user_id           uuid,
  solution_name        text                     NOT NULL,
  scope_tags           text[]                   NOT NULL,
  status               text                     NOT NULL DEFAULT 'pending',
  decision             text,
  llm_model            text                              DEFAULT 'gpt-4o',
  tokens_used          integer,
  processing_time_ms   integer,
  llm_raw_response     text,
  ea_user_id           uuid,
  ea_override_notes    text,
  ea_overridden_at     timestamp with time zone,
  report_json          jsonb,

  CONSTRAINT reviews_pkey PRIMARY KEY (id),

  CONSTRAINT valid_status CHECK (status = ANY (ARRAY[
    'draft', 'submitted', 'pending', 'in_review',
    'ea_review', 'approved', 'rejected', 'deferred'
  ])),
  CONSTRAINT valid_decision CHECK (
    decision IS NULL OR decision = ANY (ARRAY[
      'approve', 'approve_with_conditions', 'defer', 'reject'
    ])
  ),

  CONSTRAINT reviews_sa_user_id_fkey FOREIGN KEY (sa_user_id)
    REFERENCES public.users (id) ON DELETE CASCADE,
  CONSTRAINT reviews_ea_user_id_fkey FOREIGN KEY (ea_user_id)
    REFERENCES public.users (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_reviews_status    ON public.reviews USING btree (status);
CREATE INDEX IF NOT EXISTS idx_reviews_submitted ON public.reviews USING btree (submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_sa        ON public.reviews USING btree (sa_user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_ea        ON public.reviews USING btree (ea_user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_scope     ON public.reviews USING gin  (scope_tags);

CREATE OR REPLACE TRIGGER trigger_review_status_change
  AFTER UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION log_review_status_change();


-- ============================================================
-- TABLE: findings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.findings (
  id               uuid                     NOT NULL DEFAULT gen_random_uuid(),
  review_id        uuid                     NOT NULL,
  domain           text                     NOT NULL,
  principle_id     text,
  severity         text                     NOT NULL,
  finding          text                     NOT NULL,
  recommendation   text,
  is_resolved      boolean                           DEFAULT false,
  created_at       timestamp with time zone          DEFAULT now(),

  CONSTRAINT findings_pkey PRIMARY KEY (id),

  CONSTRAINT findings_severity_check CHECK (severity = ANY (ARRAY[
    'critical', 'major', 'minor'
  ])),

  CONSTRAINT findings_review_id_fkey FOREIGN KEY (review_id)
    REFERENCES public.reviews (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_findings_review   ON public.findings USING btree (review_id);
CREATE INDEX IF NOT EXISTS idx_findings_domain   ON public.findings USING btree (domain);
CREATE INDEX IF NOT EXISTS idx_findings_severity ON public.findings USING btree (severity);


-- ============================================================
-- TABLE: actions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.actions (
  id            uuid                     NOT NULL DEFAULT gen_random_uuid(),
  review_id     uuid                     NOT NULL,
  action_text   text                     NOT NULL,
  owner_role    text                     NOT NULL,
  due_days      integer,
  due_date      date,
  status        text                              DEFAULT 'open',
  completed_at  timestamp with time zone,
  created_at    timestamp with time zone          DEFAULT now(),

  CONSTRAINT actions_pkey PRIMARY KEY (id),

  CONSTRAINT actions_status_check CHECK (status = ANY (ARRAY[
    'open', 'in_progress', 'completed', 'blocked'
  ])),

  CONSTRAINT actions_review_id_fkey FOREIGN KEY (review_id)
    REFERENCES public.reviews (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_actions_review ON public.actions USING btree (review_id);
CREATE INDEX IF NOT EXISTS idx_actions_status ON public.actions USING btree (status);
CREATE INDEX IF NOT EXISTS idx_actions_due    ON public.actions USING btree (due_date);


-- ============================================================
-- TABLE: adrs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.adrs (
  id           uuid                     NOT NULL DEFAULT gen_random_uuid(),
  review_id    uuid                     NOT NULL,
  adr_id       text                     NOT NULL,
  decision     text                     NOT NULL,
  rationale    text                     NOT NULL,
  context      text,
  consequences text,
  owner        text,
  target_date  date,
  status       text                              DEFAULT 'proposed',
  created_at   timestamp with time zone          DEFAULT now(),
  updated_at   timestamp with time zone          DEFAULT now(),

  CONSTRAINT adrs_pkey PRIMARY KEY (id),

  CONSTRAINT adrs_status_check CHECK (status = ANY (ARRAY[
    'proposed', 'accepted', 'rejected', 'superseded'
  ])),

  CONSTRAINT adrs_review_id_fkey FOREIGN KEY (review_id)
    REFERENCES public.reviews (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_adrs_review ON public.adrs USING btree (review_id);
CREATE INDEX IF NOT EXISTS idx_adrs_status ON public.adrs USING btree (status);

CREATE OR REPLACE TRIGGER trigger_adrs_updated_at
  BEFORE UPDATE ON public.adrs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
