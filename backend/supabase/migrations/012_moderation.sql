CREATE TABLE IF NOT EXISTS public.moderation_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  target_type text NOT NULL CHECK (target_type IN ('USER', 'ISSUE', 'PROJECT', 'COMMENT', 'EVIDENCE', 'CHAPTER')),
  target_id uuid NOT NULL,
  reason text NOT NULL CHECK (reason IN ('SPAM', 'ABUSE', 'FALSE_INFORMATION', 'HARASSMENT', 'INAPPROPRIATE_CONTENT', 'DUPLICATE', 'FRAUD', 'OTHER')),
  details text CHECK (details IS NULL OR length(details) <= 3000),
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'IN_REVIEW', 'RESOLVED', 'REJECTED')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.moderation_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid REFERENCES public.moderation_reports(id) ON DELETE SET NULL,
  actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  action text NOT NULL CHECK (action IN ('WARN', 'HIDE', 'REMOVE', 'SUSPEND', 'RESTORE', 'ESCALATE')),
  target_type text NOT NULL CHECK (target_type IN ('USER', 'ISSUE', 'PROJECT', 'COMMENT', 'EVIDENCE', 'CHAPTER')),
  target_id uuid NOT NULL,
  reason text NOT NULL CHECK (length(trim(reason)) BETWEEN 3 AND 2000),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS moderation_reports_reporter_id_idx ON public.moderation_reports (reporter_id);
CREATE INDEX IF NOT EXISTS moderation_reports_target_idx ON public.moderation_reports (target_type, target_id);
CREATE INDEX IF NOT EXISTS moderation_reports_status_idx ON public.moderation_reports (status);
CREATE INDEX IF NOT EXISTS moderation_reports_created_at_idx ON public.moderation_reports (created_at DESC);
CREATE INDEX IF NOT EXISTS moderation_reports_deleted_at_idx ON public.moderation_reports (deleted_at);
CREATE INDEX IF NOT EXISTS moderation_actions_report_id_idx ON public.moderation_actions (report_id);
CREATE INDEX IF NOT EXISTS moderation_actions_actor_id_idx ON public.moderation_actions (actor_id);
CREATE INDEX IF NOT EXISTS moderation_actions_target_idx ON public.moderation_actions (target_type, target_id);
CREATE INDEX IF NOT EXISTS moderation_actions_created_at_idx ON public.moderation_actions (created_at DESC);
