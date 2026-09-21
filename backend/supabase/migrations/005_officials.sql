CREATE TABLE IF NOT EXISTS public.officials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  full_name text NOT NULL CHECK (length(trim(full_name)) BETWEEN 1 AND 120),
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 120),
  organization text NOT NULL CHECK (length(trim(organization)) BETWEEN 1 AND 160),
  jurisdiction_level text NOT NULL DEFAULT 'WARD'
    CHECK (jurisdiction_level IN ('CHAPTER', 'WARD', 'MUNICIPALITY', 'DISTRICT', 'PROVINCE', 'NATIONAL')),
  province_id uuid REFERENCES public.provinces(id) ON DELETE SET NULL,
  district_id uuid REFERENCES public.districts(id) ON DELETE SET NULL,
  municipality_id uuid REFERENCES public.municipalities(id) ON DELETE SET NULL,
  ward_id uuid REFERENCES public.wards(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'INACTIVE'
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
  verified_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  verified_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (verified_at IS NULL OR verified_by IS NOT NULL),
  CHECK (province_id IS NULL OR district_id IS NOT NULL),
  CHECK (district_id IS NULL OR municipality_id IS NOT NULL),
  CHECK (municipality_id IS NULL OR ward_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS officials_user_id_idx ON public.officials (user_id);
CREATE INDEX IF NOT EXISTS officials_ward_id_idx ON public.officials (ward_id);
CREATE INDEX IF NOT EXISTS officials_municipality_id_idx ON public.officials (municipality_id);
CREATE INDEX IF NOT EXISTS officials_district_id_idx ON public.officials (district_id);
CREATE INDEX IF NOT EXISTS officials_province_id_idx ON public.officials (province_id);
CREATE INDEX IF NOT EXISTS officials_status_idx ON public.officials (status);
CREATE INDEX IF NOT EXISTS officials_deleted_at_idx ON public.officials (deleted_at);
