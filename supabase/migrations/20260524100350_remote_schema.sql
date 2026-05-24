


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






CREATE OR REPLACE FUNCTION "public"."auto_archive_completed_tasks"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
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
    AS $$
BEGIN
  RETURN QUERY
  WITH expense_debts AS (
    SELECT 
      es.member_id as debtor,
      e.paid_by as creditor,
      SUM(es.amount)::integer as total_owed
    FROM expense_splits es
    JOIN expenses e ON e.id = es.expense_id
    WHERE e.home_id = p_home_id 
      AND e.status = 'active'
      AND e.deleted_at IS NULL
    GROUP BY es.member_id, e.paid_by
  ),
  settlement_credits AS (
    SELECT 
      s.from_member as debtor,
      s.to_member as creditor,
      SUM(s.amount)::integer as total_settled
    FROM settlements s
    WHERE s.home_id = p_home_id
    GROUP BY s.from_member, s.to_member
  ),
  all_pairs AS (
    SELECT debtor, creditor FROM expense_debts
    UNION
    SELECT debtor, creditor FROM settlement_credits
  ),
  net_balances AS (
    SELECT 
      ap.debtor,
      ap.creditor,
      (COALESCE(ed.total_owed, 0) - COALESCE(sc.total_settled, 0))::integer as net_amount
    FROM all_pairs ap
    LEFT JOIN expense_debts ed ON ed.debtor = ap.debtor AND ed.creditor = ap.creditor
    LEFT JOIN settlement_credits sc ON sc.debtor = ap.debtor AND sc.creditor = ap.creditor
  )
  SELECT 
    nb.debtor as member_a,
    nb.creditor as member_b,
    nb.net_amount
  FROM net_balances nb
  WHERE nb.net_amount != 0;
END;
$$;


ALTER FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_actor_name"("p_user_id" "uuid") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT full_name FROM users WHERE id = p_user_id;
$$;


ALTER FUNCTION "public"."get_actor_name"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_notification_history"("p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0, "p_home_id" "uuid" DEFAULT NULL::"uuid", "p_category" "text" DEFAULT NULL::"text", "p_unread_only" boolean DEFAULT false) RETURNS SETOF "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
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
    AS $$
DECLARE has_balance boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM calculate_home_balances(p_home_id)
    WHERE member_a = p_user_id OR member_b = p_user_id
  ) INTO has_balance;
  RETURN has_balance;
END;
$$;


ALTER FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."log_home_member_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_action text;
  v_entity_name text;
  v_metadata jsonb;
  v_home_id uuid;
  v_user_id uuid;
  v_actor_name text;
  v_member_name text;
