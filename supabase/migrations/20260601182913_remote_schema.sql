


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "moddatetime" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."accept_invitation"("invitation_token" "text") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_invitation record;
    v_user_id uuid;
    v_user_email text;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt()->>'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF v_user_email IS NULL OR trim(v_user_email) = '' THEN
        RAISE EXCEPTION 'Authenticated user email is missing';
    END IF;

    UPDATE public.invitations
    SET status = 'accepted', accepted_at = now()
    WHERE token = invitation_token
      AND status = 'pending'
      AND expires_at > now()
      AND lower(email) = lower(v_user_email)
    RETURNING * INTO v_invitation;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found, expired, or unauthorized';
    END IF;

    INSERT INTO public.home_members (home_id, user_id, role, status, joined_at, created_by)
    VALUES (v_invitation.home_id, v_user_id, v_invitation.role, 'active', now(), v_invitation.invited_by)
    ON CONFLICT (home_id, user_id)
    DO UPDATE SET
      role = EXCLUDED.role,
      status = 'active',
      deleted_at = NULL,
      joined_at = now(),
      updated_at = now(),
      updated_by = v_user_id;

    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
    VALUES (v_invitation.home_id, v_user_id, 'invitation_accepted', 'invitation', v_invitation.id);

    RETURN row_to_json(v_invitation);
END;
$$;


ALTER FUNCTION "public"."accept_invitation"("invitation_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auto_archive_completed_tasks"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.tasks
  SET archived_at = now()
  WHERE status = 'completed'
    AND completed_at < now() - INTERVAL '7 days'
    AND archived_at IS NULL
    AND deleted_at IS NULL;
END;
$$;


ALTER FUNCTION "public"."auto_archive_completed_tasks"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") RETURNS TABLE("member_a" "uuid", "member_b" "uuid", "net_amount" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  WITH movements AS (
    SELECT
      es.member_id AS debtor,
      e.paid_by AS creditor,
      es.amount::integer AS amount
    FROM public.expense_splits es
    JOIN public.expenses e ON e.id = es.expense_id
    WHERE e.home_id = p_home_id
      AND e.status = 'active'
      AND e.deleted_at IS NULL
      AND es.member_id <> e.paid_by

    UNION ALL

    SELECT
      s.from_member AS debtor,
      s.to_member AS creditor,
      (-s.amount)::integer AS amount
    FROM public.settlements s
    WHERE s.home_id = p_home_id
      AND s.from_member <> s.to_member
  ),
  canonical_pairs AS (
    SELECT
      CASE WHEN debtor::text < creditor::text THEN debtor ELSE creditor END AS member_low,
      CASE WHEN debtor::text < creditor::text THEN creditor ELSE debtor END AS member_high,
      CASE WHEN debtor::text < creditor::text THEN amount ELSE -amount END AS signed_amount
    FROM movements
  ),
  simplified AS (
    SELECT
      member_low,
      member_high,
      sum(signed_amount)::integer AS signed_amount
    FROM canonical_pairs
    GROUP BY member_low, member_high
  )
  SELECT
    CASE WHEN signed_amount > 0 THEN member_low ELSE member_high END AS member_a,
    CASE WHEN signed_amount > 0 THEN member_high ELSE member_low END AS member_b,
    abs(signed_amount)::integer AS net_amount
  FROM simplified
  WHERE signed_amount <> 0;
END;
$$;


ALTER FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_and_increment_rate_limit"("p_user_id" "uuid", "p_endpoint" "text", "p_window_start" timestamp with time zone, "p_max_requests" integer) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_count INTEGER;
BEGIN
  IF p_user_id IS NULL OR p_endpoint IS NULL OR p_endpoint = '' THEN
    RAISE EXCEPTION 'Invalid rate limit key';
  END IF;

  IF p_max_requests IS NULL OR p_max_requests < 1 THEN
    RAISE EXCEPTION 'Invalid rate limit maximum';
  END IF;

  INSERT INTO public.rate_limit_log (
    user_id,
    endpoint,
    window_start,
    count,
    updated_at
  )
  VALUES (
    p_user_id,
    p_endpoint,
    date_trunc('minute', p_window_start),
    1,
    now()
  )
  ON CONFLICT (user_id, endpoint, window_start)
  DO UPDATE SET
    count = public.rate_limit_log.count + 1,
    updated_at = now()
  RETURNING count INTO v_count;

  RETURN v_count <= p_max_requests;
END;
$$;


ALTER FUNCTION "public"."check_and_increment_rate_limit"("p_user_id" "uuid", "p_endpoint" "text", "p_window_start" timestamp with time zone, "p_max_requests" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_expense_member_membership"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = NEW.home_id
      AND hm.user_id = NEW.paid_by
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Payer must be an active member of the home';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_expense_member_membership"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_expense_split_membership"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_home_id uuid;
BEGIN
  SELECT home_id INTO v_home_id
  FROM public.expenses
  WHERE id = NEW.expense_id;

  IF v_home_id IS NULL THEN
    RAISE EXCEPTION 'Expense not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = v_home_id
      AND hm.user_id = NEW.member_id
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Split member must be an active member of the home';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_expense_split_membership"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_inventory_transaction_same_home"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_item_home_id uuid;
BEGIN
  SELECT home_id INTO v_item_home_id
  FROM public.inventory_items
  WHERE id = NEW.inventory_item_id;

  IF v_item_home_id IS NULL THEN
    RAISE EXCEPTION 'Inventory item not found';
  END IF;

  IF v_item_home_id != NEW.home_id THEN
    RAISE EXCEPTION 'Inventory item does not belong to the same home';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_inventory_transaction_same_home"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_settlement_membership"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = NEW.home_id
      AND hm.user_id = NEW.from_member
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Settlement sender must be an active member of the home';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = NEW.home_id
      AND hm.user_id = NEW.to_member
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Settlement receiver must be an active member of the home';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_settlement_membership"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_shopping_item_same_home"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_list_home_id uuid;
  v_category_home_id uuid;
  v_unit_home_id uuid;
BEGIN
  -- Get the home_id from the shopping list
  SELECT home_id INTO v_list_home_id
  FROM public.shopping_lists
  WHERE id = NEW.list_id;

  IF v_list_home_id IS NULL THEN
    RAISE EXCEPTION 'Shopping list not found';
  END IF;

  -- Check category belongs to same home (if provided)
  IF NEW.category_id IS NOT NULL THEN
    SELECT home_id INTO v_category_home_id
    FROM public.categories
    WHERE id = NEW.category_id;

    IF v_category_home_id IS NOT NULL AND v_category_home_id != v_list_home_id THEN
      RAISE EXCEPTION 'Category does not belong to the same home';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_shopping_item_same_home"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_task_assignee_membership"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.assigned_to IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.home_members hm
      WHERE hm.home_id = NEW.home_id
        AND hm.user_id = NEW.assigned_to
        AND hm.status = 'active'
        AND hm.deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Assignee must be an active member of the home';
    END IF;
  END IF;

  IF NEW.completed_by IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.home_members hm
      WHERE hm.home_id = NEW.home_id
        AND hm.user_id = NEW.completed_by
        AND hm.status = 'active'
        AND hm.deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Completor must be an active member of the home';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_task_assignee_membership"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_old_rate_limit_log"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  DELETE FROM public.rate_limit_log
  WHERE window_start < now() - INTERVAL '1 day';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;


ALTER FUNCTION "public"."cleanup_old_rate_limit_log"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_expense_with_splits"("p_home_id" "uuid", "p_amount" integer, "p_description" "text", "p_date" "date", "p_paid_by" "uuid", "p_converted_amount" integer, "p_category_id" "uuid" DEFAULT NULL::"uuid", "p_shopping_list_item_id" "uuid" DEFAULT NULL::"uuid", "p_currency_code" "text" DEFAULT 'SAR'::"text", "p_splits" "jsonb" DEFAULT '[]'::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_expense public.expenses%ROWTYPE;
  v_split_count integer := 0;
  v_distinct_member_count integer := 0;
  v_split_total integer := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_amount <= 0 OR p_converted_amount <= 0 THEN
    RAISE EXCEPTION 'Expense amount must be greater than zero';
  END IF;

  IF trim(coalesce(p_description, '')) = '' THEN
    RAISE EXCEPTION 'Expense description is required';
  END IF;

  IF length(trim(coalesce(p_currency_code, ''))) <> 3 THEN
    RAISE EXCEPTION 'Currency code must be 3 characters';
  END IF;

  IF p_splits IS NULL THEN
    p_splits := '[]'::jsonb;
  END IF;

  IF jsonb_typeof(p_splits) <> 'array' THEN
    RAISE EXCEPTION 'Splits must be a JSON array';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = v_user_id
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = p_paid_by
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Payer must be an active member of the home';
  END IF;

  IF p_category_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.categories c
    WHERE c.id = p_category_id
      AND c.type = 'expense'
      AND c.deleted_at IS NULL
      AND (c.is_default = true OR c.home_id = p_home_id)
  ) THEN
    RAISE EXCEPTION 'Expense category must belong to the home or be a default expense category';
  END IF;

  IF p_shopping_list_item_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.shopping_items si
    JOIN public.shopping_lists sl ON sl.id = si.list_id
    WHERE si.id = p_shopping_list_item_id
      AND si.deleted_at IS NULL
      AND sl.home_id = p_home_id
      AND sl.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Shopping list item must belong to the home';
  END IF;

  WITH split_rows AS (
    SELECT member_id, amount
    FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer)
  )
  SELECT
    count(*)::integer,
    count(DISTINCT member_id)::integer,
    coalesce(sum(amount), 0)::integer
  INTO v_split_count, v_distinct_member_count, v_split_total
  FROM split_rows;

  IF v_split_count > 0 THEN
    IF v_distinct_member_count <> v_split_count THEN
      RAISE EXCEPTION 'Split members must be unique';
    END IF;

    IF v_split_total <> p_converted_amount THEN
      RAISE EXCEPTION 'Split total must equal converted expense amount';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer)
      WHERE split.member_id IS NULL OR split.amount IS NULL OR split.amount < 0
    ) THEN
      RAISE EXCEPTION 'Each split must have a member and non-negative amount';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer)
      WHERE NOT EXISTS (
        SELECT 1
        FROM public.home_members hm
        WHERE hm.home_id = p_home_id
          AND hm.user_id = split.member_id
          AND hm.status = 'active'
          AND hm.deleted_at IS NULL
      )
    ) THEN
      RAISE EXCEPTION 'Split member must be an active member of the home';
    END IF;
  END IF;

  INSERT INTO public.expenses (
    home_id,
    amount,
    description,
    date,
    category_id,
    paid_by,
    shopping_list_item_id,
    currency_code,
    converted_amount,
    created_by
  )
  VALUES (
    p_home_id,
    p_amount,
    trim(p_description),
    p_date,
    p_category_id,
    p_paid_by,
    p_shopping_list_item_id,
    upper(trim(p_currency_code)),
    p_converted_amount,
    v_user_id
  )
  RETURNING * INTO v_expense;

  IF v_split_count > 1 THEN
    INSERT INTO public.expense_splits (expense_id, member_id, amount)
    SELECT v_expense.id, split.member_id, split.amount
    FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer);
  END IF;

  RETURN to_jsonb(v_expense);
