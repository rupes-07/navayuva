CREATE OR REPLACE FUNCTION public.auth_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_profile_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT p.id
  FROM public.profiles AS p
  WHERE p.user_id = public.auth_user_id()
    AND p.deleted_at IS NULL
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.has_role(required_role text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles AS ur
    JOIN public.roles AS r ON r.id = ur.role_id
    WHERE ur.user_id = public.auth_user_id()
      AND ur.deleted_at IS NULL
      AND r.deleted_at IS NULL
      AND r.name = required_role
  );
$$;

CREATE OR REPLACE FUNCTION public.has_permission(required_permission text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles AS ur
    JOIN public.roles AS r ON r.id = ur.role_id
    JOIN public.role_permissions AS rp ON rp.role_id = r.id
    JOIN public.permissions AS p ON p.id = rp.permission_id
    WHERE ur.user_id = public.auth_user_id()
      AND ur.deleted_at IS NULL
      AND r.deleted_at IS NULL
      AND rp.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND p.key = required_permission
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.has_role('ADMIN') OR public.has_role('SUPER_ADMIN');
$$;

CREATE OR REPLACE FUNCTION public.is_moderator()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.is_admin() OR public.has_role('MODERATOR');
$$;

CREATE OR REPLACE FUNCTION public.can_read_issue(p_issue_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.issues AS i
    WHERE i.id = p_issue_id
      AND i.deleted_at IS NULL
      AND (
        i.reporter_id = public.current_profile_id()
        OR public.is_admin()
        OR public.has_permission('ISSUE_READ')
        OR EXISTS (
          SELECT 1
          FROM public.officials AS o
          WHERE o.user_id = public.current_profile_id()
            AND o.deleted_at IS NULL
            AND o.status = 'ACTIVE'
            AND (
              o.jurisdiction_level = 'NATIONAL'
              OR (o.jurisdiction_level = 'PROVINCE' AND o.province_id = i.province_id)
              OR (o.jurisdiction_level = 'DISTRICT' AND o.district_id = i.district_id)
              OR (o.jurisdiction_level = 'MUNICIPALITY' AND o.municipality_id = i.municipality_id)
              OR (o.jurisdiction_level = 'WARD' AND o.ward_id = i.ward_id)
            )
        )
        OR EXISTS (
          SELECT 1
          FROM public.chapter_memberships AS cm
          WHERE cm.user_id = public.current_profile_id()
            AND cm.chapter_id = i.chapter_id
            AND cm.deleted_at IS NULL
            AND cm.status = 'ACTIVE'
            AND cm.role IN ('OFFICER', 'LEADER')
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_issue(p_issue_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.issues AS i
    WHERE i.id = p_issue_id
      AND i.deleted_at IS NULL
      AND (
        i.reporter_id = public.current_profile_id()
        OR public.is_admin()
        OR public.has_permission('ISSUE_UPDATE')
        OR public.has_permission('ISSUE_VERIFY')
        OR public.has_permission('ISSUE_REJECT')
        OR public.has_permission('ISSUE_ESCALATE')
        OR public.has_permission('ISSUE_RESOLVE')
        OR EXISTS (
          SELECT 1
          FROM public.officials AS o
          WHERE o.user_id = public.current_profile_id()
            AND o.deleted_at IS NULL
            AND o.status = 'ACTIVE'
            AND (
              o.jurisdiction_level = 'NATIONAL'
              OR (o.jurisdiction_level = 'PROVINCE' AND o.province_id = i.province_id)
              OR (o.jurisdiction_level = 'DISTRICT' AND o.district_id = i.district_id)
              OR (o.jurisdiction_level = 'MUNICIPALITY' AND o.municipality_id = i.municipality_id)
              OR (o.jurisdiction_level = 'WARD' AND o.ward_id = i.ward_id)
            )
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_read_project(p_project_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.projects AS p
    WHERE p.id = p_project_id
      AND p.deleted_at IS NULL
      AND (
        p.status IN ('PUBLISHED', 'ONGOING', 'COMPLETED')
        OR p.created_by = public.current_profile_id()
        OR public.is_admin()
        OR public.has_permission('PROJECT_UPDATE')
        OR EXISTS (
          SELECT 1
          FROM public.chapter_memberships AS cm
          WHERE cm.user_id = public.current_profile_id()
            AND cm.chapter_id = p.chapter_id
            AND cm.deleted_at IS NULL
            AND cm.status = 'ACTIVE'
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_project(p_project_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.projects AS p
    WHERE p.id = p_project_id
      AND p.deleted_at IS NULL
      AND (
        p.created_by = public.current_profile_id()
        OR public.is_admin()
        OR public.has_permission('PROJECT_UPDATE')
        OR EXISTS (
          SELECT 1
          FROM public.chapter_memberships AS cm
          WHERE cm.user_id = public.current_profile_id()
            AND cm.chapter_id = p.chapter_id
            AND cm.deleted_at IS NULL
            AND cm.status = 'ACTIVE'
            AND cm.role IN ('OFFICER', 'LEADER')
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_read_payment(p_payment_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.payments AS payment
    WHERE payment.id = p_payment_id
      AND payment.deleted_at IS NULL
      AND (
        payment.user_id = public.current_profile_id()
        OR public.is_admin()
        OR public.has_permission('PAYMENT_VIEW')
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_read_notification(p_notification_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.notifications AS notification
    WHERE notification.id = p_notification_id
      AND notification.deleted_at IS NULL
      AND (
        notification.recipient_id = public.current_profile_id()
        OR public.is_admin()
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_read_moderation_report(p_report_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.moderation_reports AS report
    WHERE report.id = p_report_id
      AND report.deleted_at IS NULL
      AND (
        report.reporter_id = public.current_profile_id()
        OR public.is_moderator()
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_access_audit()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.is_admin() OR public.has_permission('AUDIT_VIEW');
$$;

REVOKE ALL ON FUNCTION public.auth_user_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.current_profile_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_role(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_permission(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_moderator() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_issue(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_issue(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_project(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_project(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_payment(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_notification(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_moderation_report(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_access_audit() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.auth_user_id() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.current_profile_id() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.has_role(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.has_permission(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_moderator() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_issue(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_issue(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_project(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_project(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_payment(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_notification(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_moderation_report(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_audit() TO anon, authenticated;
