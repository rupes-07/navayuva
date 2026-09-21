CREATE TABLE IF NOT EXISTS public.projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chapter_id uuid NOT NULL REFERENCES public.chapters(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 3 AND 160),
  description text NOT NULL CHECK (length(description) BETWEEN 10 AND 5000),
  category text NOT NULL
    CHECK (category IN ('BLOOD_DONATION', 'CLEANUP', 'TREE_PLANTATION', 'EDUCATION', 'TOURISM', 'CULTURAL', 'DISASTER_RESPONSE', 'COMMUNITY_SERVICE', 'YOUTH_DEVELOPMENT', 'OTHER')),
  location text NOT NULL CHECK (length(trim(location)) BETWEEN 2 AND 240),
  province_id uuid REFERENCES public.provinces(id) ON DELETE SET NULL,
  district_id uuid REFERENCES public.districts(id) ON DELETE SET NULL,
  municipality_id uuid REFERENCES public.municipalities(id) ON DELETE SET NULL,
  ward_id uuid REFERENCES public.wards(id) ON DELETE SET NULL,
  start_date date NOT NULL,
  end_date date,
  capacity integer CHECK (capacity IS NULL OR capacity > 0),
  status text NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT', 'PUBLISHED', 'ONGOING', 'COMPLETED', 'CANCELLED')),
  cover_image_url text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (end_date IS NULL OR end_date >= start_date),
  CHECK (province_id IS NULL OR district_id IS NOT NULL),
  CHECK (district_id IS NULL OR municipality_id IS NOT NULL),
  CHECK (municipality_id IS NULL OR ward_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.project_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  state text NOT NULL DEFAULT 'REGISTERED'
    CHECK (state IN ('REGISTERED', 'CANCELLED', 'ATTENDED', 'ABSENT')),
  registered_at timestamptz NOT NULL DEFAULT now(),
  cancelled_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (cancelled_at IS NULL OR state IN ('CANCELLED', 'ABSENT')),
  CHECK (cancelled_at IS NULL OR cancelled_at >= registered_at)
);

CREATE TABLE IF NOT EXISTS public.project_attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  verified_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'ATTENDED', 'ABSENT', 'EXCUSED')),
  check_in_at timestamptz,
  check_out_at timestamptz,
  volunteer_hours numeric(10,2) NOT NULL DEFAULT 0 CHECK (volunteer_hours >= 0),
  verification_method text NOT NULL DEFAULT 'MANUAL'
    CHECK (verification_method IN ('MANUAL', 'QR', 'GPS', 'ORGANIZER')),
  idempotency_key text NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 8 AND 120),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (check_out_at IS NULL OR check_in_at IS NOT NULL),
  CHECK (check_out_at IS NULL OR check_out_at >= check_in_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS projects_active_slug_uidx ON public.projects (chapter_id, lower(title), start_date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS projects_chapter_id_idx ON public.projects (chapter_id);
CREATE INDEX IF NOT EXISTS projects_created_by_idx ON public.projects (created_by);
CREATE INDEX IF NOT EXISTS projects_status_idx ON public.projects (status);
CREATE INDEX IF NOT EXISTS projects_category_idx ON public.projects (category);
CREATE INDEX IF NOT EXISTS projects_start_date_idx ON public.projects (start_date);
CREATE INDEX IF NOT EXISTS projects_ward_id_idx ON public.projects (ward_id);
CREATE INDEX IF NOT EXISTS projects_municipality_id_idx ON public.projects (municipality_id);
CREATE INDEX IF NOT EXISTS projects_district_id_idx ON public.projects (district_id);
CREATE INDEX IF NOT EXISTS projects_province_id_idx ON public.projects (province_id);
CREATE INDEX IF NOT EXISTS projects_deleted_at_idx ON public.projects (deleted_at);
CREATE UNIQUE INDEX IF NOT EXISTS project_participants_active_project_user_uidx
  ON public.project_participants (project_id, user_id)
  WHERE deleted_at IS NULL AND state = 'REGISTERED';
CREATE INDEX IF NOT EXISTS project_participants_project_id_idx ON public.project_participants (project_id);
CREATE INDEX IF NOT EXISTS project_participants_user_id_idx ON public.project_participants (user_id);
CREATE INDEX IF NOT EXISTS project_participants_state_idx ON public.project_participants (state);
CREATE INDEX IF NOT EXISTS project_participants_deleted_at_idx ON public.project_participants (deleted_at);
CREATE UNIQUE INDEX IF NOT EXISTS project_attendance_active_project_user_uidx
  ON public.project_attendance (project_id, user_id)
  WHERE deleted_at IS NULL AND status = 'PENDING';
CREATE INDEX IF NOT EXISTS project_attendance_project_id_idx ON public.project_attendance (project_id);
CREATE INDEX IF NOT EXISTS project_attendance_user_id_idx ON public.project_attendance (user_id);
CREATE INDEX IF NOT EXISTS project_attendance_verified_by_idx ON public.project_attendance (verified_by);
CREATE INDEX IF NOT EXISTS project_attendance_status_idx ON public.project_attendance (status);
CREATE INDEX IF NOT EXISTS project_attendance_deleted_at_idx ON public.project_attendance (deleted_at);
