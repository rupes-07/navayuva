CREATE TABLE IF NOT EXISTS public.provinces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 100),
  code text NOT NULL CHECK (code ~ '^[A-Z0-9-]{1,32}$'),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (code),
  UNIQUE (slug)
);

CREATE TABLE IF NOT EXISTS public.districts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  province_id uuid NOT NULL REFERENCES public.provinces(id) ON DELETE RESTRICT,
  name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 100),
  code text NOT NULL CHECK (code ~ '^[A-Z0-9-]{1,32}$'),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (province_id, code),
  UNIQUE (province_id, slug)
);

CREATE TABLE IF NOT EXISTS public.municipalities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  district_id uuid NOT NULL REFERENCES public.districts(id) ON DELETE RESTRICT,
  name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 120),
  code text NOT NULL CHECK (code ~ '^[A-Z0-9-]{1,32}$'),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  municipality_type text NOT NULL DEFAULT 'MUNICIPALITY'
    CHECK (municipality_type IN ('METROPOLITAN', 'SUB_METROPOLITAN', 'MUNICIPALITY', 'RURAL_MUNICIPALITY')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (district_id, code),
  UNIQUE (district_id, slug)
);

CREATE TABLE IF NOT EXISTS public.wards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  municipality_id uuid NOT NULL REFERENCES public.municipalities(id) ON DELETE RESTRICT,
  name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 120),
  code text NOT NULL CHECK (code ~ '^[A-Z0-9-]{1,32}$'),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  ward_number integer NOT NULL CHECK (ward_number BETWEEN 1 AND 50),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (municipality_id, code),
  UNIQUE (municipality_id, slug),
  UNIQUE (municipality_id, ward_number)
);

CREATE INDEX IF NOT EXISTS provinces_deleted_at_idx ON public.provinces (deleted_at);
CREATE INDEX IF NOT EXISTS districts_province_id_idx ON public.districts (province_id);
CREATE INDEX IF NOT EXISTS districts_deleted_at_idx ON public.districts (deleted_at);
CREATE INDEX IF NOT EXISTS municipalities_district_id_idx ON public.municipalities (district_id);
CREATE INDEX IF NOT EXISTS municipalities_deleted_at_idx ON public.municipalities (deleted_at);
CREATE INDEX IF NOT EXISTS wards_municipality_id_idx ON public.wards (municipality_id);
CREATE INDEX IF NOT EXISTS wards_deleted_at_idx ON public.wards (deleted_at);

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL CHECK (length(trim(full_name)) BETWEEN 1 AND 120),
  username citext NOT NULL,
  email citext,
  phone text,
  date_of_birth date,
  gender text NOT NULL DEFAULT 'UNSPECIFIED'
    CHECK (gender IN ('FEMALE', 'MALE', 'NON_BINARY', 'SELF_DESCRIBE', 'UNSPECIFIED')),
  bio text CHECK (bio IS NULL OR length(bio) <= 1000),
  profile_image_url text,
  province_id uuid REFERENCES public.provinces(id) ON DELETE SET NULL,
  district_id uuid REFERENCES public.districts(id) ON DELETE SET NULL,
  municipality_id uuid REFERENCES public.municipalities(id) ON DELETE SET NULL,
  ward_id uuid REFERENCES public.wards(id) ON DELETE SET NULL,
  chapter_id uuid,
  membership_status text NOT NULL DEFAULT 'PENDING'
    CHECK (membership_status IN ('PENDING', 'ACTIVE', 'EXPIRED', 'CANCELLED')),
  volunteer_hours numeric(10,2) NOT NULL DEFAULT 0 CHECK (volunteer_hours >= 0),
  impact_score integer NOT NULL DEFAULT 0 CHECK (impact_score >= 0),
  language text NOT NULL DEFAULT 'en' CHECK (language ~ '^[a-z]{2}(?:-[A-Z]{2})?$'),
  account_status text NOT NULL DEFAULT 'PENDING'
    CHECK (account_status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'DEACTIVATED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (email IS NULL OR email ~* '^[^@]+@[^@]+\.[^@]+$'),
  CHECK (phone IS NULL OR phone ~ '^\+?[0-9 ()-]{7,24}$'),
  CHECK (date_of_birth IS NULL OR date_of_birth <= CURRENT_DATE),
  CHECK (province_id IS NULL OR district_id IS NOT NULL),
  CHECK (district_id IS NULL OR municipality_id IS NOT NULL),
  CHECK (municipality_id IS NULL OR ward_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS profiles_active_username_uidx ON public.profiles (lower(username)) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS profiles_active_email_uidx ON public.profiles (lower(email)) WHERE deleted_at IS NULL AND email IS NOT NULL;
CREATE INDEX IF NOT EXISTS profiles_user_id_idx ON public.profiles (user_id);
CREATE INDEX IF NOT EXISTS profiles_ward_id_idx ON public.profiles (ward_id);
CREATE INDEX IF NOT EXISTS profiles_deleted_at_idx ON public.profiles (deleted_at);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  generated_username text;
BEGIN
  generated_username := left(lower(regexp_replace(split_part(COALESCE(NEW.email, NEW.id::text), '@', 1), '[^a-zA-Z0-9]+', '-', 'g')), 30)
    || '_' || substr(NEW.id::text, 1, 8);

  INSERT INTO public.profiles (
    user_id,
    full_name,
    username,
    email,
    membership_status,
    account_status,
    language
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', split_part(COALESCE(NEW.email, NEW.id::text), '@', 1)),
    generated_username,
    NEW.email,
    'PENDING',
    'PENDING',
    COALESCE(NEW.raw_user_meta_data ->> 'language', 'en')
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();