BEGIN
  v_home_id := NEW.home_id;
  v_user_id := auth.uid();
  v_actor_name := get_actor_name(v_user_id);
  v_member_name := get_actor_name(NEW.user_id);

  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'active' THEN
      v_action := 'member_joined';
      v_entity_name := v_member_name;
      v_metadata := NULL;
    ELSE
      RETURN NEW;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      v_action := 'member_removed';
      v_entity_name := v_member_name;
      v_metadata := jsonb_build_object('member_name', v_member_name);
    ELSIF OLD.role IS DISTINCT FROM NEW.role THEN
      v_action := 'member_role_changed';
      v_entity_name := v_member_name;
      v_metadata := jsonb_build_object('old_role', OLD.role, 'new_role', NEW.role, 'member_name', v_member_name);
    ELSE
      RETURN NEW;
    END IF;
  END IF;

  INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
  VALUES (v_home_id, v_user_id, v_actor_name, v_action, 'home_member', NEW.id, v_entity_name, v_metadata);

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_home_member_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_invitation_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_actor_name text;
  v_entity_name text;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'accepted' THEN
    v_actor_name := get_actor_name(NEW.invited_by);
    v_entity_name := COALESCE(NEW.email, NEW.phone);

    INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
    VALUES (NEW.home_id, NEW.invited_by, v_actor_name, 'invitation_accepted', 'invitation', NEW.id, v_entity_name, NULL);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_invitation_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_shopping_item_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_action text;
  v_entity_name text;
  v_metadata jsonb;
  v_home_id uuid;
  v_user_id uuid;
  v_actor_name text;
  v_list_id uuid;
  v_list_name text;
  v_old_values jsonb;
  v_new_values jsonb;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_list_id := NEW.list_id;
    SELECT sl.home_id, sl.title INTO v_home_id, v_list_name FROM shopping_lists sl WHERE sl.id = NEW.list_id;
    v_user_id := NEW.created_by;
  ELSE
    v_list_id := NEW.list_id;
    SELECT sl.home_id, sl.title INTO v_home_id, v_list_name FROM shopping_lists sl WHERE sl.id = NEW.list_id;
    v_user_id := COALESCE(NEW.updated_by, NEW.created_by);
  END IF;

  v_actor_name := get_actor_name(v_user_id);

  IF TG_OP = 'INSERT' THEN
    v_action := 'item_added';
    v_entity_name := NEW.name;
    v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      v_action := 'item_deleted';
      v_entity_name := NEW.name;
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
    ELSIF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed' THEN
      v_action := 'item_purchased';
      v_entity_name := NEW.name;
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
    ELSIF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'pending' AND OLD.status = 'completed' THEN
      v_action := 'item_unpurchased';
      v_entity_name := NEW.name;
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
    ELSIF OLD.name IS DISTINCT FROM NEW.name
       OR OLD.quantity IS DISTINCT FROM NEW.quantity
       OR OLD.unit_id IS DISTINCT FROM NEW.unit_id
       OR OLD.category_id IS DISTINCT FROM NEW.category_id
       OR OLD.note IS DISTINCT FROM NEW.note THEN
      v_action := 'item_updated';
      v_entity_name := NEW.name;
      v_old_values := jsonb_build_object(
        'name', OLD.name,
        'quantity', OLD.quantity,
        'unit_id', OLD.unit_id,
        'category_id', OLD.category_id,
        'note', OLD.note
      );
      v_new_values := jsonb_build_object(
        'name', NEW.name,
        'quantity', NEW.quantity,
        'unit_id', NEW.unit_id,
        'category_id', NEW.category_id,
        'note', NEW.note
      );
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name, 'old_values', v_old_values, 'new_values', v_new_values);
    ELSE
      RETURN NEW;
    END IF;
  END IF;

  INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
  VALUES (v_home_id, v_user_id, v_actor_name, v_action, 'shopping_item', NEW.id, v_entity_name, v_metadata);

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_shopping_item_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_shopping_list_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_action text;
  v_entity_name text;
  v_metadata jsonb;
  v_home_id uuid;
  v_user_id uuid;
  v_actor_name text;
BEGIN
  v_home_id := NEW.home_id;
  v_user_id := COALESCE(NEW.updated_by, NEW.created_by);
  v_actor_name := get_actor_name(v_user_id);

  IF TG_OP = 'INSERT' THEN
    v_action := 'list_created';
    v_entity_name := NEW.title;
    v_metadata := NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.title IS DISTINCT FROM NEW.title THEN
      v_action := 'list_renamed';
      v_entity_name := NEW.title;
      v_metadata := jsonb_build_object('old_name', OLD.title, 'new_name', NEW.title);
    ELSIF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'archived' THEN
      v_action := 'list_archived';
      v_entity_name := NEW.title;
      v_metadata := NULL;
    ELSIF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      v_action := 'list_deleted';
      v_entity_name := NEW.title;
      v_metadata := NULL;
    ELSE
      RETURN NEW;
    END IF;
  END IF;

  INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
  VALUES (v_home_id, v_user_id, v_actor_name, v_action, 'shopping_list', NEW.id, v_entity_name, v_metadata);

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_shopping_list_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_invitee_on_invitation"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_home_name TEXT;
  v_inviter_name TEXT;
  v_invitee_user_id UUID;