END;
$$;


ALTER FUNCTION "public"."create_expense_with_splits"("p_home_id" "uuid", "p_amount" integer, "p_description" "text", "p_date" "date", "p_paid_by" "uuid", "p_converted_amount" integer, "p_category_id" "uuid", "p_shopping_list_item_id" "uuid", "p_currency_code" "text", "p_splits" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_invitation"("p_home_id" "uuid", "p_email" "text", "p_role" "text" DEFAULT 'member'::"text") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_user_id uuid;
  v_user_role text;
  v_existing_member uuid;
  v_existing_invitation uuid;
  v_invitation public.invitations%ROWTYPE;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT role INTO v_user_role
  FROM public.home_members
  WHERE home_id = p_home_id
    AND user_id = v_user_id
    AND status = 'active'
    AND deleted_at IS NULL;

  IF v_user_role IS NULL OR v_user_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Only owners and admins can create invitations';
  END IF;

  IF p_role NOT IN ('admin', 'member', 'viewer') THEN
    RAISE EXCEPTION 'Invalid role. Must be admin, member, or viewer';
  END IF;

  SELECT hm.user_id INTO v_existing_member
  FROM public.home_members hm
  JOIN public.users u ON u.id = hm.user_id
  WHERE hm.home_id = p_home_id
    AND lower(u.email) = lower(p_email)
    AND hm.status = 'active'
    AND hm.deleted_at IS NULL;

  IF v_existing_member IS NOT NULL THEN
    RAISE EXCEPTION 'User is already an active member of this home';
  END IF;

  SELECT id INTO v_existing_invitation
  FROM public.invitations
  WHERE home_id = p_home_id
    AND lower(email) = lower(p_email)
    AND status = 'pending'
    AND expires_at > now();

  IF v_existing_invitation IS NOT NULL THEN
    RAISE EXCEPTION 'A pending invitation already exists for this email';
  END IF;

  INSERT INTO public.invitations (
    home_id, email, role, token, status, invited_by, expires_at
  ) VALUES (
    p_home_id,
    lower(p_email),
    p_role,
    encode(extensions.gen_random_bytes(32), 'hex'),
    'pending',
    v_user_id,
    now() + INTERVAL '7 days'
  )
  RETURNING * INTO v_invitation;

  INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
  VALUES (p_home_id, v_user_id, 'invitation_sent', 'invitation', v_invitation.id);

  RETURN row_to_json(v_invitation);
END;
$$;


ALTER FUNCTION "public"."create_invitation"("p_home_id" "uuid", "p_email" "text", "p_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_next_recurring_task"("p_task_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_task RECORD;
  v_new_due_date DATE;
  v_new_task_id UUID;
BEGIN
  -- Get the completed recurring task
  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = p_task_id
    AND status = 'completed'
    AND recurrence_type IS NOT NULL
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Calculate next due date based on recurrence type
  IF v_task.due_date IS NOT NULL THEN
    CASE v_task.recurrence_type
      WHEN 'daily' THEN
        v_new_due_date := v_task.due_date + INTERVAL '1 day';
      WHEN 'weekly' THEN
        v_new_due_date := v_task.due_date + INTERVAL '7 days';
      WHEN 'monthly' THEN
        v_new_due_date := (v_task.due_date + INTERVAL '1 month');
        -- Handle months with fewer days (e.g., Jan 31 -> Feb 28)
        IF EXTRACT(DAY FROM v_task.due_date) > EXTRACT(DAY FROM v_new_due_date) THEN
          v_new_due_date := (DATE_TRUNC('month', v_new_due_date) + INTERVAL '1 month - 1 day')::DATE;
        END IF;
      ELSE
        v_new_due_date := v_task.due_date + INTERVAL '7 days';
    END CASE;
  ELSE
    -- If no due date, calculate from completion date
    CASE v_task.recurrence_type
      WHEN 'daily' THEN
        v_new_due_date := CURRENT_DATE + INTERVAL '1 day';
      WHEN 'weekly' THEN
        v_new_due_date := CURRENT_DATE + INTERVAL '7 days';
      WHEN 'monthly' THEN
        v_new_due_date := (CURRENT_DATE + INTERVAL '1 month');
      ELSE
        v_new_due_date := CURRENT_DATE + INTERVAL '7 days';
    END CASE;
  END IF;

  -- Create new task instance
  INSERT INTO public.tasks (
    home_id,
    title,
    description,
    due_date,
    category_id,
    assigned_to,
    recurrence_type,
    status,
    created_by
  ) VALUES (
    v_task.home_id,
    v_task.title,
    v_task.description,
    v_new_due_date,
    v_task.category_id,
    v_task.assigned_to,
    v_task.recurrence_type,
    'incomplete',
    v_task.created_by
  )
  RETURNING id INTO v_new_task_id;

  RETURN v_new_task_id;
END;
$$;


ALTER FUNCTION "public"."create_next_recurring_task"("p_task_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_actor_name"("p_user_id" "uuid") RETURNS "text"
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
  SELECT full_name FROM public.users WHERE id = p_user_id;
$$;


ALTER FUNCTION "public"."get_actor_name"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_notification_history"("p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0, "p_home_id" "uuid" DEFAULT NULL::"uuid", "p_category" "text" DEFAULT NULL::"text", "p_unread_only" boolean DEFAULT false) RETURNS SETOF "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  RETURN QUERY
  SELECT jsonb_build_object(
    'id', n.id,
    'user_id', n.user_id,
    'home_id', n.home_id,
    'category', COALESCE(n.category, n.type),
    'type', n.type,
    'title', n.title,
    'body', n.body,
    'actor_id', n.actor_id,
    'target_route', n.target_route,
    'reference_id', n.reference_id,
    'reference_type', n.reference_type,
    'is_read', n.is_read,
    'batch_key', n.batch_key,
    'created_at', n.created_at
  )
  FROM public.notifications n
  WHERE n.user_id = auth.uid()
    AND (p_home_id IS NULL OR n.home_id = p_home_id)
    AND (p_category IS NULL OR COALESCE(n.category, n.type) = p_category)
    AND (NOT p_unread_only OR n.is_read = false)
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


ALTER FUNCTION "public"."get_notification_history"("p_limit" integer, "p_offset" integer, "p_home_id" "uuid", "p_category" "text", "p_unread_only" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_tables_last_update"("p_home_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members
    WHERE home_id = p_home_id
      AND user_id = auth.uid()
      AND status = 'active'
      AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  v_result := jsonb_build_object(
    'shopping_lists', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.shopping_lists
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'shopping_items', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.shopping_items
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'tasks', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.tasks
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'inventory_items', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.inventory_items
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'expenses', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.expenses
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'categories', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.categories
      WHERE home_id = p_home_id AND deleted_at IS NULL
    )
  );

  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."get_tables_last_update"("p_home_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_home"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  INSERT INTO public.home_members (home_id, user_id, role, status)
  VALUES (NEW.id, NEW.owner_id, 'owner', 'active');
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_home"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  INSERT INTO public.users (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    NEW.email
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE has_balance boolean;
BEGIN
  -- Require authentication
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Require active home membership for caller
  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Only allow checking own balances unless caller is owner/admin
  IF auth.uid() <> p_user_id AND NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = auth.uid()
      AND hm.role IN ('owner', 'admin')
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.calculate_home_balances(p_home_id)
    WHERE member_a = p_user_id OR member_b = p_user_id
  ) INTO has_balance;
  RETURN has_balance;
END;
$$;


ALTER FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_template_usage"("template_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_home_id uuid;
begin
  select home_id into v_home_id from public.item_templates where id = template_id;
  if not exists (
    select 1 from public.home_members 
    where home_id = v_home_id 
    and user_id = auth.uid() 
    and status = 'active'
    and deleted_at is null
  ) then
    raise exception 'Not authorized or template not found';
  end if;
  update public.item_templates
  set usage_count = coalesce(usage_count, 0) + 1,
      updated_at = now()
  where id = template_id;
end;
$$;


ALTER FUNCTION "public"."increment_template_usage"("template_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_home_member"("p_home_id" "uuid") RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM home_members
    WHERE home_id = p_home_id
      AND user_id = auth.uid()
      AND status = 'active'
      AND deleted_at IS NULL
  );
$$;


ALTER FUNCTION "public"."is_home_member"("p_home_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_not_viewer"("p_home_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.home_members
    WHERE home_id = p_home_id
      AND user_id = auth.uid()
      AND role != 'viewer'
      AND status = 'active'
      AND deleted_at IS NULL
  );
END;
$$;


ALTER FUNCTION "public"."is_not_viewer"("p_home_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_not_viewer_for_list"("p_list_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.shopping_lists sl
    JOIN public.home_members hm ON sl.home_id = hm.home_id
    WHERE sl.id = p_list_id
      AND hm.user_id = auth.uid()
      AND hm.role != 'viewer'
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
      AND sl.deleted_at IS NULL
  );
END;
$$;


ALTER FUNCTION "public"."is_not_viewer_for_list"("p_list_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_home_member_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_action text;
  v_actor uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_action := 'member_joined';
    v_actor := COALESCE(NEW.created_by, NEW.user_id);
    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
    VALUES (NEW.home_id, v_actor, v_action, 'home_member', NEW.user_id,
      jsonb_build_object('user_id', NEW.user_id, 'role', NEW.role));
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.role IS DISTINCT FROM NEW.role THEN
      v_actor := COALESCE(NEW.updated_by, NEW.user_id);
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (NEW.home_id, v_actor, 'role_changed', 'home_member', NEW.user_id,
        jsonb_build_object('user_id', NEW.user_id, 'old_role', OLD.role, 'new_role', NEW.role));
    END IF;
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      v_actor := COALESCE(NEW.updated_by, NEW.user_id);
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (NEW.home_id, v_actor, 'member_removed', 'home_member', NEW.user_id,
        jsonb_build_object('user_id', NEW.user_id));
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_home_member_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_invitation_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (NEW.home_id, NEW.invited_by, 'invitation_accepted', 'invitation', NEW.id);
    ELSIF NEW.status = 'cancelled' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (NEW.home_id, NEW.invited_by, 'invitation_cancelled', 'invitation', NEW.id);
    ELSIF NEW.status = 'expired' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (NEW.home_id, NEW.invited_by, 'invitation_expired', 'invitation', NEW.id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_invitation_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_shopping_item_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_home_id uuid;
  v_list_title text;
BEGIN
  SELECT sl.home_id, sl.title INTO v_home_id, v_list_title
  FROM public.shopping_lists sl
  WHERE sl.id = COALESCE(NEW.list_id, OLD.list_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
    VALUES (v_home_id, NEW.created_by, 'item_added', 'shopping_item', NEW.id,
      jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'item_deleted', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
    IF NEW.status = 'completed' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.completed_by, NEW.updated_by, NEW.created_by), 'item_purchased', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
    IF NEW.status = 'pending' AND OLD.status = 'completed' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'item_unpurchased', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
    IF OLD.name IS DISTINCT FROM NEW.name OR OLD.quantity IS DISTINCT FROM NEW.quantity THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'item_updated', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_shopping_item_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_shopping_list_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_action text;
  v_home_id uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_action := 'list_created';
    v_home_id := NEW.home_id;
    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
    VALUES (v_home_id, NEW.created_by, v_action, 'shopping_list', NEW.id,
      jsonb_build_object('title', NEW.title));
  ELSIF TG_OP = 'UPDATE' THEN
    v_home_id := NEW.home_id;
    IF OLD.title IS DISTINCT FROM NEW.title THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'list_renamed', 'shopping_list', NEW.id,
        jsonb_build_object('old_title', OLD.title, 'new_title', NEW.title));
    END IF;
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'list_' || NEW.status, 'shopping_list', NEW.id,
        jsonb_build_object('old_status', OLD.status, 'new_status', NEW.status));
    END IF;
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'list_deleted', 'shopping_list', NEW.id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_shopping_list_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_invitee_on_invitation"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_user_id uuid;
  v_home_name text;
  v_actor_name text;
BEGIN
  SELECT id INTO v_user_id FROM public.users WHERE lower(email) = lower(NEW.email);
  IF v_user_id IS NULL THEN RETURN NEW; END IF;

  SELECT name INTO v_home_name FROM public.homes WHERE id = NEW.home_id;
  SELECT full_name INTO v_actor_name FROM public.users WHERE id = NEW.invited_by;

  INSERT INTO public.notifications (user_id, home_id, category, type, title, body, actor_id, reference_id, reference_type, target_route)
  VALUES (v_user_id, NEW.home_id, 'invitation', 'invitation_received',
    'دعوة', 'تمت دعوتك إلى ' || COALESCE(v_home_name, 'المنزل') || ' من قبل ' || COALESCE(v_actor_name, 'شخص'),
    NEW.invited_by, NEW.id, 'invitation', '/invitations');

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_invitee_on_invitation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_inviter_on_invitation_response"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_home_name text;
  v_invitee_name text;
  v_title text;
  v_body text;
BEGIN
  IF NEW.status NOT IN ('accepted', 'cancelled', 'declined') THEN RETURN NEW; END IF;
  IF OLD.status != 'pending' THEN RETURN NEW; END IF;

  SELECT name INTO v_home_name FROM public.homes WHERE id = NEW.home_id;
  SELECT full_name INTO v_invitee_name FROM public.users WHERE lower(email) = lower(NEW.email);

  IF NEW.status = 'accepted' THEN
    v_title := 'دعوة مقبولة';
    v_body := COALESCE(v_invitee_name, 'شخص') || ' قبل دعوتك للانضمام إلى ' || COALESCE(v_home_name, 'المنزل');
  ELSIF NEW.status = 'cancelled' THEN
    v_title := 'دعوة ملغاة';
    v_body := 'تم إلغاء الدعوة المرسلة إلى ' || COALESCE(v_invitee_name, 'شخص');
  ELSE
    v_title := 'دعوة مرفوضة';
    v_body := COALESCE(v_invitee_name, 'شخص') || ' رفض دعوتك للانضمام إلى ' || COALESCE(v_home_name, 'المنزل');
  END IF;

  -- Delete stale pending notification for this invitation
  DELETE FROM public.notifications
  WHERE reference_id = NEW.id AND reference_type = 'invitation' AND type = 'invitation_received';

  INSERT INTO public.notifications (user_id, home_id, category, type, title, body, actor_id, reference_id, reference_type, target_route)
  VALUES (NEW.invited_by, NEW.home_id, 'invitation', 'invitation_' || NEW.status,
    v_title, v_body,
    (SELECT id FROM public.users WHERE lower(email) = lower(NEW.email)),
    NEW.id, 'invitation', '/invitations');

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_inviter_on_invitation_response"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_category_critical_updates"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if OLD.home_id is distinct from NEW.home_id then
    raise exception 'Cannot change the home_id of a category';
  end if;
  if OLD.type is distinct from NEW.type then
    raise exception 'Cannot change the type of a category';
  end if;
  if OLD.is_default is distinct from NEW.is_default then
    raise exception 'Cannot change the is_default status of a category';
  end if;
  return NEW;
end;
$$;


ALTER FUNCTION "public"."prevent_category_critical_updates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."protect_home_owner"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_owner_count integer;
BEGIN
  -- If changing role FROM owner, ensure it's not the last owner
  -- BUT allow if the new role is also being set in the same transaction
  IF OLD.role = 'owner' AND NEW.role != 'owner' THEN
    -- Check if there's another active owner (excluding self)
    SELECT COUNT(*) INTO v_owner_count
    FROM public.home_members
    WHERE home_id = OLD.home_id
      AND role = 'owner'
      AND status = 'active'
      AND deleted_at IS NULL
      AND user_id != OLD.user_id;

    -- If no other owner exists, block the demotion
    IF v_owner_count = 0 THEN
      RAISE EXCEPTION 'Cannot demote the last owner. Transfer ownership first.';
    END IF;
  END IF;

  -- If soft-deleting an owner, ensure it's not the last owner
  IF OLD.role = 'owner' AND NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    SELECT COUNT(*) INTO v_owner_count
    FROM public.home_members
    WHERE home_id = OLD.home_id
      AND role = 'owner'
      AND status = 'active'
      AND deleted_at IS NULL
      AND user_id != OLD.user_id;

    IF v_owner_count = 0 THEN
      RAISE EXCEPTION 'Cannot remove the last owner. Transfer ownership first.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."protect_home_owner"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."record_settlement"("p_home_id" "uuid", "p_from_member" "uuid", "p_to_member" "uuid", "p_amount" numeric, "p_payment_method" "text", "p_date" "date") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_user_id uuid;
  v_balance record;
  v_max_amount numeric := 0;
  v_settlement_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF NOT public.is_not_viewer(p_home_id) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;
  FOR v_balance IN SELECT * FROM public.calculate_home_balances(p_home_id) LOOP
    IF v_balance.member_a = p_from_member AND v_balance.member_b = p_to_member THEN
      v_max_amount := v_balance.net_amount;
    ELSIF v_balance.member_a = p_to_member AND v_balance.member_b = p_from_member THEN
      v_max_amount := -v_balance.net_amount;
    END IF;
  END LOOP;
  IF v_max_amount <= 0 THEN
    RAISE EXCEPTION 'No outstanding balance to settle';
  END IF;
  IF p_amount > v_max_amount THEN
    RAISE EXCEPTION 'Settlement amount (%) cannot exceed outstanding balance (%)', p_amount, v_max_amount;
  END IF;
  INSERT INTO public.settlements (
    home_id, from_member, to_member, amount, payment_method, date, created_by
  ) VALUES (
    p_home_id, p_from_member, p_to_member, p_amount, p_payment_method, p_date, v_user_id
  ) RETURNING id INTO v_settlement_id;
  RETURN (SELECT to_jsonb(s.*) FROM public.settlements s WHERE s.id = v_settlement_id);
END;
$$;


ALTER FUNCTION "public"."record_settlement"("p_home_id" "uuid", "p_from_member" "uuid", "p_to_member" "uuid", "p_amount" numeric, "p_payment_method" "text", "p_date" "date") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."shopping_items" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "list_id" "uuid" NOT NULL,
    "product_id" "uuid",
    "name" "text" NOT NULL,
    "quantity" numeric(10,2) DEFAULT 1,
    "unit_id" "uuid",
    "category_id" "uuid",
    "priority" "text" DEFAULT 'medium'::"text",
    "note" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "assigned_to" "uuid",
    "created_by" "uuid" NOT NULL,
    "updated_by" "uuid",
    "completed_by" "uuid",
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    "estimated_price" numeric(10,2),
    "currency" "text" DEFAULT 'SAR'::"text",
    "purchased_quantity" numeric(10,2) DEFAULT 0 NOT NULL,
    "home_id" "uuid" NOT NULL,
    CONSTRAINT "shopping_items_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'medium'::"text", 'high'::"text", 'urgent'::"text"]))),
    CONSTRAINT "shopping_items_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'cancelled'::"text"])))
);

ALTER TABLE ONLY "public"."shopping_items" REPLICA IDENTITY FULL;


ALTER TABLE "public"."shopping_items" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."restore_shopping_item"("p_item_id" "uuid") RETURNS "public"."shopping_items"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id uuid;
  v_home_id uuid;
  v_item public.shopping_items;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select sl.home_id
  into v_home_id
  from public.shopping_items si
  join public.shopping_lists sl on sl.id = si.list_id
  where si.id = p_item_id;

  if v_home_id is null then
    raise exception 'Shopping item not found';
  end if;

  if not exists (
    select 1
    from public.home_members hm
    where hm.home_id = v_home_id
      and hm.user_id = v_user_id
      and hm.status = 'active'
      and hm.deleted_at is null
  ) then
    raise exception 'Not authorized to restore this shopping item';
  end if;

  update public.shopping_items
  set deleted_at = null,
      updated_at = now(),
      updated_by = v_user_id
  where id = p_item_id
  returning * into v_item;

  return v_item;
end;
$$;


ALTER FUNCTION "public"."restore_shopping_item"("p_item_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_home_members_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_home_members_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_shopping_item_home_id"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
    SELECT home_id INTO NEW.home_id
    FROM shopping_lists
    WHERE id = NEW.list_id;

    IF NEW.home_id IS NULL THEN
        RAISE EXCEPTION 'Shopping list not found for item %', NEW.list_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_shopping_item_home_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_shopping_item_purchase_state"("p_item_id" "uuid", "p_purchased_quantity" numeric) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_item shopping_items%ROWTYPE;
  v_home_id uuid;
  v_total numeric;
  v_status text;
  v_completed_at timestamptz;
  v_completed_by uuid;
BEGIN
  -- Fetch the item
  SELECT * INTO v_item
  FROM shopping_items
  WHERE id = p_item_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shopping item not found: %', p_item_id;
  END IF;

  -- Get home_id via the shopping list
  SELECT sl.home_id INTO v_home_id
  FROM shopping_lists sl
  WHERE sl.id = v_item.list_id;

  -- Verify caller is a member of the home
  IF NOT EXISTS (
    SELECT 1 FROM home_members hm
    WHERE hm.home_id = v_home_id
      AND hm.user_id = auth.uid()
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Permission denied: not a home member';
  END IF;

  -- Derive status from purchased_quantity vs quantity
  v_total := COALESCE(v_item.quantity, 1);

  IF p_purchased_quantity >= v_total THEN
    v_status := 'completed';
    v_completed_at := now();
    v_completed_by := auth.uid();
  ELSIF p_purchased_quantity > 0 THEN
    v_status := 'in_progress';
    v_completed_at := NULL;
    v_completed_by := NULL;
  ELSE
    v_status := 'pending';
    v_completed_at := NULL;
    v_completed_by := NULL;
  END IF;

  -- Update the item
  UPDATE shopping_items SET
    purchased_quantity = p_purchased_quantity,
    status = v_status,
    completed_at = v_completed_at,
    completed_by = v_completed_by,
    updated_at = now(),
    updated_by = auth.uid()
  WHERE id = p_item_id
  RETURNING * INTO v_item;

  -- Return the updated item as JSON
  RETURN jsonb_build_object(
    'id', v_item.id,
    'list_id', v_item.list_id,
    'product_id', v_item.product_id,
    'name', v_item.name,
    'quantity', v_item.quantity,
    'unit_id', v_item.unit_id,
    'category_id', v_item.category_id,
    'priority', v_item.priority,
    'note', v_item.note,
    'status', v_item.status,
    'assigned_to', v_item.assigned_to,
    'created_by', v_item.created_by,
    'updated_by', v_item.updated_by,
    'completed_by', v_item.completed_by,
    'completed_at', v_item.completed_at,
    'created_at', v_item.created_at,
    'updated_at', v_item.updated_at,
    'deleted_at', v_item.deleted_at,
    'estimated_price', v_item.estimated_price,
    'currency', v_item.currency,
    'purchased_quantity', v_item.purchased_quantity,
    'home_id', v_home_id
  );
END;
$$;


ALTER FUNCTION "public"."set_shopping_item_purchase_state"("p_item_id" "uuid", "p_purchased_quantity" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_template_on_add"("p_home_id" "uuid", "p_name" "text", "p_quantity" numeric, "p_unit_id" "uuid", "p_category_id" "uuid", "p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  p_user_id := auth.uid();
  if not exists (
    select 1 from public.home_members 
    where home_id = p_home_id 
    and user_id = p_user_id 
    and status = 'active'
    and deleted_at is null
  ) then
    raise exception 'Not authorized';
  end if;
  insert into public.item_templates (
    home_id, name, default_quantity, default_unit_id, default_category_id, created_by, usage_count
  ) values (
    p_home_id, p_name, p_quantity, p_unit_id, p_category_id, p_user_id, 1
  )
  on conflict (home_id, name) do update
  set usage_count = coalesce(item_templates.usage_count, 0) + 1,
      updated_at = now();
end;
$$;


ALTER FUNCTION "public"."sync_template_on_add"("p_home_id" "uuid", "p_name" "text", "p_quantity" numeric, "p_unit_id" "uuid", "p_category_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."transfer_home_ownership"("p_home_id" "uuid", "p_new_owner_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_user_id uuid;
  v_current_role text;
  v_new_owner_role text;
BEGIN
  v_user_id := auth.uid();
  SELECT role INTO v_current_role FROM public.home_members
  WHERE home_id = p_home_id AND user_id = v_user_id AND status = 'active' AND deleted_at IS NULL;
  IF v_current_role != 'owner' THEN
    RAISE EXCEPTION 'Only owner can transfer ownership';
  END IF;
  SELECT role INTO v_new_owner_role FROM public.home_members
  WHERE home_id = p_home_id AND user_id = p_new_owner_id AND status = 'active' AND deleted_at IS NULL;
  IF v_new_owner_role IS NULL THEN
    RAISE EXCEPTION 'New owner must be an active member';
  END IF;
  UPDATE public.home_members
  SET role = 'admin', updated_at = NOW(), updated_by = v_user_id
  WHERE home_id = p_home_id AND user_id = v_user_id;
  UPDATE public.home_members
  SET role = 'owner', updated_at = NOW(), updated_by = v_user_id
  WHERE home_id = p_home_id AND user_id = p_new_owner_id;
  UPDATE public.homes
  SET owner_id = p_new_owner_id, updated_at = NOW()
  WHERE id = p_home_id;
  INSERT INTO public.activity_logs (
    home_id, user_id, action, entity_type, entity_id, metadata
  ) VALUES (
    p_home_id, v_user_id, 'ownership_transferred', 'home', p_home_id, jsonb_build_object('new_owner_id', p_new_owner_id)
  );
END;
$$;


ALTER FUNCTION "public"."transfer_home_ownership"("p_home_id" "uuid", "p_new_owner_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_item jsonb;
  v_name text;
  v_quantity numeric;
  v_unit_id uuid;
  v_category_id uuid;
  v_existing_id uuid;
  v_existing_qty numeric;
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF NOT public.is_not_viewer(p_home_id) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_name := v_item->>'name';
    v_quantity := (v_item->>'quantity')::numeric;
    IF (v_item->>'unitId') IS NOT NULL THEN
      v_unit_id := (v_item->>'unitId')::uuid;
    ELSE
      v_unit_id := NULL;
    END IF;
    IF (v_item->>'categoryId') IS NOT NULL THEN
      v_category_id := (v_item->>'categoryId')::uuid;
    ELSE
      v_category_id := NULL;
    END IF;
    LOOP
      UPDATE public.inventory_items
      SET quantity = quantity + v_quantity,
          updated_by = v_user_id
      WHERE home_id = p_home_id
        AND lower(name) = lower(v_name)
        AND unit_id IS NOT DISTINCT FROM v_unit_id
        AND deleted_at IS NULL
      RETURNING id, quantity INTO v_existing_id, v_existing_qty;
      IF FOUND THEN
        INSERT INTO public.inventory_transactions (
          inventory_item_id, home_id, previous_quantity, new_quantity, change_reason, changed_by
        ) VALUES (
          v_existing_id, p_home_id, v_existing_qty - v_quantity, v_existing_qty, 'shopping_restock', v_user_id
        );
        EXIT;
      END IF;
      BEGIN
        INSERT INTO public.inventory_items (
          home_id, name, quantity, unit_id, category_id, created_by, updated_by
        ) VALUES (
          p_home_id, v_name, v_quantity, v_unit_id, v_category_id, v_user_id, v_user_id
        ) RETURNING id INTO v_existing_id;
        INSERT INTO public.inventory_transactions (
          inventory_item_id, home_id, previous_quantity, new_quantity, change_reason, changed_by
        ) VALUES (
          v_existing_id, p_home_id, 0, v_quantity, 'shopping_restock', v_user_id
        );
        EXIT;
      EXCEPTION WHEN unique_violation THEN
      END;
    END LOOP;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_validate_item_template"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_cat_home_id uuid;
  v_cat_type text;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.home_id != OLD.home_id THEN
    RAISE EXCEPTION 'Cannot change home_id of a template';
  END IF;
  IF NEW.default_category_id IS NOT NULL THEN
    SELECT home_id, type INTO v_cat_home_id, v_cat_type
    FROM public.categories WHERE id = NEW.default_category_id AND deleted_at IS NULL;
    IF v_cat_home_id != NEW.home_id THEN
      RAISE EXCEPTION 'Category must belong to the same home';
    END IF;
    IF v_cat_type != 'shopping' THEN
      RAISE EXCEPTION 'Category must be of type shopping';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trg_validate_item_template"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_validate_shopping_item_template"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_cat_home_id uuid;
  v_cat_type text;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.home_id != OLD.home_id THEN
    RAISE EXCEPTION 'Cannot change home_id of a template';
  END IF;
  IF NEW.default_category_id IS NOT NULL THEN
    SELECT home_id, type INTO v_cat_home_id, v_cat_type
    FROM public.categories WHERE id = NEW.default_category_id AND deleted_at IS NULL;
    IF v_cat_home_id != NEW.home_id THEN
      RAISE EXCEPTION 'Category must belong to the same home';
    END IF;
    IF v_cat_type != 'shopping' THEN
      RAISE EXCEPTION 'Category must be of type shopping';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trg_validate_shopping_item_template"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_expenses_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_expenses_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_task_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_task_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_category_assignment"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_category_type text;
  v_category_home_id uuid;
  v_category_is_default boolean;
  v_expected_type text;
begin
  if NEW.category_id is not null then
    select type, home_id, is_default into v_category_type, v_category_home_id, v_category_is_default
    from public.categories where id = NEW.category_id;
    if not found then
      raise exception 'Category not found';
    end if;
    if v_category_home_id is distinct from NEW.home_id and not coalesce(v_category_is_default, false) then
      raise exception 'Category does not belong to this home';
    end if;
    if TG_TABLE_NAME = 'inventory_items' then
      v_expected_type := 'inventory';
    end if;
    if v_expected_type is not null and v_category_type != v_expected_type then
      raise exception 'Invalid category type for this item, expected %', v_expected_type;
    end if;
  end if;
  return NEW;
end;
$$;


ALTER FUNCTION "public"."validate_category_assignment"() OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."activity_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "action" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid",
    "entity_name" "text",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "actor_name" "text"
);

ALTER TABLE ONLY "public"."activity_logs" REPLICA IDENTITY FULL;


ALTER TABLE "public"."activity_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."beta_feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "feedback_type" "text" NOT NULL,
    "description" "text" NOT NULL,
    "star_rating" integer,
    "device_info" "jsonb",
    "screen_route" "text",
    "app_logs" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "beta_feedback_feedback_type_check" CHECK (("feedback_type" = ANY (ARRAY['bug'::"text", 'survey'::"text"]))),
    CONSTRAINT "beta_feedback_star_rating_check" CHECK ((("star_rating" >= 1) AND ("star_rating" <= 5)))
);


ALTER TABLE "public"."beta_feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "home_id" "uuid",
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "icon" "text",
    "color" "text",
    "sort_order" integer DEFAULT 0,
    "is_default" boolean DEFAULT false,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "categories_type_check" CHECK (("type" = ANY (ARRAY['shopping'::"text", 'inventory'::"text", 'expense'::"text"])))
);

ALTER TABLE ONLY "public"."categories" REPLICA IDENTITY FULL;


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."device_tokens" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "platform" "text",
    "device_name" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    CONSTRAINT "device_tokens_platform_check" CHECK (("platform" = ANY (ARRAY['android'::"text", 'ios'::"text", 'web'::"text"])))
);

ALTER TABLE ONLY "public"."device_tokens" REPLICA IDENTITY FULL;


ALTER TABLE "public"."device_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."expense_splits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "expense_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "amount" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "expense_splits_amount_check" CHECK (("amount" >= 0))
);

ALTER TABLE ONLY "public"."expense_splits" REPLICA IDENTITY FULL;


ALTER TABLE "public"."expense_splits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."expenses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "amount" integer NOT NULL,
    "description" "text" NOT NULL,
    "date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "category_id" "uuid",
    "paid_by" "uuid" NOT NULL,
    "shopping_list_item_id" "uuid",
    "currency_code" character varying(3) DEFAULT 'SAR'::character varying NOT NULL,
    "converted_amount" integer NOT NULL,
    "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "updated_by" "uuid",
    "cancelled_by" "uuid",
    CONSTRAINT "expenses_amount_check" CHECK (("amount" > 0)),
    CONSTRAINT "expenses_converted_amount_check" CHECK (("converted_amount" > 0)),
    CONSTRAINT "expenses_status_check" CHECK ((("status")::"text" = ANY ((ARRAY['active'::character varying, 'cancelled'::character varying])::"text"[])))
);

ALTER TABLE ONLY "public"."expenses" REPLICA IDENTITY FULL;


ALTER TABLE "public"."expenses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."home_members" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text",
    "joined_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "updated_by" "uuid",
    "created_by" "uuid",
    CONSTRAINT "home_members_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text", 'viewer'::"text"]))),
    CONSTRAINT "home_members_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'pending'::"text"])))
);

