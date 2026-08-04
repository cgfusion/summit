-- ---------------------------------------------------------------------------
-- Per-user Dashboard card order, so a rearranged layout follows the user to
-- any device. NULL means "use the default order". Written only via
-- fn_update_dashboard_layout (security definer, scoped to auth.uid()) so a
-- non-admin user can save their own layout without needing a broader
-- self-update RLS policy on profiles (writes there are otherwise
-- admin-only, see profiles_admin_write).
-- ---------------------------------------------------------------------------
alter table public.profiles add column dashboard_layout jsonb;

create or replace function public.fn_update_dashboard_layout(p_layout jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set dashboard_layout = p_layout where id = auth.uid();
end;
$$;

grant execute on function public.fn_update_dashboard_layout(jsonb) to authenticated;