BEGIN
  -- Get home name
  SELECT name INTO v_home_name FROM homes WHERE id = NEW.home_id;
  
  -- Get inviter name
  SELECT COALESCE(raw_user_meta_data->>'full_name', email) 
  INTO v_inviter_name 
  FROM auth.users WHERE id = NEW.invited_by;
  
  -- Find invitee user_id by email
  SELECT id INTO v_invitee_user_id 
  FROM users 
  WHERE email = NEW.email;
  
  -- If invitee exists in our system, create a notification for them
  IF v_invitee_user_id IS NOT NULL THEN
    INSERT INTO notifications (
      user_id, 
      home_id, 
      title, 
      body, 
      type, 
      entity_type, 
      entity_id,
      category
    ) VALUES (
      v_invitee_user_id,
      NEW.home_id,
      'دعوة جديدة للانضمام',
      format('دعاك %s للانضمام إلى %s بدور %s', 
        v_inviter_name, 
        v_home_name,
        CASE NEW.role 
          WHEN 'admin' THEN 'مدير'
          WHEN 'member' THEN 'عضو'
          WHEN 'viewer' THEN 'مشاهد'
          ELSE NEW.role
        END
      ),
      'invitation_received',
      'invitation',
      NEW.id,
      'invitation'
    );
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_invitee_on_invitation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_inviter_on_invitation_response"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_invitee_name TEXT;
  v_home_name TEXT;
BEGIN
  -- Only fire on status change
  IF OLD.status = NEW.status THEN RETURN NEW; END IF;
  
  -- Get invitee name
  SELECT COALESCE(raw_user_meta_data->>'full_name', email) 
  INTO v_invitee_name 
  FROM auth.users 
  WHERE id = (SELECT id FROM users WHERE email = NEW.email);
  
  -- Get home name
  SELECT name INTO v_home_name FROM homes WHERE id = NEW.home_id;
  
  -- Notify the inviter
  INSERT INTO notifications (
    user_id, 
    home_id, 
    title, 
    body, 
    type, 
    entity_type, 
    entity_id,
    category
  ) VALUES (
    NEW.invited_by,
    NEW.home_id,
    CASE 
      WHEN NEW.status = 'accepted' THEN 'قبول الدعوة'
      WHEN NEW.status = 'declined' THEN 'رفض الدعوة'
      ELSE 'تحديث الدعوة'
    END,
    CASE 
      WHEN NEW.status = 'accepted' THEN format('قبل %s دعوة الانضمام إلى %s', v_invitee_name, v_home_name)
      WHEN NEW.status = 'declined' THEN format('رفض %s دعوة الانضمام إلى %s', v_invitee_name, v_home_name)
      ELSE format('تم تحديث دعوة %s', v_invitee_name)
    END,
    'invitation_' || NEW.status,
    'invitation',
    NEW.id,
    'invitation'
  );
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_inviter_on_invitation_response"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_expenses_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;


ALTER FUNCTION "public"."update_expenses_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_task_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_task_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


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


ALTER TABLE "public"."device_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."expense_splits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "expense_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "amount" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "expense_splits_amount_check" CHECK (("amount" >= 0))
);


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
    CONSTRAINT "expenses_amount_check" CHECK (("amount" > 0)),
    CONSTRAINT "expenses_converted_amount_check" CHECK (("converted_amount" > 0)),
    CONSTRAINT "expenses_status_check" CHECK ((("status")::"text" = ANY ((ARRAY['active'::character varying, 'cancelled'::character varying])::"text"[])))
);


ALTER TABLE "public"."expenses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."home_members" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "home_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text",
    "joined_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    CONSTRAINT "home_members_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text", 'viewer'::"text"]))),
    CONSTRAINT "home_members_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'pending'::"text"])))
);


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


ALTER TABLE "public"."settlements" OWNER TO "postgres";


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
    CONSTRAINT "shopping_items_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'medium'::"text", 'high'::"text", 'urgent'::"text"]))),
    CONSTRAINT "shopping_items_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'cancelled'::"text"])))
);

ALTER TABLE ONLY "public"."shopping_items" REPLICA IDENTITY FULL;


ALTER TABLE "public"."shopping_items" OWNER TO "postgres";


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