ALTER TABLE ONLY "public"."home_members" REPLICA IDENTITY FULL;


ALTER TABLE "public"."home_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."homes" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "default_currency" "text" DEFAULT 'TRY'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "homes_type_check" CHECK (("type" = ANY (ARRAY['family'::"text", 'couple'::"text", 'shared_house'::"text", 'student_housing'::"text", 'single_user'::"text", 'office'::"text"])))
);

ALTER TABLE ONLY "public"."homes" REPLICA IDENTITY FULL;


ALTER TABLE "public"."homes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "quantity" numeric(10,2) DEFAULT 0 NOT NULL,
    "unit_id" "uuid",
    "category_id" "uuid",
    "min_quantity" numeric(10,2),
    "notes" "text",
    "created_by" "uuid" NOT NULL,
    "updated_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "inventory_items_min_quantity_check" CHECK ((("min_quantity" IS NULL) OR ("min_quantity" >= (0)::numeric))),
    CONSTRAINT "inventory_items_quantity_check" CHECK (("quantity" >= (0)::numeric))
);

ALTER TABLE ONLY "public"."inventory_items" REPLICA IDENTITY FULL;


ALTER TABLE "public"."inventory_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "inventory_item_id" "uuid" NOT NULL,
    "home_id" "uuid" NOT NULL,
    "previous_quantity" numeric(10,2) NOT NULL,
    "new_quantity" numeric(10,2) NOT NULL,
    "change_reason" character varying(50) NOT NULL,
    "changed_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_transactions_change_reason_check" CHECK ((("change_reason")::"text" = ANY ((ARRAY['manual_update'::character varying, 'shopping_restock'::character varying, 'zero_removal'::character varying, 'initial_add'::character varying, 'delete'::character varying])::"text"[])))
);


