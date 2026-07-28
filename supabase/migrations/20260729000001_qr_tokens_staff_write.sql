-- Allow any staff member (not just admins) to register/reissue QR cards,
-- since this is a routine teacher task (a lost/damaged card, or a student
-- whose card was never printed). Deletion stays admin-only.

drop policy if exists qr_tokens_admin_write on public.qr_tokens;

create policy qr_tokens_staff_insert on public.qr_tokens
  for insert
  with check (public.is_staff());

create policy qr_tokens_staff_update on public.qr_tokens
  for update
  using (public.is_staff())
  with check (public.is_staff());

create policy qr_tokens_admin_delete on public.qr_tokens
  for delete
  using (public.is_admin());