ALTER TABLE "public"."shopping_mode_sessions" OWNER TO "postgres";


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
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_pkey" PRIMARY KEY ("id");



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



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."units"
    ADD CONSTRAINT "units_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "uq_inventory_items_home_name_unit" UNIQUE ("home_id", "name", "unit_id", "deleted_at");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "uq_notification_preferences_user_home" UNIQUE ("user_id", "home_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_activity_logs_entity" ON "public"."activity_logs" USING "btree" ("entity_type", "entity_id", "created_at" DESC);



CREATE INDEX "idx_activity_logs_home_created" ON "public"."activity_logs" USING "btree" ("home_id", "created_at" DESC);



CREATE INDEX "idx_expense_splits_expense_id" ON "public"."expense_splits" USING "btree" ("expense_id");



CREATE INDEX "idx_expense_splits_member_id" ON "public"."expense_splits" USING "btree" ("member_id");



CREATE INDEX "idx_expenses_date" ON "public"."expenses" USING "btree" ("date");



CREATE INDEX "idx_expenses_home_id" ON "public"."expenses" USING "btree" ("home_id");



CREATE INDEX "idx_expenses_paid_by" ON "public"."expenses" USING "btree" ("paid_by");



CREATE INDEX "idx_inventory_items_category" ON "public"."inventory_items" USING "btree" ("home_id", "category_id");



CREATE INDEX "idx_inventory_items_home_id" ON "public"."inventory_items" USING "btree" ("home_id");



CREATE INDEX "idx_inventory_items_name_search" ON "public"."inventory_items" USING "btree" ("home_id", "name");



CREATE INDEX "idx_inventory_transactions_home_id" ON "public"."inventory_transactions" USING "btree" ("home_id");



CREATE INDEX "idx_inventory_transactions_item_id" ON "public"."inventory_transactions" USING "btree" ("inventory_item_id");



CREATE INDEX "idx_item_templates_home_id" ON "public"."item_templates" USING "btree" ("home_id");



CREATE INDEX "idx_item_templates_usage" ON "public"."item_templates" USING "btree" ("home_id", "usage_count" DESC);



CREATE INDEX "idx_notification_preferences_home_id" ON "public"."notification_preferences" USING "btree" ("home_id");



CREATE INDEX "idx_notification_preferences_user_home" ON "public"."notification_preferences" USING "btree" ("user_id", "home_id");



CREATE INDEX "idx_notification_preferences_user_id" ON "public"."notification_preferences" USING "btree" ("user_id");



CREATE INDEX "idx_settlements_home_id" ON "public"."settlements" USING "btree" ("home_id");



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



CREATE INDEX "idx_tasks_due_date" ON "public"."tasks" USING "btree" ("due_date");



CREATE INDEX "idx_tasks_home_id" ON "public"."tasks" USING "btree" ("home_id");



CREATE INDEX "idx_tasks_status" ON "public"."tasks" USING "btree" ("status");



CREATE OR REPLACE TRIGGER "on_home_created" AFTER INSERT ON "public"."homes" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_home"();



CREATE OR REPLACE TRIGGER "set_inventory_items_updated_at" BEFORE UPDATE ON "public"."inventory_items" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "set_notification_preferences_updated_at" BEFORE UPDATE ON "public"."notification_preferences" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "set_shopping_mode_sessions_updated_at" BEFORE UPDATE ON "public"."shopping_mode_sessions" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."item_templates" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "trg_home_members_activity" AFTER INSERT OR UPDATE ON "public"."home_members" FOR EACH ROW EXECUTE FUNCTION "public"."log_home_member_activity"();



CREATE OR REPLACE TRIGGER "trg_invitations_activity" AFTER UPDATE ON "public"."invitations" FOR EACH ROW EXECUTE FUNCTION "public"."log_invitation_activity"();



CREATE OR REPLACE TRIGGER "trg_notify_invitee" AFTER INSERT ON "public"."invitations" FOR EACH ROW EXECUTE FUNCTION "public"."notify_invitee_on_invitation"();



