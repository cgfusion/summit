-- ---------------------------------------------------------------------------
-- Migration: 20260818000002_add_storage_delete_policy.sql
-- Description: Allows authenticated users to delete uploaded images from sudut-info-banners bucket.
-- ---------------------------------------------------------------------------

drop policy if exists "Authenticated delete from sudut-info-banners" on storage.objects;
create policy "Authenticated delete from sudut-info-banners"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'sudut-info-banners');
