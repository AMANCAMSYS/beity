-- =============================================================
-- Revoke anon access from all SECURITY DEFINER functions
-- =============================================================

BEGIN;

-- Revoke all existing functions from anon
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef = true
  LOOP
    BEGIN
      EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM anon', r.proname, r.args);
    EXCEPTION WHEN OTHERS THEN
      -- Ignore errors for functions that may not exist
      NULL;
    END;
  END LOOP;
END $$;

-- Revoke default privileges for future functions from anon
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
REVOKE ALL ON FUNCTIONS FROM anon;

-- Ensure anon still has basic schema usage
GRANT USAGE ON SCHEMA public TO anon;

-- Revoke ALL on all tables from anon (they should only use authenticated)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  LOOP
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM anon', r.tablename);
  END LOOP;
END $$;

COMMIT;