CREATE OR REPLACE TRIGGER "trg_notify_inviter_response" AFTER UPDATE ON "public"."invitations" FOR EACH ROW EXECUTE FUNCTION "public"."notify_inviter_on_invitation_response"();



CREATE OR REPLACE TRIGGER "trg_shopping_items_activity" AFTER INSERT OR UPDATE ON "public"."shopping_items" FOR EACH ROW EXECUTE FUNCTION "public"."log_shopping_item_activity"();



CREATE OR REPLACE TRIGGER "trg_shopping_lists_activity" AFTER INSERT OR UPDATE ON "public"."shopping_lists" FOR EACH ROW EXECUTE FUNCTION "public"."log_shopping_list_activity"();



CREATE OR REPLACE TRIGGER "trg_tasks_updated_at" BEFORE UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."update_task_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_expenses_updated_at" BEFORE UPDATE ON "public"."expenses" FOR EACH ROW EXECUTE FUNCTION "public"."update_expenses_updated_at"();



ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



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
    ADD CONSTRAINT "expenses_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_paid_by_fkey" FOREIGN KEY ("paid_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_shopping_list_item_id_fkey" FOREIGN KEY ("shopping_list_item_id") REFERENCES "public"."shopping_items"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."home_members"
    ADD CONSTRAINT "home_members_home_id_fkey" FOREIGN KEY ("home_id") REFERENCES "public"."homes"("id") ON DELETE CASCADE;



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



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Authenticated users can insert activity logs" ON "public"."activity_logs" FOR INSERT TO "authenticated" WITH CHECK ((("auth"."uid"() = "user_id") AND ("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL))))));



CREATE POLICY "Authenticated users can view units" ON "public"."units" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Creator, assignee, or admin can update tasks" ON "public"."tasks" FOR UPDATE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL))))) WITH CHECK (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Home members can create custom categories" ON "public"."categories" FOR INSERT WITH CHECK (("public"."is_home_member"("home_id") AND ("created_by" = "auth"."uid"()) AND ("is_default" = false)));



