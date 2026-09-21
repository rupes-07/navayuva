CREATE TABLE IF NOT EXISTS public.admin_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key text NOT NULL UNIQUE CHECK (config_key ~ '^[a-z][a-z0-9_]*$'),
  config_value jsonb NOT NULL,
  value_type text NOT NULL DEFAULT 'JSON'
    CHECK (value_type IN ('JSON', 'STRING', 'NUMBER', 'BOOLEAN')),
  version integer NOT NULL DEFAULT 1 CHECK (version > 0),
  description text,
  updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (config_key, version)
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  action text NOT NULL CHECK (length(trim(action)) BETWEEN 1 AND 120),
  entity_type text NOT NULL CHECK (length(trim(entity_type)) BETWEEN 1 AND 120),
  entity_id uuid,
  old_data jsonb,
  new_data jsonb,
  ip_address inet,
  user_agent text,
  request_id text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS admin_configs_key_version_idx ON public.admin_configs (config_key, version DESC);
CREATE INDEX IF NOT EXISTS admin_configs_active_idx ON public.admin_configs (is_active);
CREATE INDEX IF NOT EXISTS audit_logs_actor_id_idx ON public.audit_logs (actor_id);
CREATE INDEX IF NOT EXISTS audit_logs_entity_idx ON public.audit_logs (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS audit_logs_action_idx ON public.audit_logs (action);
CREATE INDEX IF NOT EXISTS audit_logs_created_at_idx ON public.audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_metadata_gin_idx ON public.audit_logs USING gin (metadata);
