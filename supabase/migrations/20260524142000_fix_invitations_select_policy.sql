-- Drop the restrictive SELECT policy
DROP POLICY IF EXISTS "Users can view their own pending invitations" ON "public"."invitations";
DROP POLICY IF EXISTS "Users can view their own invitations" ON "public"."invitations";

-- Recreate the SELECT policy to allow users to view any invitations sent to them
CREATE POLICY "Users can view their own invitations" ON "public"."invitations"
  FOR SELECT TO public
  USING (email IN (SELECT email FROM public.users WHERE id = auth.uid()));
