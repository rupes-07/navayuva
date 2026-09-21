CREATE TABLE IF NOT EXISTS public.impact_point_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  points integer NOT NULL CHECK (points != 0),
  event_type text NOT NULL CHECK (length(trim(event_type)) BETWEEN 1 AND 80),
  reference_id uuid,
  description text NOT NULL CHECK (length(trim(description)) BETWEEN 1 AND 500),
  idempotency_key text NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 8 AND 120),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.leadership_tiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE CHECK (name IN ('MEMBER', 'OFFICER', 'CHAPTER_LEADER', 'WARD_LEADER', 'MUNICIPAL_LEADER', 'DISTRICT_LEADER', 'PROVINCIAL_LEADER', 'NATIONAL_LEADER')),
  level integer NOT NULL UNIQUE CHECK (level BETWEEN 0 AND 100),
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.promotion_criteria (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_id uuid NOT NULL REFERENCES public.leadership_tiers(id) ON DELETE CASCADE,
  version integer NOT NULL CHECK (version > 0),
  minimum_impact_score integer CHECK (minimum_impact_score IS NULL OR minimum_impact_score >= 0),
  minimum_volunteer_hours numeric(10,2) CHECK (minimum_volunteer_hours IS NULL OR minimum_volunteer_hours >= 0),
  minimum_age integer CHECK (minimum_age IS NULL OR minimum_age BETWEEN 14 AND 100),
  required_badges jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (tier_id, version)
);

CREATE UNIQUE INDEX IF NOT EXISTS promotion_criteria_active_tier_version_uidx
  ON public.promotion_criteria (tier_id, version)
  WHERE deleted_at IS NULL AND is_active;
CREATE INDEX IF NOT EXISTS promotion_criteria_tier_id_idx ON public.promotion_criteria (tier_id);
CREATE INDEX IF NOT EXISTS promotion_criteria_deleted_at_idx ON public.promotion_criteria (deleted_at);

CREATE TABLE IF NOT EXISTS public.promotion_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_tier_id uuid NOT NULL REFERENCES public.leadership_tiers(id) ON DELETE RESTRICT,
  nominator_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'APPLIED'
    CHECK (status IN ('APPLIED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'WITHDRAWN')),
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  reason text CHECK (reason IS NULL OR length(reason) <= 2000),
  criteria_version integer,
  reviewed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (reviewed_at IS NULL OR reviewed_by IS NOT NULL),
  CHECK (criteria_version IS NULL OR criteria_version > 0)
);

CREATE TABLE IF NOT EXISTS public.promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  previous_tier_id uuid REFERENCES public.leadership_tiers(id) ON DELETE SET NULL,
  new_tier_id uuid NOT NULL REFERENCES public.leadership_tiers(id) ON DELETE RESTRICT,
  previous_role text,
  new_role text NOT NULL,
  approved_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reason text CHECK (reason IS NULL OR length(reason) <= 2000),
  criteria_version integer CHECK (criteria_version IS NULL OR criteria_version > 0),
  effective_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (approved_by IS NOT NULL OR deleted_at IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE CHECK (length(trim(name)) BETWEEN 1 AND 80),
  description text CHECK (description IS NULL OR length(description) <= 500),
  icon_url text,
  rule_key text NOT NULL UNIQUE CHECK (rule_key ~ '^[a-z][a-z0-9_]*$'),
  points_threshold integer CHECK (points_threshold IS NULL OR points_threshold >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.user_badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_id uuid NOT NULL REFERENCES public.badges(id) ON DELETE RESTRICT,
  awarded_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reason text CHECK (reason IS NULL OR length(reason) <= 500),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  awarded_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS impact_point_ledger_user_id_idx ON public.impact_point_ledger (user_id);
CREATE INDEX IF NOT EXISTS impact_point_ledger_event_type_idx ON public.impact_point_ledger (event_type);
CREATE INDEX IF NOT EXISTS impact_point_ledger_reference_id_idx ON public.impact_point_ledger (reference_id);
CREATE INDEX IF NOT EXISTS impact_point_ledger_created_at_idx ON public.impact_point_ledger (created_at DESC);
CREATE INDEX IF NOT EXISTS leadership_tiers_level_idx ON public.leadership_tiers (level);
CREATE INDEX IF NOT EXISTS leadership_tiers_deleted_at_idx ON public.leadership_tiers (deleted_at);
CREATE INDEX IF NOT EXISTS promotion_applications_applicant_id_idx ON public.promotion_applications (applicant_id);
CREATE INDEX IF NOT EXISTS promotion_applications_target_tier_id_idx ON public.promotion_applications (target_tier_id);
CREATE INDEX IF NOT EXISTS promotion_applications_status_idx ON public.promotion_applications (status);
CREATE INDEX IF NOT EXISTS promotion_applications_deleted_at_idx ON public.promotion_applications (deleted_at);
CREATE INDEX IF NOT EXISTS promotions_user_id_idx ON public.promotions (user_id);
CREATE INDEX IF NOT EXISTS promotions_new_tier_id_idx ON public.promotions (new_tier_id);
CREATE INDEX IF NOT EXISTS promotions_effective_at_idx ON public.promotions (effective_at DESC);
CREATE INDEX IF NOT EXISTS promotions_deleted_at_idx ON public.promotions (deleted_at);
CREATE INDEX IF NOT EXISTS badges_active_idx ON public.badges (is_active);
CREATE INDEX IF NOT EXISTS badges_deleted_at_idx ON public.badges (deleted_at);
CREATE INDEX IF NOT EXISTS user_badges_user_id_idx ON public.user_badges (user_id);
CREATE INDEX IF NOT EXISTS user_badges_badge_id_idx ON public.user_badges (badge_id);
CREATE INDEX IF NOT EXISTS user_badges_deleted_at_idx ON public.user_badges (deleted_at);
