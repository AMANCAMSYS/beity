-- Allow members of the same active home to resolve each other's display names.
-- This keeps profile visibility scoped to shared home membership instead of
-- exposing all users.
DROP POLICY IF EXISTS "Users can view profiles of members in their homes" ON public.users;

CREATE POLICY "Users can view profiles of members in their homes"
ON public.users
FOR SELECT
TO authenticated
USING (
  id = auth.uid()
  OR EXISTS (
    SELECT 1
    FROM public.home_members viewer
    JOIN public.home_members viewed
      ON viewed.home_id = viewer.home_id
    WHERE viewer.user_id = auth.uid()
      AND viewer.status = 'active'
      AND viewer.deleted_at IS NULL
      AND viewed.user_id = public.users.id
      AND viewed.status = 'active'
      AND viewed.deleted_at IS NULL
  )
);