CREATE POLICY "Home members can create items" ON "public"."shopping_items" FOR INSERT WITH CHECK ((("list_id" IN ( SELECT "sl"."id"
   FROM ("public"."shopping_lists" "sl"
     JOIN "public"."home_members" "hm" ON (("sl"."home_id" = "hm"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL) AND ("sl"."deleted_at" IS NULL)))) AND ("created_by" = "auth"."uid"())));



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



CREATE POLICY "Home members can create tasks" ON "public"."tasks" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Home members can delete tasks" ON "public"."tasks" FOR DELETE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Home members can update items" ON "public"."shopping_items" FOR UPDATE USING (("list_id" IN ( SELECT "sl"."id"
   FROM ("public"."shopping_lists" "sl"
     JOIN "public"."home_members" "hm" ON (("sl"."home_id" = "hm"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL) AND ("sl"."deleted_at" IS NULL)))));



CREATE POLICY "Home members can update lists" ON "public"."shopping_lists" FOR UPDATE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Home members can update their home categories" ON "public"."categories" FOR UPDATE USING ("public"."is_home_member"("home_id"));



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



CREATE POLICY "Invited users can update their invitations" ON "public"."invitations" FOR UPDATE TO "authenticated" USING (("email" = ("auth"."jwt"() ->> 'email'::"text"))) WITH CHECK (("status" = ANY (ARRAY['accepted'::"text", 'cancelled'::"text"])));



CREATE POLICY "Members can delete expense splits" ON "public"."expense_splits" FOR DELETE USING (("expense_id" IN ( SELECT "expenses"."id"
   FROM "public"."expenses"
  WHERE ("expenses"."home_id" IN ( SELECT "home_members"."home_id"
           FROM "public"."home_members"
          WHERE ("home_members"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Members can insert expense splits" ON "public"."expense_splits" FOR INSERT WITH CHECK (("expense_id" IN ( SELECT "expenses"."id"
   FROM "public"."expenses"
  WHERE ("expenses"."home_id" IN ( SELECT "home_members"."home_id"
           FROM "public"."home_members"
          WHERE ("home_members"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Members can insert expenses" ON "public"."expenses" FOR INSERT WITH CHECK (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Members can insert settlements" ON "public"."settlements" FOR INSERT WITH CHECK (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Members can update expense splits" ON "public"."expense_splits" FOR UPDATE USING (("expense_id" IN ( SELECT "expenses"."id"
   FROM "public"."expenses"
  WHERE ("expenses"."home_id" IN ( SELECT "home_members"."home_id"
           FROM "public"."home_members"
          WHERE ("home_members"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Members can update home expenses" ON "public"."expenses" FOR UPDATE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Members can view expense splits" ON "public"."expense_splits" FOR SELECT USING (("expense_id" IN ( SELECT "expenses"."id"
   FROM "public"."expenses"
  WHERE ("expenses"."home_id" IN ( SELECT "home_members"."home_id"
           FROM "public"."home_members"
          WHERE ("home_members"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Members can view home expenses" ON "public"."expenses" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Members can view home settlements" ON "public"."settlements" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



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



CREATE POLICY "Users can add inventory items" ON "public"."inventory_items" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")))) AND ("created_by" = ( SELECT "auth"."uid"() AS "uid")) AND ("updated_by" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "Users can add themselves as owner or admins can add members" ON "public"."home_members" FOR INSERT WITH CHECK (((("user_id" = "auth"."uid"()) AND ("role" = 'owner'::"text") AND ("status" = 'active'::"text")) OR ("home_id" IN ( SELECT "hm"."home_id"
   FROM "public"."home_members" "hm"
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL))))));



CREATE POLICY "Users can create homes" ON "public"."homes" FOR INSERT WITH CHECK (("auth"."uid"() = "owner_id"));



CREATE POLICY "Users can create inventory transactions" ON "public"."inventory_transactions" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")))) AND ("changed_by" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "Users can create item templates" ON "public"."item_templates" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Users can create sessions in their home" ON "public"."shopping_mode_sessions" FOR INSERT WITH CHECK ((("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))) AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Users can delete inventory items" ON "public"."inventory_items" FOR DELETE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")))));



CREATE POLICY "Users can delete item templates" ON "public"."item_templates" FOR DELETE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete own comments" ON "public"."task_comments" FOR DELETE USING (("created_by" = "auth"."uid"()));



CREATE POLICY "Users can delete own notification preferences" ON "public"."notification_preferences" FOR DELETE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can insert own notification preferences" ON "public"."notification_preferences" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can insert own profile" ON "public"."users" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can manage their own device tokens" ON "public"."device_tokens" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update inventory items" ON "public"."inventory_items" FOR UPDATE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) WITH CHECK (("updated_by" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update item templates" ON "public"."item_templates" FOR UPDATE USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update own comments" ON "public"."task_comments" FOR UPDATE USING (("created_by" = "auth"."uid"())) WITH CHECK (("created_by" = "auth"."uid"()));



CREATE POLICY "Users can update own notification preferences" ON "public"."notification_preferences" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update own profile" ON "public"."users" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own sessions" ON "public"."shopping_mode_sessions" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update their own notifications" ON "public"."notifications" FOR UPDATE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update their own pending invitations" ON "public"."invitations" FOR UPDATE USING ((("email" IN ( SELECT "users"."email"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))) AND ("status" = 'pending'::"text"))) WITH CHECK (("email" IN ( SELECT "users"."email"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view activity from their homes" ON "public"."activity_logs" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view default categories and their home categories" ON "public"."categories" FOR SELECT USING ((("deleted_at" IS NULL) AND (("is_default" = true) OR "public"."is_home_member"("home_id"))));



CREATE POLICY "Users can view homes they are members of" ON "public"."homes" FOR SELECT USING ((("deleted_at" IS NULL) AND (("owner_id" = "auth"."uid"()) OR "public"."is_home_member"("id"))));



CREATE POLICY "Users can view inventory items for their homes" ON "public"."inventory_items" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")))));



CREATE POLICY "Users can view inventory transactions" ON "public"."inventory_transactions" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")))));



CREATE POLICY "Users can view invitations for their homes" ON "public"."invitations" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL)))));



CREATE POLICY "Users can view item templates" ON "public"."item_templates" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view items from their home lists" ON "public"."shopping_items" FOR SELECT USING ((("deleted_at" IS NULL) AND ("list_id" IN ( SELECT "sl"."id"
   FROM ("public"."shopping_lists" "sl"
     JOIN "public"."home_members" "hm" ON (("sl"."home_id" = "hm"."home_id")))
  WHERE (("hm"."user_id" = "auth"."uid"()) AND ("hm"."status" = 'active'::"text") AND ("hm"."deleted_at" IS NULL) AND ("sl"."deleted_at" IS NULL))))));



CREATE POLICY "Users can view lists from their homes" ON "public"."shopping_lists" FOR SELECT USING ((("deleted_at" IS NULL) AND ("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL))))));



CREATE POLICY "Users can view members of their homes" ON "public"."home_members" FOR SELECT USING ((("deleted_at" IS NULL) AND "public"."is_home_member"("home_id")));



CREATE POLICY "Users can view own notification preferences" ON "public"."notification_preferences" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view own profile" ON "public"."users" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view products from their homes" ON "public"."products" FOR SELECT USING ((("deleted_at" IS NULL) AND ("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE (("home_members"."user_id" = "auth"."uid"()) AND ("home_members"."status" = 'active'::"text") AND ("home_members"."deleted_at" IS NULL))))));



CREATE POLICY "Users can view sessions in their home" ON "public"."shopping_mode_sessions" FOR SELECT USING (("home_id" IN ( SELECT "home_members"."home_id"
   FROM "public"."home_members"
  WHERE ("home_members"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own device tokens" ON "public"."device_tokens" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view their own notifications" ON "public"."notifications" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view their own pending invitations" ON "public"."invitations" FOR SELECT USING ((("email" IN ( SELECT "users"."email"
   FROM "public"."users"
  WHERE ("users"."id" = "auth"."uid"()))) AND ("status" = 'pending'::"text")));



ALTER TABLE "public"."activity_logs" ENABLE ROW LEVEL SECURITY;


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


ALTER TABLE "public"."role_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."settlements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_lists" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_mode_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."units" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "view_role_permissions" ON "public"."role_permissions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."activity_logs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."categories";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."home_members";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."homes";



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














































































































































































GRANT ALL ON FUNCTION "public"."auto_archive_completed_tasks"() TO "anon";
GRANT ALL ON FUNCTION "public"."auto_archive_completed_tasks"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_archive_completed_tasks"() TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_home_balances"("p_home_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_actor_name"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_actor_name"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_actor_name"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_notification_history"("p_limit" integer, "p_offset" integer, "p_home_id" "uuid", "p_category" "text", "p_unread_only" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."get_notification_history"("p_limit" integer, "p_offset" integer, "p_home_id" "uuid", "p_category" "text", "p_unread_only" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_notification_history"("p_limit" integer, "p_offset" integer, "p_home_id" "uuid", "p_category" "text", "p_unread_only" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."handle_new_home"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_home"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_home"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_unsettled_balances"("p_home_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_home_member"("p_home_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_home_member"("p_home_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_home_member"("p_home_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_home_member_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_home_member_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_home_member_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_invitation_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_invitation_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_invitation_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_shopping_item_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_shopping_item_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_shopping_item_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_shopping_list_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_shopping_list_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_shopping_list_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_invitee_on_invitation"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_invitee_on_invitation"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_invitee_on_invitation"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_inviter_on_invitation_response"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_inviter_on_invitation_response"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_inviter_on_invitation_response"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_expenses_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_expenses_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_expenses_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_task_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_task_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_task_updated_at"() TO "service_role";
























GRANT ALL ON TABLE "public"."activity_logs" TO "anon";
GRANT ALL ON TABLE "public"."activity_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."activity_logs" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."device_tokens" TO "anon";
GRANT ALL ON TABLE "public"."device_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."device_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."expense_splits" TO "anon";
GRANT ALL ON TABLE "public"."expense_splits" TO "authenticated";
GRANT ALL ON TABLE "public"."expense_splits" TO "service_role";



GRANT ALL ON TABLE "public"."expenses" TO "anon";
GRANT ALL ON TABLE "public"."expenses" TO "authenticated";
GRANT ALL ON TABLE "public"."expenses" TO "service_role";



GRANT ALL ON TABLE "public"."home_members" TO "anon";
GRANT ALL ON TABLE "public"."home_members" TO "authenticated";
GRANT ALL ON TABLE "public"."home_members" TO "service_role";



GRANT ALL ON TABLE "public"."homes" TO "anon";
GRANT ALL ON TABLE "public"."homes" TO "authenticated";
GRANT ALL ON TABLE "public"."homes" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_items" TO "anon";
GRANT ALL ON TABLE "public"."inventory_items" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_items" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_transactions" TO "anon";
GRANT ALL ON TABLE "public"."inventory_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."invitations" TO "anon";
GRANT ALL ON TABLE "public"."invitations" TO "authenticated";
GRANT ALL ON TABLE "public"."invitations" TO "service_role";



GRANT ALL ON TABLE "public"."item_templates" TO "anon";
GRANT ALL ON TABLE "public"."item_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."item_templates" TO "service_role";



GRANT ALL ON TABLE "public"."notification_preferences" TO "anon";
GRANT ALL ON TABLE "public"."notification_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."settlements" TO "anon";
GRANT ALL ON TABLE "public"."settlements" TO "authenticated";
GRANT ALL ON TABLE "public"."settlements" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_items" TO "anon";
GRANT ALL ON TABLE "public"."shopping_items" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_items" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_lists" TO "anon";
GRANT ALL ON TABLE "public"."shopping_lists" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_lists" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_mode_sessions" TO "anon";
GRANT ALL ON TABLE "public"."shopping_mode_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_mode_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."task_comments" TO "anon";
GRANT ALL ON TABLE "public"."task_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."task_comments" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "anon";
GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."units" TO "anon";
GRANT ALL ON TABLE "public"."units" TO "authenticated";
GRANT ALL ON TABLE "public"."units" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































drop extension if exists "pg_net";

alter table "public"."expenses" drop constraint "expenses_status_check";

alter table "public"."inventory_transactions" drop constraint "inventory_transactions_change_reason_check";

alter table "public"."settlements" drop constraint "settlements_payment_method_check";

alter table "public"."tasks" drop constraint "tasks_recurrence_type_check";

alter table "public"."tasks" drop constraint "tasks_status_check";

alter table "public"."expenses" add constraint "expenses_status_check" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'cancelled'::character varying])::text[]))) not valid;

alter table "public"."expenses" validate constraint "expenses_status_check";

alter table "public"."inventory_transactions" add constraint "inventory_transactions_change_reason_check" CHECK (((change_reason)::text = ANY ((ARRAY['manual_update'::character varying, 'shopping_restock'::character varying, 'zero_removal'::character varying, 'initial_add'::character varying, 'delete'::character varying])::text[]))) not valid;

alter table "public"."inventory_transactions" validate constraint "inventory_transactions_change_reason_check";

alter table "public"."settlements" add constraint "settlements_payment_method_check" CHECK (((payment_method)::text = ANY ((ARRAY['cash'::character varying, 'transfer'::character varying, 'other'::character varying])::text[]))) not valid;

alter table "public"."settlements" validate constraint "settlements_payment_method_check";

alter table "public"."tasks" add constraint "tasks_recurrence_type_check" CHECK ((((recurrence_type)::text = ANY ((ARRAY['daily'::character varying, 'weekly'::character varying, 'monthly'::character varying])::text[])) OR (recurrence_type IS NULL))) not valid;

alter table "public"."tasks" validate constraint "tasks_recurrence_type_check";

alter table "public"."tasks" add constraint "tasks_status_check" CHECK (((status)::text = ANY ((ARRAY['incomplete'::character varying, 'completed'::character varying])::text[]))) not valid;

alter table "public"."tasks" validate constraint "tasks_status_check";

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


