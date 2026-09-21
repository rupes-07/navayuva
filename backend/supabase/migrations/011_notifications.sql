CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  email_enabled boolean NOT NULL DEFAULT true,
  sms_enabled boolean NOT NULL DEFAULT false,
  in_app_enabled boolean NOT NULL DEFAULT true,
  issue_updates boolean NOT NULL DEFAULT true,
  project_updates boolean NOT NULL DEFAULT true,
  promotion_updates boolean NOT NULL DEFAULT true,
  membership_updates boolean NOT NULL DEFAULT true,
  system_updates boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type text NOT NULL
    CHECK (type IN ('ISSUE_SUBMITTED', 'ISSUE_VERIFIED', 'ISSUE_REJECTED', 'ISSUE_ESCALATED', 'ISSUE_STATUS_CHANGED', 'PROJECT_PUBLISHED', 'PROJECT_REMINDER', 'PROJECT_ATTENDANCE_VERIFIED', 'PROMOTION_APPLIED', 'PROMOTION_APPROVED', 'PROMOTION_REJECTED', 'MEMBERSHIP_EXPIRING', 'PAYMENT_SUCCESS', 'PAYMENT_FAILED', 'CHAPTER_APPROVED', 'CHAPTER_SUSPENDED', 'SYSTEM_NOTIFICATION')),
  channel text NOT NULL DEFAULT 'IN_APP'
    CHECK (channel IN ('IN_APP', 'EMAIL', 'SMS')),
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 160),
  body text NOT NULL CHECK (length(trim(body)) BETWEEN 1 AND 2000),
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'READ')),
  sent_at timestamptz,
  read_at timestamptz,
  provider_message_id text UNIQUE,
  idempotency_key text NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 8 AND 120),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (sent_at IS NULL OR sent_at >= created_at),
  CHECK (read_at IS NULL OR read_at >= created_at)
);

CREATE INDEX IF NOT EXISTS notification_preferences_user_id_idx ON public.notification_preferences (user_id);
CREATE INDEX IF NOT EXISTS notifications_recipient_id_idx ON public.notifications (recipient_id);
CREATE INDEX IF NOT EXISTS notifications_type_idx ON public.notifications (type);
CREATE INDEX IF NOT EXISTS notifications_channel_idx ON public.notifications (channel);
CREATE INDEX IF NOT EXISTS notifications_status_idx ON public.notifications (status);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.notifications (created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_deleted_at_idx ON public.notifications (deleted_at);
