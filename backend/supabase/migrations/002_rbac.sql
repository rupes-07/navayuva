CREATE TABLE IF NOT EXISTS public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (name ~ '^[A-Z][A-Z0-9_]*$'),
  description text,
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS roles_active_name_uidx ON public.roles (lower(name)) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS roles_deleted_at_idx ON public.roles (deleted_at);

CREATE TABLE IF NOT EXISTS public.permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL CHECK (key ~ '^[A-Z][A-Z0-9_]*$'),
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS permissions_active_key_uidx ON public.permissions (lower(key)) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS permissions_deleted_at_idx ON public.permissions (deleted_at);

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
  granted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (expires_at IS NULL OR expires_at > granted_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS user_roles_active_user_role_uidx
  ON public.user_roles (user_id, role_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS user_roles_user_id_idx ON public.user_roles (user_id);
CREATE INDEX IF NOT EXISTS user_roles_role_id_idx ON public.user_roles (role_id);
CREATE INDEX IF NOT EXISTS user_roles_deleted_at_idx ON public.user_roles (deleted_at);

CREATE TABLE IF NOT EXISTS public.role_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS role_permissions_active_role_permission_uidx
  ON public.role_permissions (role_id, permission_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS role_permissions_role_id_idx ON public.role_permissions (role_id);
CREATE INDEX IF NOT EXISTS role_permissions_permission_id_idx ON public.role_permissions (permission_id);
CREATE INDEX IF NOT EXISTS role_permissions_deleted_at_idx ON public.role_permissions (deleted_at);
