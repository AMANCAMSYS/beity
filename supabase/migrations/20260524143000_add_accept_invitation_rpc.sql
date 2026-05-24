-- Create a secure RPC for accepting invitations transactionally
CREATE OR REPLACE FUNCTION accept_invitation(invitation_token text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with privileges of the function creator (postgres), bypassing RLS
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

    -- Get invitation
    SELECT * INTO v_invitation
    FROM invitations
    WHERE token = invitation_token AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found or not pending';
    END IF;

    -- Check if expired
    IF v_invitation.expires_at < now() THEN
        UPDATE invitations SET status = 'expired' WHERE id = v_invitation.id;
        RAISE EXCEPTION 'Invitation expired';
    END IF;

    -- Ensure the user's email matches the invitation email (security check)
    IF lower(v_invitation.email) != lower(v_user_email) THEN
        RAISE EXCEPTION 'Unauthorized to accept this invitation';
    END IF;

    -- Update invitation status
    UPDATE invitations
    SET status = 'accepted', accepted_at = now()
    WHERE id = v_invitation.id
    RETURNING * INTO v_invitation;

    -- Add user to home_members if not already a member
    INSERT INTO home_members (home_id, user_id, role, status)
    VALUES (v_invitation.home_id, v_user_id, v_invitation.role, 'active')
    ON CONFLICT (home_id, user_id) DO NOTHING;

    -- Log activity
    INSERT INTO activity_logs (home_id, user_id, action, entity_type, entity_id)
    VALUES (v_invitation.home_id, v_user_id, 'invitation_accepted', 'invitation', v_invitation.id);

    -- Return the updated invitation as JSON
    RETURN row_to_json(v_invitation);
END;
$$;
