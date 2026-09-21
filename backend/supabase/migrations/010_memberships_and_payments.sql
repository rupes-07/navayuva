CREATE TABLE IF NOT EXISTS public.membership_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE CHECK (length(trim(name)) BETWEEN 1 AND 100),
  description text CHECK (description IS NULL OR length(description) <= 1000),
  price_amount numeric(12,2) NOT NULL CHECK (price_amount >= 0),
  currency char(3) NOT NULL DEFAULT 'NPR' CHECK (currency ~ '^[A-Z]{3}$'),
  billing_interval text NOT NULL DEFAULT 'ONE_TIME'
    CHECK (billing_interval IN ('ONE_TIME', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
  trial_period_days integer NOT NULL DEFAULT 0 CHECK (trial_period_days >= 0),
  grace_period_days integer NOT NULL DEFAULT 0 CHECK (grace_period_days >= 0),
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_id uuid NOT NULL REFERENCES public.membership_plans(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'TRIALING'
    CHECK (status IN ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  trial_ends_at timestamptz,
  grace_ends_at timestamptz,
  cancelled_at timestamptz,
  provider_subscription_id text UNIQUE,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (current_period_end IS NULL OR current_period_start IS NULL OR current_period_end >= current_period_start),
  CHECK (trial_ends_at IS NULL OR current_period_start IS NULL OR trial_ends_at >= current_period_start),
  CHECK (grace_ends_at IS NULL OR current_period_end IS NULL OR grace_ends_at >= current_period_end)
);

CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subscription_id uuid REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  currency char(3) NOT NULL DEFAULT 'NPR' CHECK (currency ~ '^[A-Z]{3}$'),
  provider text NOT NULL CHECK (provider IN ('ESEWA', 'KHALTI', 'STRIPE', 'OTHER')),
  provider_payment_id text UNIQUE,
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED', 'CANCELLED')),
  paid_at timestamptz,
  failure_reason text,
  idempotency_key text NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 8 AND 120),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (paid_at IS NULL OR status IN ('SUCCEEDED', 'REFUNDED')),
  CHECK (provider_payment_id IS NULL OR status IN ('SUCCEEDED', 'REFUNDED'))
);

CREATE TABLE IF NOT EXISTS public.payment_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id uuid NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('AUTHORIZATION', 'CAPTURE', 'REFUND', 'WEBHOOK')),
  provider_reference text NOT NULL UNIQUE CHECK (length(provider_reference) BETWEEN 1 AND 240),
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  currency char(3) NOT NULL DEFAULT 'NPR' CHECK (currency ~ '^[A-Z]{3}$'),
  status text NOT NULL CHECK (status IN ('RECEIVED', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'IGNORED')),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  received_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (processed_at IS NULL OR processed_at >= received_at)
);

CREATE INDEX IF NOT EXISTS membership_plans_active_idx ON public.membership_plans (is_active);
CREATE INDEX IF NOT EXISTS membership_plans_deleted_at_idx ON public.membership_plans (deleted_at);
CREATE INDEX IF NOT EXISTS subscriptions_user_id_idx ON public.subscriptions (user_id);
CREATE INDEX IF NOT EXISTS subscriptions_plan_id_idx ON public.subscriptions (plan_id);
CREATE INDEX IF NOT EXISTS subscriptions_status_idx ON public.subscriptions (status);
CREATE INDEX IF NOT EXISTS subscriptions_current_period_end_idx ON public.subscriptions (current_period_end);
CREATE INDEX IF NOT EXISTS subscriptions_deleted_at_idx ON public.subscriptions (deleted_at);
CREATE INDEX IF NOT EXISTS payments_user_id_idx ON public.payments (user_id);
CREATE INDEX IF NOT EXISTS payments_subscription_id_idx ON public.payments (subscription_id);
CREATE INDEX IF NOT EXISTS payments_provider_status_idx ON public.payments (provider, status);
CREATE INDEX IF NOT EXISTS payments_created_at_idx ON public.payments (created_at DESC);
CREATE INDEX IF NOT EXISTS payments_deleted_at_idx ON public.payments (deleted_at);
CREATE INDEX IF NOT EXISTS payment_transactions_payment_id_idx ON public.payment_transactions (payment_id);
CREATE INDEX IF NOT EXISTS payment_transactions_received_at_idx ON public.payment_transactions (received_at DESC);