ALTER TABLE "public"."inventory_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invitations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "email" "text",
    "phone" "text",
    "role" "text" DEFAULT 'member'::"text",
    "token" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "invited_by" "uuid" NOT NULL,
    "expires_at" timestamp with time zone,
    "accepted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "invitations_role_check" CHECK (("role" = ANY (ARRAY['admin'::"text", 'member'::"text", 'viewer'::"text"]))),
    CONSTRAINT "invitations_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'expired'::"text", 'cancelled'::"text"])))
);

ALTER TABLE ONLY "public"."invitations" REPLICA IDENTITY FULL;


ALTER TABLE "public"."invitations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."item_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "default_quantity" numeric(10,2) DEFAULT 1 NOT NULL,
    "default_unit_id" "uuid",
    "default_category_id" "uuid",
    "usage_count" integer DEFAULT 0 NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."item_templates" REPLICA IDENTITY FULL;


ALTER TABLE "public"."item_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_preferences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "home_id" "uuid" NOT NULL,
    "item_added" boolean DEFAULT true NOT NULL,
    "item_completed" boolean DEFAULT true NOT NULL,
    "low_stock" boolean DEFAULT true NOT NULL,
    "expiry_alert" boolean DEFAULT true NOT NULL,
    "expense_added" boolean DEFAULT true NOT NULL,
    "task_due" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notification_preferences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "home_id" "uuid",
    "title" "text" NOT NULL,
    "body" "text",
    "type" "text" NOT NULL,
    "entity_type" "text",
    "entity_id" "uuid",
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "category" "text",
    "actor_id" "uuid",
    "target_route" "text",
    "reference_id" "uuid",
    "reference_type" "text",
    "batch_key" "text"
);

