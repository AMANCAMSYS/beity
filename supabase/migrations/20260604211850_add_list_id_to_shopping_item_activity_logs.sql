CREATE OR REPLACE FUNCTION public.log_shopping_item_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_home_id uuid;
  v_list_id uuid;
  v_list_title text;
BEGIN
  v_list_id := COALESCE(NEW.list_id, OLD.list_id);

  SELECT sl.home_id, sl.title
    INTO v_home_id, v_list_title
  FROM public.shopping_lists sl
  WHERE sl.id = v_list_id;

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.activity_logs (
      home_id, user_id, action, entity_type, entity_id, metadata
    )
    VALUES (
      v_home_id,
      NEW.created_by,
      'item_added',
      'shopping_item',
      NEW.id,
      jsonb_build_object(
        'name', NEW.name,
        'list_id', v_list_id,
        'list_title', v_list_title
      )
    );
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      INSERT INTO public.activity_logs (
        home_id, user_id, action, entity_type, entity_id, metadata
      )
      VALUES (
        v_home_id,
        COALESCE(NEW.updated_by, NEW.created_by),
        'item_deleted',
        'shopping_item',
        NEW.id,
        jsonb_build_object(
          'name', NEW.name,
          'list_id', v_list_id,
          'list_title', v_list_title
        )
      );
    END IF;

    IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
      INSERT INTO public.activity_logs (
        home_id, user_id, action, entity_type, entity_id, metadata
      )
      VALUES (
        v_home_id,
        COALESCE(NEW.completed_by, NEW.updated_by, NEW.created_by),
        'item_purchased',
        'shopping_item',
        NEW.id,
        jsonb_build_object(
          'name', NEW.name,
          'list_id', v_list_id,
          'list_title', v_list_title
        )
      );
    END IF;

    IF NEW.status <> 'completed' AND OLD.status = 'completed' THEN
      INSERT INTO public.activity_logs (
        home_id, user_id, action, entity_type, entity_id, metadata
      )
      VALUES (
        v_home_id,
        COALESCE(NEW.updated_by, NEW.created_by),
        'item_unpurchased',
        'shopping_item',
        NEW.id,
        jsonb_build_object(
          'name', NEW.name,
          'list_id', v_list_id,
          'list_title', v_list_title
        )
      );
    END IF;

    IF OLD.name IS DISTINCT FROM NEW.name
       OR OLD.quantity IS DISTINCT FROM NEW.quantity THEN
      INSERT INTO public.activity_logs (
        home_id, user_id, action, entity_type, entity_id, metadata
      )
      VALUES (
        v_home_id,
        COALESCE(NEW.updated_by, NEW.created_by),
        'item_updated',
        'shopping_item',
        NEW.id,
        jsonb_build_object(
          'name', NEW.name,
          'list_id', v_list_id,
          'list_title', v_list_title
        )
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
