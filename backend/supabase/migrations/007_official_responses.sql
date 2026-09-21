CREATE TABLE IF NOT EXISTS public.official_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id uuid NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  official_id uuid NOT NULL REFERENCES public.officials(id) ON DELETE CASCADE,
  response text NOT NULL CHECK (length(trim(response)) BETWEEN 3 AND 5000),
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'IN_PROGRESS', 'RESOLVED', 'REJECTED')),
  estimated_resolution_date date,
  attachment_url text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (estimated_resolution_date IS NULL OR estimated_resolution_date >= CURRENT_DATE)
);

CREATE UNIQUE INDEX IF NOT EXISTS official_responses_active_issue_official_uidx
  ON public.official_responses (issue_id, official_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS official_responses_issue_id_idx ON public.official_responses (issue_id);
CREATE INDEX IF NOT EXISTS official_responses_official_id_idx ON public.official_responses (official_id);
CREATE INDEX IF NOT EXISTS official_responses_status_idx ON public.official_responses (status);
CREATE INDEX IF NOT EXISTS official_responses_deleted_at_idx ON public.official_responses (deleted_at);