ALTER TABLE ONLY "public"."notifications" REPLICA IDENTITY FULL;


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "home_id" "uuid",
    "name" "text" NOT NULL,
    "default_category_id" "uuid",
    "default_unit_id" "uuid",
    "barcode" "text",
    "image_url" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone
);

ALTER TABLE ONLY "public"."products" REPLICA IDENTITY FULL;


ALTER TABLE "public"."products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."rate_limit_log" (
    "user_id" "uuid" NOT NULL,
    "endpoint" "text" NOT NULL,
    "window_start" timestamp with time zone NOT NULL,
    "count" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "rate_limit_log_count_check" CHECK (("count" >= 0))
);


ALTER TABLE "public"."rate_limit_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role" "text" NOT NULL,
    "permission" "text" NOT NULL,
    "allowed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "role_permissions_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text", 'viewer'::"text"])))
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."settlements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "from_member" "uuid" NOT NULL,
    "to_member" "uuid" NOT NULL,
    "amount" integer NOT NULL,
    "payment_method" character varying(50) DEFAULT 'cash'::character varying NOT NULL,
    "date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "settlements_amount_check" CHECK (("amount" > 0)),
    CONSTRAINT "settlements_check" CHECK (("from_member" <> "to_member")),
    CONSTRAINT "settlements_payment_method_check" CHECK ((("payment_method")::"text" = ANY ((ARRAY['cash'::character varying, 'transfer'::character varying, 'other'::character varying])::"text"[])))
);

ALTER TABLE ONLY "public"."settlements" REPLICA IDENTITY FULL;


ALTER TABLE "public"."settlements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shopping_lists" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "type" "text",
    "status" "text" DEFAULT 'active'::"text",
    "created_by" "uuid" NOT NULL,
    "updated_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    "icon" "text" DEFAULT 'shopping_cart'::"text",
    CONSTRAINT "shopping_lists_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'completed'::"text", 'archived'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "shopping_lists_type_check" CHECK (("type" = ANY (ARRAY['grocery'::"text", 'pharmacy'::"text", 'hardware'::"text", 'other'::"text"])))
);

ALTER TABLE ONLY "public"."shopping_lists" REPLICA IDENTITY FULL;


ALTER TABLE "public"."shopping_lists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shopping_mode_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shopping_list_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "home_id" "uuid" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ended_at" timestamp with time zone,
    "items_purchased_count" integer DEFAULT 0 NOT NULL,
    "items_total_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."shopping_mode_sessions" REPLICA IDENTITY FULL;


ALTER TABLE "public"."shopping_mode_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sync_operations_log" (
    "idempotency_key" "uuid" NOT NULL,
    "user_id" "uuid",
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid" NOT NULL,
    "operation_type" "text" NOT NULL,
    "executed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."sync_operations_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."task_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "task_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "task_comment_content_not_empty" CHECK (("char_length"("content") > 0))
);

ALTER TABLE ONLY "public"."task_comments" REPLICA IDENTITY FULL;


ALTER TABLE "public"."task_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "title" character varying(200) NOT NULL,
    "description" "text",
    "due_date" "date",
    "category_id" "uuid",
    "assigned_to" "uuid",
    "status" character varying(20) DEFAULT 'incomplete'::character varying NOT NULL,
    "recurrence_type" character varying(20),
    "completed_by" "uuid",
    "completed_at" timestamp with time zone,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "archived_at" timestamp with time zone,
    "updated_by" "uuid",
    CONSTRAINT "task_description_length" CHECK ((("description" IS NULL) OR ("char_length"("description") <= 2000))),
    CONSTRAINT "task_title_length" CHECK (("char_length"(("title")::"text") <= 200)),
    CONSTRAINT "tasks_recurrence_type_check" CHECK (((("recurrence_type")::"text" = ANY ((ARRAY['daily'::character varying, 'weekly'::character varying, 'monthly'::character varying])::"text"[])) OR ("recurrence_type" IS NULL))),
    CONSTRAINT "tasks_status_check" CHECK ((("status")::"text" = ANY ((ARRAY['incomplete'::character varying, 'completed'::character varying])::"text"[])))
);

ALTER TABLE ONLY "public"."tasks" REPLICA IDENTITY FULL;


ALTER TABLE "public"."tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."units" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "symbol" "text",
    "type" "text",
    "is_default" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "units_type_check" CHECK (("type" = ANY (ARRAY['weight'::"text", 'volume'::"text", 'count'::"text", 'length'::"text"])))
);


ALTER TABLE "public"."units" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "phone" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "country" character varying(10),
    "dialect" character varying(50),
    "language" character varying(10),
    CONSTRAINT "users_full_name_not_empty" CHECK (("char_length"("full_name") > 0))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."beta_feedback"
    ADD CONSTRAINT "beta_feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_user_id_token_key" UNIQUE ("user_id", "token");



ALTER TABLE ONLY "public"."expense_splits"
    ADD CONSTRAINT "expense_splits_expense_id_member_id_key" UNIQUE ("expense_id", "member_id");



ALTER TABLE ONLY "public"."expense_splits"
    ADD CONSTRAINT "expense_splits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."home_members"
    ADD CONSTRAINT "home_members_home_id_user_id_key" UNIQUE ("home_id", "user_id");



ALTER TABLE ONLY "public"."home_members"
    ADD CONSTRAINT "home_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."homes"
    ADD CONSTRAINT "homes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invitations"
    ADD CONSTRAINT "invitations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invitations"
    ADD CONSTRAINT "invitations_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."item_templates"
    ADD CONSTRAINT "item_templates_home_id_name_key" UNIQUE ("home_id", "name");



ALTER TABLE ONLY "public"."item_templates"
    ADD CONSTRAINT "item_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rate_limit_log"
    ADD CONSTRAINT "rate_limit_log_pkey" PRIMARY KEY ("user_id", "endpoint", "window_start");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_permission_key" UNIQUE ("role", "permission");



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shopping_mode_sessions"
    ADD CONSTRAINT "shopping_mode_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sync_operations_log"
    ADD CONSTRAINT "sync_operations_log_pkey" PRIMARY KEY ("idempotency_key");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."units"
    ADD CONSTRAINT "units_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "uq_notification_preferences_user_home" UNIQUE ("user_id", "home_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_activity_logs_entity" ON "public"."activity_logs" USING "btree" ("entity_type", "entity_id", "created_at" DESC);



