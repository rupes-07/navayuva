CREATE TABLE IF NOT EXISTS public.chapters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(trim(name)) BETWEEN 2 AND 120),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text CHECK (description IS NULL OR length(description) <= 2000),
  province_id uuid NOT NULL REFERENCES public.provinces(id) ON DELETE RESTRICT,
  district_id uuid NOT NULL REFERENCES public.districts(id) ON DELETE RESTRICT,
  municipality_id uuid NOT NULL REFERENCES public.municipalities(id) ON DELETE RESTRICT,
  ward_id uuid NOT NULL REFERENCES public.wards(id) ON DELETE RESTRICT,
  logo_url text,
  cover_image_url text,
  founding_member_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'ACTIVE', 'DORMANT', 'SUSPENDED', 'REJECTED', 'ARCHIVED')),
  activity_status text NOT NULL DEFAULT 'INACTIVE'
    CHECK (activity_status IN ('ACTIVE', 'INACTIVE')),
  approved_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  approved_at timestamptz,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (approved_at IS NULL OR approved_by IS NOT NULL),
  CHECK (province_id IS NOT NULL AND district_id IS NOT NULL AND municipality_id IS NOT NULL AND ward_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS chapters_active_slug_uidx ON public.chapters (lower(slug)) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS chapters_ward_id_idx ON public.chapters (ward_id);
CREATE INDEX IF NOT EXISTS chapters_municipality_id_idx ON public.chapters (municipality_id);
CREATE INDEX IF NOT EXISTS chapters_district_id_idx ON public.chapters (district_id);
CREATE INDEX IF NOT EXISTS chapters_province_id_idx ON public.chapters (province_id);
CREATE INDEX IF NOT EXISTS chapters_status_idx ON public.chapters (status);
CREATE INDEX IF NOT EXISTS chapters_deleted_at_idx ON public.chapters (deleted_at);

CREATE TABLE IF NOT EXISTS public.chapter_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chapter_id uuid NOT NULL REFERENCES public.chapters(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'MEMBER'
    CHECK (role IN ('MEMBER', 'OFFICER', 'LEADER')),
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'LEFT')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (left_at IS NULL OR status IN ('LEFT', 'SUSPENDED')),
  CHECK (left_at IS NULL OR left_at >= joined_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS chapter_memberships_active_chapter_user_uidx
  ON public.chapter_memberships (chapter_id, user_id)
  WHERE deleted_at IS NULL AND status NOT IN ('LEFT');
CREATE INDEX IF NOT EXISTS chapter_memberships_chapter_id_idx ON public.chapter_memberships (chapter_id);
CREATE INDEX IF NOT EXISTS chapter_memberships_user_id_idx ON public.chapter_memberships (user_id);
CREATE INDEX IF NOT EXISTS chapter_memberships_status_idx ON public.chapter_memberships (status);
CREATE INDEX IF NOT EXISTS chapter_memberships_deleted_at_idx ON public.chapter_memberships (deleted_at);

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS chapter_id uuid,
  ADD CONSTRAINT profiles_chapter_id_fkey
  FOREIGN KEY (chapter_id) REFERENCES public.chapters(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS profiles_chapter_id_idx ON public.profiles (chapter_id);
