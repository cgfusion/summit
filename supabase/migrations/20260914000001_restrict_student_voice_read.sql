-- ---------------------------------------------------------------------------
-- Migration: 20260914000001_restrict_student_voice_read.sql
-- Description: Fixes KI-014 -- student_voice_submissions previously granted
-- `anon` unrestricted SELECT, meaning anyone holding the public anon key
-- could read every submission's full subject/message text via a raw
-- PostgREST call, including ones marked is_anonymous = true (confidential
-- anti-bullying/safety reports). The is_anonymous flag only nulls
-- student_id -- it never restricted who could read the row.
--
-- Students still read their OWN past submissions via
-- fn_student_portal_data_by_qr, a `security definer` function that bypasses
-- RLS entirely -- this policy change does not affect that path. The only
-- direct table read in the Dart codebase (`getAllVoiceSubmissions`) is
-- called exclusively from the staff-only, auth-gated Discipline & Counseling
-- screen, so restricting SELECT to `authenticated` breaks nothing there.
--
-- INSERT stays open to anon + authenticated: students submit via QR Name
-- Tag login, which never establishes a Supabase Auth session.
-- ---------------------------------------------------------------------------

drop policy if exists "public_read_voice" on public.student_voice_submissions;

drop policy if exists "staff_read_voice" on public.student_voice_submissions;
create policy "staff_read_voice"
  on public.student_voice_submissions for select
  to authenticated
  using (true);