CREATE INDEX "idx_activity_logs_home_created" ON "public"."activity_logs" USING "btree" ("home_id", "created_at" DESC);



CREATE INDEX "idx_categories_delta_sync" ON "public"."categories" USING "btree" ("home_id", "updated_at" DESC);



CREATE INDEX "idx_expense_splits_expense_id" ON "public"."expense_splits" USING "btree" ("expense_id");



CREATE INDEX "idx_expense_splits_member_id" ON "public"."expense_splits" USING "btree" ("member_id");



CREATE INDEX "idx_expenses_date" ON "public"."expenses" USING "btree" ("date");



CREATE INDEX "idx_expenses_delta_sync" ON "public"."expenses" USING "btree" ("home_id", "updated_at" DESC);



CREATE INDEX "idx_expenses_home_id" ON "public"."expenses" USING "btree" ("home_id");



CREATE INDEX "idx_expenses_paid_by" ON "public"."expenses" USING "btree" ("paid_by");



CREATE INDEX "idx_home_members_active_user_home" ON "public"."home_members" USING "btree" ("user_id", "home_id") WHERE (("status" = 'active'::"text") AND ("deleted_at" IS NULL));



CREATE INDEX "idx_inventory_items_category" ON "public"."inventory_items" USING "btree" ("home_id", "category_id");



CREATE INDEX "idx_inventory_items_delta_sync" ON "public"."inventory_items" USING "btree" ("home_id", "updated_at" DESC);



CREATE INDEX "idx_inventory_items_home_id" ON "public"."inventory_items" USING "btree" ("home_id");



CREATE INDEX "idx_inventory_items_name_search" ON "public"."inventory_items" USING "btree" ("home_id", "name");



CREATE INDEX "idx_inventory_transactions_home_id" ON "public"."inventory_transactions" USING "btree" ("home_id");



CREATE INDEX "idx_inventory_transactions_item_id" ON "public"."inventory_transactions" USING "btree" ("inventory_item_id");



CREATE INDEX "idx_invitations_email_status" ON "public"."invitations" USING "btree" ("lower"("email"), "status", "expires_at");



CREATE INDEX "idx_invitations_home_status" ON "public"."invitations" USING "btree" ("home_id", "status", "created_at" DESC);



CREATE INDEX "idx_item_templates_home_id" ON "public"."item_templates" USING "btree" ("home_id");



CREATE INDEX "idx_item_templates_usage" ON "public"."item_templates" USING "btree" ("home_id", "usage_count" DESC);



CREATE INDEX "idx_notification_preferences_home_id" ON "public"."notification_preferences" USING "btree" ("home_id");



CREATE INDEX "idx_notification_preferences_user_home" ON "public"."notification_preferences" USING "btree" ("user_id", "home_id");



CREATE INDEX "idx_notification_preferences_user_id" ON "public"."notification_preferences" USING "btree" ("user_id");



CREATE INDEX "idx_notifications_user_unread_created" ON "public"."notifications" USING "btree" ("user_id", "is_read", "created_at" DESC);



