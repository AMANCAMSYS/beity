-- Fix invitation response notification triggers
CREATE OR REPLACE FUNCTION "public"."notify_inviter_on_invitation_response"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_invitee_name TEXT;
  v_home_name TEXT;
  v_current_user_id UUID;
BEGIN
  -- Only fire on status change
  IF OLD.status = NEW.status THEN RETURN NEW; END IF;
  
  -- Get the current user ID executing the update
  v_current_user_id := auth.uid();
  
  -- 1. Always delete the pending notification for the invitee on any status change
  DELETE FROM public.notifications 
  WHERE entity_type = 'invitation' 
    AND entity_id = NEW.id;

  -- Get invitee name
  SELECT COALESCE(raw_user_meta_data->>'full_name', email) 
  INTO v_invitee_name 
  FROM auth.users 
  WHERE id = (SELECT id FROM public.users WHERE email = NEW.email);
  
  IF v_invitee_name IS NULL THEN
    v_invitee_name := NEW.email;
  END IF;
  
  -- Get home name
  SELECT name INTO v_home_name FROM public.homes WHERE id = NEW.home_id;

  -- 2. Handle different status changes
  IF NEW.status = 'cancelled' THEN
    -- Distinguish between Cancellation (by inviter) and Decline (by invitee)
    IF v_current_user_id = NEW.invited_by THEN
      -- Invitation cancelled by the inviter themselves. Do not notify the inviter.
      RETURN NEW;
    ELSE
      -- Invitation declined by the invitee. Notify the inviter.
      INSERT INTO public.notifications (
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
        'رفض الدعوة',
        format('رفض %s دعوة الانضمام إلى %s', v_invitee_name, v_home_name),
        'invitation_declined',
        'invitation',
        NEW.id,
        'invitation'
      );
    END IF;
  ELSIF NEW.status = 'accepted' THEN
    -- Invitation accepted. Notify the inviter.
    INSERT INTO public.notifications (
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
      'قبول الدعوة',
      format('قبل %s دعوة الانضمام إلى %s', v_invitee_name, v_home_name),
      'invitation_accepted',
      'invitation',
      NEW.id,
      'invitation'
    );
  END IF;
  
  RETURN NEW;
END;
$$;
