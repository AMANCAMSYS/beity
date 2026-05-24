-- ====================================================================
-- Beity Project: Fix invitations Row-Level Security (RLS) Policies
-- Run this script in the Supabase SQL Editor to fix the RLS issue.
-- ====================================================================

-- 1. Ensure RLS is active on the invitations table
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- 2. Clean up any conflicting or obsolete update policies
DROP POLICY IF EXISTS "Invited users can update their invitations" ON invitations;
DROP POLICY IF EXISTS "Inviter can update invitations" ON invitations;
DROP POLICY IF EXISTS "Home owners and admins can cancel invitations" ON invitations;
DROP POLICY IF EXISTS "Allow update for invite owners" ON invitations;
DROP POLICY IF EXISTS "Allow update status" ON invitations;
DROP POLICY IF EXISTS "invitations_update_policy" ON invitations;

-- 3. Policy: Allow the invited user to ACCEPT or DECLINE the invitation
CREATE POLICY "Invited users can update their invitations" ON invitations
FOR UPDATE
TO authenticated
USING (
  email = auth.jwt() ->> 'email'
)
WITH CHECK (
  status IN ('accepted', 'cancelled')
);

-- 4. Policy: Allow the inviter OR home owners/admins to CANCEL the invitation
CREATE POLICY "Home owners and admins can cancel invitations" ON invitations
FOR UPDATE
TO authenticated
USING (
  invited_by = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM home_members
    WHERE home_members.home_id = invitations.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
  )
)
WITH CHECK (
  status = 'cancelled'
);

-- 5. Verification query to list all active policies on the invitations table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'invitations';