CREATE INDEX "idx_products_home" ON "public"."products" USING "btree" ("home_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_rate_limit_log_lookup" ON "public"."rate_limit_log" USING "btree" ("user_id", "endpoint", "window_start");



CREATE INDEX "idx_settlements_home_id" ON "public"."settlements" USING "btree" ("home_id");



CREATE INDEX "idx_shopping_items_delta_sync" ON "public"."shopping_items" USING "btree" ("list_id", "updated_at" DESC);



CREATE INDEX "idx_shopping_items_home_id" ON "public"."shopping_items" USING "btree" ("home_id");



CREATE INDEX "idx_shopping_lists_delta_sync" ON "public"."shopping_lists" USING "btree" ("home_id", "updated_at" DESC);



CREATE INDEX "idx_shopping_mode_sessions_active" ON "public"."shopping_mode_sessions" USING "btree" ("user_id", "ended_at") WHERE ("ended_at" IS NULL);



CREATE INDEX "idx_shopping_mode_sessions_home" ON "public"."shopping_mode_sessions" USING "btree" ("home_id", "started_at" DESC);



CREATE INDEX "idx_shopping_mode_sessions_list" ON "public"."shopping_mode_sessions" USING "btree" ("shopping_list_id", "started_at" DESC);



CREATE INDEX "idx_shopping_mode_sessions_user" ON "public"."shopping_mode_sessions" USING "btree" ("user_id", "started_at" DESC);



CREATE INDEX "idx_task_comments_created_at" ON "public"."task_comments" USING "btree" ("created_at");



CREATE INDEX "idx_task_comments_task_id" ON "public"."task_comments" USING "btree" ("task_id");



CREATE INDEX "idx_tasks_active" ON "public"."tasks" USING "btree" ("home_id") WHERE (("deleted_at" IS NULL) AND ("archived_at" IS NULL));



CREATE INDEX "idx_tasks_assigned_to" ON "public"."tasks" USING "btree" ("assigned_to");



CREATE INDEX "idx_tasks_category_id" ON "public"."tasks" USING "btree" ("category_id");



CREATE INDEX "idx_tasks_created_by" ON "public"."tasks" USING "btree" ("created_by");



CREATE INDEX "idx_tasks_delta_sync" ON "public"."tasks" USING "btree" ("home_id", "updated_at" DESC);



CREATE INDEX "idx_tasks_due_date" ON "public"."tasks" USING "btree" ("due_date");



CREATE INDEX "idx_tasks_home_id" ON "public"."tasks" USING "btree" ("home_id");



CREATE INDEX "idx_tasks_status" ON "public"."tasks" USING "btree" ("status");



CREATE UNIQUE INDEX "uq_inventory_items_active_home_name_unit" ON "public"."inventory_items" USING "btree" ("home_id", "lower"(("name")::"text"), COALESCE("unit_id", '00000000-0000-0000-0000-000000000000'::"uuid")) WHERE ("deleted_at" IS NULL);



CREATE OR REPLACE TRIGGER "on_home_created" AFTER INSERT ON "public"."homes" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_home"();



CREATE OR REPLACE TRIGGER "set_inventory_items_updated_at" BEFORE UPDATE ON "public"."inventory_items" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "set_notification_preferences_updated_at" BEFORE UPDATE ON "public"."notification_preferences" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "set_shopping_mode_sessions_updated_at" BEFORE UPDATE ON "public"."shopping_mode_sessions" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."item_templates" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "trg_check_expense_member_membership" BEFORE INSERT OR UPDATE ON "public"."expenses" FOR EACH ROW EXECUTE FUNCTION "public"."check_expense_member_membership"();



CREATE OR REPLACE TRIGGER "trg_check_expense_split_membership" BEFORE INSERT OR UPDATE ON "public"."expense_splits" FOR EACH ROW EXECUTE FUNCTION "public"."check_expense_split_membership"();



CREATE OR REPLACE TRIGGER "trg_check_inventory_transaction_same_home" BEFORE INSERT OR UPDATE ON "public"."inventory_transactions" FOR EACH ROW EXECUTE FUNCTION "public"."check_inventory_transaction_same_home"();



CREATE OR REPLACE TRIGGER "trg_check_settlement_membership" BEFORE INSERT OR UPDATE ON "public"."settlements" FOR EACH ROW EXECUTE FUNCTION "public"."check_settlement_membership"();



CREATE OR REPLACE TRIGGER "trg_check_shopping_item_same_home" BEFORE INSERT OR UPDATE ON "public"."shopping_items" FOR EACH ROW EXECUTE FUNCTION "public"."check_shopping_item_same_home"();



CREATE OR REPLACE TRIGGER "trg_check_task_assignee_membership" BEFORE INSERT OR UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."check_task_assignee_membership"();



CREATE OR REPLACE TRIGGER "trg_home_members_activity" AFTER INSERT OR UPDATE ON "public"."home_members" FOR EACH ROW EXECUTE FUNCTION "public"."log_home_member_activity"();



CREATE OR REPLACE TRIGGER "trg_home_members_updated_at" BEFORE UPDATE ON "public"."home_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_home_members_updated_at"();



CREATE OR REPLACE TRIGGER "trg_invitations_activity" AFTER UPDATE ON "public"."invitations" FOR EACH ROW EXECUTE FUNCTION "public"."log_invitation_activity"();



CREATE OR REPLACE TRIGGER "trg_notify_invitee" AFTER INSERT ON "public"."invitations" FOR EACH ROW EXECUTE FUNCTION "public"."notify_invitee_on_invitation"();



CREATE OR REPLACE TRIGGER "trg_notify_inviter_response" AFTER UPDATE ON "public"."invitations" FOR EACH ROW EXECUTE FUNCTION "public"."notify_inviter_on_invitation_response"();



CREATE OR REPLACE TRIGGER "trg_prevent_category_critical_updates" BEFORE UPDATE ON "public"."categories" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_category_critical_updates"();



CREATE OR REPLACE TRIGGER "trg_protect_home_owner" BEFORE UPDATE ON "public"."home_members" FOR EACH ROW EXECUTE FUNCTION "public"."protect_home_owner"();



CREATE OR REPLACE TRIGGER "trg_set_shopping_item_home_id" BEFORE INSERT OR UPDATE OF "list_id" ON "public"."shopping_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_shopping_item_home_id"();



CREATE OR REPLACE TRIGGER "trg_shopping_items_activity" AFTER INSERT OR UPDATE ON "public"."shopping_items" FOR EACH ROW EXECUTE FUNCTION "public"."log_shopping_item_activity"();



CREATE OR REPLACE TRIGGER "trg_shopping_lists_activity" AFTER INSERT OR UPDATE ON "public"."shopping_lists" FOR EACH ROW EXECUTE FUNCTION "public"."log_shopping_list_activity"();



CREATE OR REPLACE TRIGGER "trg_tasks_updated_at" BEFORE UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."update_task_updated_at"();



CREATE OR REPLACE TRIGGER "trg_validate_inventory_category" BEFORE INSERT OR UPDATE ON "public"."inventory_items" FOR EACH ROW EXECUTE FUNCTION "public"."validate_category_assignment"();



CREATE OR REPLACE TRIGGER "trg_validate_tasks_category" BEFORE INSERT OR UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."validate_category_assignment"();



CREATE OR REPLACE TRIGGER "trigger_expenses_updated_at" BEFORE UPDATE ON "public"."expenses" FOR EACH ROW EXECUTE FUNCTION "public"."update_expenses_updated_at"();



CREATE OR REPLACE TRIGGER "validate_template_category" BEFORE INSERT OR UPDATE ON "public"."item_templates" FOR EACH ROW EXECUTE FUNCTION "public"."trg_validate_shopping_item_template"();



ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."beta_feedback"
    ADD CONSTRAINT "beta_feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."expense_splits"
    ADD CONSTRAINT "expense_splits_expense_id_fkey" FOREIGN KEY ("expense_id") REFERENCES "public"."expenses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."expense_splits"
    ADD CONSTRAINT "expense_splits_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_cancelled_by_fkey" FOREIGN KEY ("cancelled_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_paid_by_fkey" FOREIGN KEY ("paid_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_shopping_list_item_id_fkey" FOREIGN KEY ("shopping_list_item_id") REFERENCES "public"."shopping_items"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."home_members"
    ADD CONSTRAINT "home_members_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."home_members"
    ADD CONSTRAINT "home_members_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."home_members"
    ADD CONSTRAINT "home_members_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."home_members"
    ADD CONSTRAINT "home_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."homes"
    ADD CONSTRAINT "homes_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."units"("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_transactions"
    ADD CONSTRAINT "inventory_transactions_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "public"."inventory_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invitations"
    ADD CONSTRAINT "invitations_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invitations"
    ADD CONSTRAINT "invitations_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."item_templates"
    ADD CONSTRAINT "item_templates_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."item_templates"
    ADD CONSTRAINT "item_templates_default_category_id_fkey" FOREIGN KEY ("default_category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."item_templates"
    ADD CONSTRAINT "item_templates_default_unit_id_fkey" FOREIGN KEY ("default_unit_id") REFERENCES "public"."units"("id");



ALTER TABLE ONLY "public"."item_templates"
    ADD CONSTRAINT "item_templates_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_default_category_id_fkey" FOREIGN KEY ("default_category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_default_unit_id_fkey" FOREIGN KEY ("default_unit_id") REFERENCES "public"."units"("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_from_member_fkey" FOREIGN KEY ("from_member") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_to_member_fkey" FOREIGN KEY ("to_member") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_completed_by_fkey" FOREIGN KEY ("completed_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_list_id_fkey" FOREIGN KEY ("list_id") REFERENCES "public"."shopping_lists"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."units"("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shopping_mode_sessions"
    ADD CONSTRAINT "shopping_mode_sessions_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_mode_sessions"
    ADD CONSTRAINT "shopping_mode_sessions_shopping_list_id_fkey" FOREIGN KEY ("shopping_list_id") REFERENCES "public"."shopping_lists"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_mode_sessions"
    ADD CONSTRAINT "shopping_mode_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sync_operations_log"
    ADD CONSTRAINT "sync_operations_log_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_completed_by_fkey" FOREIGN KEY ("completed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Authenticated users can create custom units" ON "public"."units" FOR INSERT TO "authenticated" WITH CHECK (("is_default" = false));



CREATE POLICY "Authenticated users can delete non-default units" ON "public"."units" FOR DELETE TO "authenticated" USING (("is_default" = false));



CREATE POLICY "Authenticated users can insert activity logs" ON "public"."activity_logs" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = "auth"."uid"()) AND ("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL))))));



CREATE POLICY "Authenticated users can update non-default units" ON "public"."units" FOR UPDATE TO "authenticated" USING (("is_default" = false)) WITH CHECK (("is_default" = false));



CREATE POLICY "Authenticated users can view units" ON "public"."units" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Home members can create custom categories" ON "public"."categories" FOR INSERT WITH CHECK (("public"."is_home_member"("home_id") AND ("created_by" = "auth"."uid"()) AND ("is_default" = false)));



CREATE POLICY "Home members can create items (Viewer protected)" ON "public"."shopping_items" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."shopping_lists" "sl"
  WHERE (("sl"."id" = "shopping_items"."list_id") AND "public"."is_not_viewer"("sl"."home_id")))));



CREATE POLICY "Home members can create lists" ON "public"."shopping_lists" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Home members can create products" ON "public"."products" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Home members can create task comments" ON "public"."task_comments" FOR INSERT WITH CHECK ((("task_id" IN ( SELECT "t"."id"
   FROM ("public"."tasks" "t"
     JOIN "public"."home_members" "hm" ON (("hm"."home_id" = "t"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Home members can create tasks (Viewer protected)" ON "public"."tasks" FOR INSERT WITH CHECK ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Home members can delete items (Viewer protected)" ON "public"."shopping_items" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."shopping_lists" "sl"
  WHERE (("sl"."id" = "shopping_items"."list_id") AND "public"."is_not_viewer"("sl"."home_id")))));



CREATE POLICY "Home members can delete tasks (Viewer protected)" ON "public"."tasks" FOR DELETE USING ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Home members can update items (Viewer protected)" ON "public"."shopping_items" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."shopping_lists" "sl"
  WHERE (("sl"."id" = "shopping_items"."list_id") AND "public"."is_not_viewer"("sl"."home_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."shopping_lists" "sl"
  WHERE (("sl"."id" = "shopping_items"."list_id") AND "public"."is_not_viewer"("sl"."home_id")))));



CREATE POLICY "Home members can update lists" ON "public"."shopping_lists" FOR UPDATE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Home members can update tasks (Viewer protected)" ON "public"."tasks" FOR UPDATE USING ("public"."is_not_viewer"("home_id")) WITH CHECK ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Home members can update their home categories" ON "public"."categories" FOR UPDATE USING ("public"."is_home_member"("home_id")) WITH CHECK ("public"."is_home_member"("home_id"));



CREATE POLICY "Home members can view task comments" ON "public"."task_comments" FOR SELECT USING (("task_id" IN ( SELECT "t"."id"
   FROM ("public"."tasks" "t"
     JOIN "public"."home_members" "hm" ON (("hm"."home_id" = "t"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Home members can view tasks" ON "public"."tasks" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Home owners and admins can cancel invitations" ON "public"."invitations" FOR UPDATE TO "authenticated" USING ((("invited_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."home_members"
  WHERE (("home_members"."home_id" = "invitations"."home_id") AND ("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"]))))))) WITH CHECK (("status" = 'cancelled'::"text"));



CREATE POLICY "Invited users can cancel only their pending invitations" ON "public"."invitations" FOR UPDATE TO "authenticated" USING ((("lower"("email") = "lower"(("auth"."jwt"() ->> 'email'::"text"))) AND ("status" = 'pending'::"text") AND ("expires_at" > "now"()))) WITH CHECK ((("lower"("email") = "lower"(("auth"."jwt"() ->> 'email'::"text"))) AND ("status" = 'cancelled'::"text")));



CREATE POLICY "Members can delete expense splits" ON "public"."expense_splits" FOR DELETE TO "authenticated" USING (("expense_id" IN ( SELECT "e"."id"
   FROM ("public"."expenses" "e"
     JOIN "public"."home_members" "hm" ON (("hm"."home_id" = "e"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Members can delete expenses (Viewer protected)" ON "public"."expenses" FOR DELETE USING ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Members can insert expense splits" ON "public"."expense_splits" FOR INSERT TO "authenticated" WITH CHECK (("expense_id" IN ( SELECT "e"."id"
   FROM ("public"."expenses" "e"
     JOIN "public"."home_members" "hm" ON (("hm"."home_id" = "e"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Members can insert expenses (Viewer protected)" ON "public"."expenses" FOR INSERT WITH CHECK ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Members can insert settlements" ON "public"."settlements" FOR INSERT TO "authenticated" WITH CHECK ((("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Members can update expense splits" ON "public"."expense_splits" FOR UPDATE TO "authenticated" USING (("expense_id" IN ( SELECT "e"."id"
   FROM ("public"."expenses" "e"
     JOIN "public"."home_members" "hm" ON (("hm"."home_id" = "e"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Members can update home expenses (Viewer protected)" ON "public"."expenses" FOR UPDATE USING ("public"."is_not_viewer"("home_id")) WITH CHECK ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Members can view expense splits" ON "public"."expense_splits" FOR SELECT TO "authenticated" USING (("expense_id" IN ( SELECT "e"."id"
   FROM ("public"."expenses" "e"
     JOIN "public"."home_members" "hm" ON (("hm"."home_id" = "e"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Members can view home expenses" ON "public"."expenses" FOR SELECT TO "authenticated" USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Members can view home settlements" ON "public"."settlements" FOR SELECT TO "authenticated" USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Owners and admins can cancel invitations" ON "public"."invitations" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM "public"."home_members"
  WHERE (("home_members"."home_id" = "invitations"."home_id") AND ("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))) AND ("status" = 'pending'::"text")));



CREATE POLICY "Owners and admins can create invitations" ON "public"."invitations" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))) AND ("invited_by" = "auth"."uid"())));



CREATE POLICY "Owners and admins can delete invitations" ON "public"."invitations" FOR DELETE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Owners and admins can select invitations" ON "public"."invitations" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."home_members"
  WHERE (("home_members"."home_id" = "invitations"."home_id") AND ("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Owners and admins can update homes" ON "public"."homes" FOR UPDATE USING (("id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Owners and admins can update members" ON "public"."home_members" FOR UPDATE USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Users can add inventory items (Viewer protected)" ON "public"."inventory_items" FOR INSERT WITH CHECK ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Users can add themselves as owner or admins can add members" ON "public"."home_members" FOR INSERT WITH CHECK (((("user_id" = "auth"."uid"()) AND ("role" = 'owner'::"text") AND ("status" = 'active'::"text")) OR ("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL))))));



CREATE POLICY "Users can create homes" ON "public"."homes" FOR INSERT WITH CHECK (("auth"."uid"() = "owner_id"));



CREATE POLICY "Users can create inventory transactions" ON "public"."inventory_transactions" FOR INSERT TO "authenticated" WITH CHECK (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Users can create item templates" ON "public"."item_templates" FOR INSERT TO "authenticated" WITH CHECK ((("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Users can create sessions in their home" ON "public"."shopping_mode_sessions" FOR INSERT TO "authenticated" WITH CHECK ((("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))) AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Users can delete inventory items (Viewer protected)" ON "public"."inventory_items" FOR DELETE USING ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Users can delete item templates" ON "public"."item_templates" FOR DELETE USING ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Users can delete own comments" ON "public"."task_comments" FOR DELETE USING (("created_by" = "auth"."uid"()));



CREATE POLICY "Users can delete own notification preferences" ON "public"."notification_preferences" FOR DELETE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can insert own feedback" ON "public"."beta_feedback" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can insert own notification preferences" ON "public"."notification_preferences" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can insert own profile" ON "public"."users" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can insert their own sync logs" ON "public"."sync_operations_log" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own device tokens" ON "public"."device_tokens" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update inventory items (Viewer protected)" ON "public"."inventory_items" FOR UPDATE USING ("public"."is_not_viewer"("home_id")) WITH CHECK ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Users can update item templates (Viewer protected)" ON "public"."item_templates" FOR UPDATE USING ("public"."is_not_viewer"("home_id")) WITH CHECK ("public"."is_not_viewer"("home_id"));



CREATE POLICY "Users can update own comments" ON "public"."task_comments" FOR UPDATE USING (("created_by" = "auth"."uid"())) WITH CHECK (("created_by" = "auth"."uid"()));



CREATE POLICY "Users can update own notification preferences" ON "public"."notification_preferences" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update own profile" ON "public"."users" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own sessions" ON "public"."shopping_mode_sessions" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update their own notifications" ON "public"."notifications" FOR UPDATE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view activity from their homes" ON "public"."activity_logs" FOR SELECT TO "authenticated" USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view default categories and their home categories" ON "public"."categories" FOR SELECT USING ((("deleted_at" IS NULL) AND (("is_default" = true) OR "public"."is_home_member"("home_id"))));



CREATE POLICY "Users can view homes they are members of" ON "public"."homes" FOR SELECT USING ((("deleted_at" IS NULL) AND (("owner_id" = "auth"."uid"()) OR "public"."is_home_member"("id"))));



CREATE POLICY "Users can view inventory items for their homes" ON "public"."inventory_items" FOR SELECT TO "authenticated" USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view inventory transactions" ON "public"."inventory_transactions" FOR SELECT TO "authenticated" USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view invitations for their homes" ON "public"."invitations" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view item templates" ON "public"."item_templates" FOR SELECT TO "authenticated" USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view items from their home lists" ON "public"."shopping_items" FOR SELECT USING ((("deleted_at" IS NULL) AND ("list_id" IN ( SELECT "sl"."id"
   FROM ("public"."shopping_lists" "sl"
     JOIN "public"."home_members" "hm" ON (("sl"."home_id" = "hm"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL) AND ("sl"."deleted_at" IS NULL))))));



CREATE POLICY "Users can view lists from their homes" ON "public"."shopping_lists" FOR SELECT USING ((("deleted_at" IS NULL) AND ("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL))))));



CREATE POLICY "Users can view members of their homes" ON "public"."home_members" FOR SELECT USING ((("deleted_at" IS NULL) AND "public"."is_home_member"("home_id")));



CREATE POLICY "Users can view own feedback" ON "public"."beta_feedback" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view own notification preferences" ON "public"."notification_preferences" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view own profile" ON "public"."users" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view products from their homes" ON "public"."products" FOR SELECT USING ((("deleted_at" IS NULL) AND ("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL))))));



CREATE POLICY "Users can view profiles of members in their homes" ON "public"."users" FOR SELECT TO "authenticated" USING ((("id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM ("public"."home_members" "viewer"
     JOIN "public"."home_members" "viewed" ON (("viewed"."home_id" = "viewer"."home_id")))
  WHERE (("viewer"."user_id" = "auth"."uid"()) AND ("viewer"."status" = 'active'::"text") AND ("viewer"."deleted_at" IS NULL) AND ("viewed"."user_id" = "users"."id") AND ("viewed"."status" = 'active'::"text") AND ("viewed"."deleted_at" IS NULL))))));



CREATE POLICY "Users can view sessions in their home" ON "public"."shopping_mode_sessions" FOR SELECT TO "authenticated" USING (("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view their own device tokens" ON "public"."device_tokens" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view their own invitations" ON "public"."invitations" FOR SELECT USING (("email" IN ( SELECT "users"."email"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own notifications" ON "public"."notifications" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view their own sync logs" ON "public"."sync_operations_log" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."activity_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."beta_feedback" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."device_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."expense_splits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."expenses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."home_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."homes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."invitations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."item_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rate_limit_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."settlements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_lists" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_mode_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sync_operations_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."units" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "view_role_permissions" ON "public"."role_permissions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."activity_logs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."categories";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."expense_splits";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."expenses";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."home_members";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."homes";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."inventory_items";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."invitations";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."item_templates";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."notifications";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."products";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."shopping_items";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."shopping_lists";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."task_comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."tasks";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."units";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";














































































































































































GRANT ALL ON FUNCTION "public"."accept_invitation"("invitation_token" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."accept_invitation"("invitation_token" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."auto_archive_completed_tasks"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_archive_completed_tasks"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") TO "authenticated";



GRANT ALL ON FUNCTION "public"."check_and_increment_rate_limit"("p_user_id" "uuid", "p_endpoint" "text", "p_window_start" timestamp with time zone, "p_max_requests" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_and_increment_rate_limit"("p_user_id" "uuid", "p_endpoint" "text", "p_window_start" timestamp with time zone, "p_max_requests" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."check_expense_member_membership"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_expense_member_membership"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_expense_split_membership"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_expense_split_membership"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_inventory_transaction_same_home"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_inventory_transaction_same_home"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_settlement_membership"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_settlement_membership"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_shopping_item_same_home"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_shopping_item_same_home"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_task_assignee_membership"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_task_assignee_membership"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_old_rate_limit_log"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_expense_with_splits"("p_home_id" "uuid", "p_amount" integer, "p_description" "text", "p_date" "date", "p_paid_by" "uuid", "p_converted_amount" integer, "p_category_id" "uuid", "p_shopping_list_item_id" "uuid", "p_currency_code" "text", "p_splits" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_expense_with_splits"("p_home_id" "uuid", "p_amount" integer, "p_description" "text", "p_date" "date", "p_paid_by" "uuid", "p_converted_amount" integer, "p_category_id" "uuid", "p_shopping_list_item_id" "uuid", "p_currency_code" "text", "p_splits" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."create_expense_with_splits"("p_home_id" "uuid", "p_amount" integer, "p_description" "text", "p_date" "date", "p_paid_by" "uuid", "p_converted_amount" integer, "p_category_id" "uuid", "p_shopping_list_item_id" "uuid", "p_currency_code" "text", "p_splits" "jsonb") TO "authenticated";



GRANT ALL ON FUNCTION "public"."create_invitation"("p_home_id" "uuid", "p_email" "text", "p_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_invitation"("p_home_id" "uuid", "p_email" "text", "p_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_next_recurring_task"("p_task_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_next_recurring_task"("p_task_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_actor_name"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_actor_name"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_notification_history"("p_limit" integer, "p_offset" integer, "p_home_id" "uuid", "p_category" "text", "p_unread_only" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_notification_history"("p_limit" integer, "p_offset" integer, "p_home_id" "uuid", "p_category" "text", "p_unread_only" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_tables_last_update"("p_home_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_tables_last_update"("p_home_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."handle_new_home"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_home"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_home"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."increment_template_usage"("template_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."increment_template_usage"("template_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_template_usage"("template_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_home_member"("p_home_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_home_member"("p_home_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_not_viewer"("p_home_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_not_viewer"("p_home_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_not_viewer"("p_home_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_not_viewer_for_list"("p_list_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_not_viewer_for_list"("p_list_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_not_viewer_for_list"("p_list_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_home_member_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_home_member_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_invitation_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_invitation_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_shopping_item_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_shopping_item_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_shopping_list_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_shopping_list_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_invitee_on_invitation"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_invitee_on_invitation"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_inviter_on_invitation_response"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_inviter_on_invitation_response"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_category_critical_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_category_critical_updates"() TO "service_role";



GRANT ALL ON FUNCTION "public"."protect_home_owner"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."protect_home_owner"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."record_settlement"("p_home_id" "uuid", "p_from_member" "uuid", "p_to_member" "uuid", "p_amount" numeric, "p_payment_method" "text", "p_date" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."record_settlement"("p_home_id" "uuid", "p_from_member" "uuid", "p_to_member" "uuid", "p_amount" numeric, "p_payment_method" "text", "p_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_settlement"("p_home_id" "uuid", "p_from_member" "uuid", "p_to_member" "uuid", "p_amount" numeric, "p_payment_method" "text", "p_date" "date") TO "service_role";



GRANT ALL ON TABLE "public"."shopping_items" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_items" TO "service_role";



REVOKE ALL ON FUNCTION "public"."restore_shopping_item"("p_item_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."restore_shopping_item"("p_item_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."restore_shopping_item"("p_item_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_home_members_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_home_members_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_shopping_item_home_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_shopping_item_home_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_shopping_item_purchase_state"("p_item_id" "uuid", "p_purchased_quantity" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_shopping_item_purchase_state"("p_item_id" "uuid", "p_purchased_quantity" numeric) TO "service_role";



REVOKE ALL ON FUNCTION "public"."sync_template_on_add"("p_home_id" "uuid", "p_name" "text", "p_quantity" numeric, "p_unit_id" "uuid", "p_category_id" "uuid", "p_user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."sync_template_on_add"("p_home_id" "uuid", "p_name" "text", "p_quantity" numeric, "p_unit_id" "uuid", "p_category_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_template_on_add"("p_home_id" "uuid", "p_name" "text", "p_quantity" numeric, "p_unit_id" "uuid", "p_category_id" "uuid", "p_user_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."transfer_home_ownership"("p_home_id" "uuid", "p_new_owner_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."transfer_home_ownership"("p_home_id" "uuid", "p_new_owner_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."transfer_home_ownership"("p_home_id" "uuid", "p_new_owner_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_validate_item_template"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_validate_item_template"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_validate_shopping_item_template"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_validate_shopping_item_template"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_expenses_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_expenses_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_task_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_task_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_category_assignment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_category_assignment"() TO "service_role";
























GRANT ALL ON TABLE "public"."activity_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."activity_logs" TO "service_role";



GRANT ALL ON TABLE "public"."beta_feedback" TO "anon";
GRANT ALL ON TABLE "public"."beta_feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."beta_feedback" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."device_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."device_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."expense_splits" TO "authenticated";
GRANT ALL ON TABLE "public"."expense_splits" TO "service_role";



GRANT ALL ON TABLE "public"."expenses" TO "authenticated";
GRANT ALL ON TABLE "public"."expenses" TO "service_role";



GRANT ALL ON TABLE "public"."home_members" TO "authenticated";
GRANT ALL ON TABLE "public"."home_members" TO "service_role";



GRANT ALL ON TABLE "public"."homes" TO "authenticated";
GRANT ALL ON TABLE "public"."homes" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_items" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_items" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."invitations" TO "authenticated";
GRANT ALL ON TABLE "public"."invitations" TO "service_role";



GRANT ALL ON TABLE "public"."item_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."item_templates" TO "service_role";



GRANT ALL ON TABLE "public"."notification_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."rate_limit_log" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."settlements" TO "authenticated";
GRANT ALL ON TABLE "public"."settlements" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_lists" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_lists" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_mode_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_mode_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."sync_operations_log" TO "anon";
GRANT ALL ON TABLE "public"."sync_operations_log" TO "authenticated";
GRANT ALL ON TABLE "public"."sync_operations_log" TO "service_role";



GRANT ALL ON TABLE "public"."task_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."task_comments" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."units" TO "authenticated";
GRANT ALL ON TABLE "public"."units" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































