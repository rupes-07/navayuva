CREATE TABLE IF NOT EXISTS public.issue_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 80),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text CHECK (description IS NULL OR length(description) <= 500),
  color text CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$'),
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (name),
  UNIQUE (slug)
);

CREATE INDEX IF NOT EXISTS issue_categories_active_idx ON public.issue_categories (is_active);
CREATE INDEX IF NOT EXISTS issue_categories_deleted_at_idx ON public.issue_categories (deleted_at);

CREATE TABLE IF NOT EXISTS public.issues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 3 AND 160),
  description text NOT NULL CHECK (length(description) BETWEEN 10 AND 5000),
  category_id uuid NOT NULL REFERENCES public.issue_categories(id) ON DELETE RESTRICT,
  reporter_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_anonymous boolean NOT NULL DEFAULT false,
  province_id uuid REFERENCES public.provinces(id) ON DELETE SET NULL,
  district_id uuid REFERENCES public.districts(id) ON DELETE SET NULL,
  municipality_id uuid REFERENCES public.municipalities(id) ON DELETE SET NULL,
  ward_id uuid REFERENCES public.wards(id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  latitude numeric(9,6) CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
  longitude numeric(9,6) CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
  severity text NOT NULL DEFAULT 'MEDIUM'
    CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  priority text NOT NULL DEFAULT 'MEDIUM'
    CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  status text NOT NULL DEFAULT 'SUBMITTED'
    CHECK (status IN ('SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'PRIORITIZED', 'ESCALATED', 'AWAITING_RESPONSE', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED', 'DUPLICATE')),
  assigned_official_id uuid REFERENCES public.officials(id) ON DELETE SET NULL,
  resolved_at timestamptz,
  closed_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL)),
  CHECK (resolved_at IS NULL OR status IN ('RESOLVED', 'CLOSED')),
  CHECK (closed_at IS NULL OR status = 'CLOSED'),
  CHECK (closed_at IS NULL OR resolved_at IS NOT NULL),
  CHECK (province_id IS NULL OR district_id IS NOT NULL),
  CHECK (district_id IS NULL OR municipality_id IS NOT NULL),
  CHECK (municipality_id IS NULL OR ward_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.issue_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id uuid NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  uploaded_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  file_url text,
  file_name text NOT NULL CHECK (length(trim(file_name)) BETWEEN 1 AND 255),
  file_type text NOT NULL CHECK (file_type IN ('IMAGE', 'VIDEO', 'DOCUMENT')),
  file_size integer NOT NULL CHECK (file_size > 0),
  mime_type text NOT NULL CHECK (length(trim(mime_type)) BETWEEN 1 AND 120),
  storage_path text NOT NULL CHECK (length(trim(storage_path)) BETWEEN 1 AND 500),
  verification_status text NOT NULL DEFAULT 'PENDING'
    CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (storage_path)
);

CREATE TABLE IF NOT EXISTS public.issue_supports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id uuid NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.issue_status_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id uuid NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  from_status text NOT NULL
    CHECK (from_status IN ('SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'PRIORITIZED', 'ESCALATED', 'AWAITING_RESPONSE', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED', 'DUPLICATE')),
  to_status text NOT NULL
    CHECK (to_status IN ('SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'PRIORITIZED', 'ESCALATED', 'AWAITING_RESPONSE', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED', 'DUPLICATE')),
  changed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reason text CHECK (reason IS NULL OR length(reason) <= 2000),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.issue_escalations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id uuid NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  from_level text NOT NULL CHECK (from_level IN ('CHAPTER', 'WARD', 'MUNICIPALITY', 'DISTRICT', 'PROVINCE', 'NATIONAL')),
  to_level text NOT NULL CHECK (to_level IN ('WARD', 'MUNICIPALITY', 'DISTRICT', 'PROVINCE', 'NATIONAL')),
  reason text NOT NULL CHECK (length(trim(reason)) BETWEEN 3 AND 2000),
  escalated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  assigned_to uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolved_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (to_level <> 'CHAPTER'),
  CHECK (resolved_at IS NULL OR resolved_at >= created_at)
);

CREATE INDEX IF NOT EXISTS issues_category_id_idx ON public.issues (category_id);
CREATE INDEX IF NOT EXISTS issues_reporter_id_idx ON public.issues (reporter_id);
CREATE INDEX IF NOT EXISTS issues_chapter_id_idx ON public.issues (chapter_id);
CREATE INDEX IF NOT EXISTS issues_ward_id_idx ON public.issues (ward_id);
CREATE INDEX IF NOT EXISTS issues_municipality_id_idx ON public.issues (municipality_id);
CREATE INDEX IF NOT EXISTS issues_district_id_idx ON public.issues (district_id);
CREATE INDEX IF NOT EXISTS issues_province_id_idx ON public.issues (province_id);
CREATE INDEX IF NOT EXISTS issues_status_idx ON public.issues (status);
CREATE INDEX IF NOT EXISTS issues_severity_idx ON public.issues (severity);
CREATE INDEX IF NOT EXISTS issues_priority_idx ON public.issues (priority);
CREATE INDEX IF NOT EXISTS issues_created_at_idx ON public.issues (created_at DESC);
CREATE INDEX IF NOT EXISTS issues_active_created_at_idx ON public.issues (created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS issues_deleted_at_idx ON public.issues (deleted_at);
CREATE INDEX IF NOT EXISTS issue_evidence_issue_id_idx ON public.issue_evidence (issue_id);
CREATE INDEX IF NOT EXISTS issue_evidence_uploaded_by_idx ON public.issue_evidence (uploaded_by);
CREATE INDEX IF NOT EXISTS issue_evidence_verification_status_idx ON public.issue_evidence (verification_status);
CREATE INDEX IF NOT EXISTS issue_evidence_deleted_at_idx ON public.issue_evidence (deleted_at);
CREATE UNIQUE INDEX IF NOT EXISTS issue_supports_active_issue_user_uidx
  ON public.issue_supports (issue_id, user_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS issue_supports_issue_id_idx ON public.issue_supports (issue_id);
CREATE INDEX IF NOT EXISTS issue_supports_user_id_idx ON public.issue_supports (user_id);
CREATE INDEX IF NOT EXISTS issue_status_logs_issue_created_at_idx ON public.issue_status_logs (issue_id, created_at DESC);
CREATE INDEX IF NOT EXISTS issue_escalations_issue_id_idx ON public.issue_escalations (issue_id);
CREATE INDEX IF NOT EXISTS issue_escalations_assigned_to_idx ON public.issue_escalations (assigned_to);
CREATE INDEX IF NOT EXISTS issue_escalations_created_at_idx ON public.issue_escalations (created_at DESC);
