-- Create RPC function to safely increment template usage without race conditions
create or replace function public.increment_template_usage(template_id uuid)
returns void as $$
begin
  update public.item_templates
  set usage_count = coalesce(usage_count, 0) + 1,
      updated_at = now()
  where id = template_id;
end;
$$ language plpgsql security definer set search_path = public;

-- Create RPC function to safely sync template on item add with atomic insert-or-increment
create or replace function public.sync_template_on_add(
  p_home_id uuid,
  p_name text,
  p_quantity numeric,
  p_unit_id uuid,
  p_category_id uuid,
  p_user_id uuid
)
returns void as $$
begin
  insert into public.item_templates (
    home_id,
    name,
    default_quantity,
    default_unit_id,
    default_category_id,
    created_by,
    usage_count
  )
  values (
    p_home_id,
    p_name,
    p_quantity,
    p_unit_id,
    p_category_id,
    p_user_id,
    1
  )
  on conflict (home_id, name) do update
  set usage_count = coalesce(item_templates.usage_count, 0) + 1,
      updated_at = now();
end;
$$ language plpgsql security definer set search_path = public;
