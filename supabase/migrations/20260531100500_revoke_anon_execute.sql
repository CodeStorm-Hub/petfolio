-- Lock down internal SECURITY DEFINER functions exposed to anon
-- (advisor 0028 anon_security_definer_function_executable).
--
-- These functions are never called by anonymous users:
--   * cleanup_expired_stories — maintenance/cron only (no client caller)
--   * get_pet_awards_summary   — called by authenticated pet_awards_provider
--   * mark_story_viewed        — called by authenticated story_repository
--
-- Functions are created with EXECUTE granted to PUBLIC by default, which anon
-- inherits, so we must REVOKE from PUBLIC (not just anon). Authenticated and
-- service_role retain their explicit grants.

revoke execute on function public.cleanup_expired_stories()
  from public, anon, authenticated;

revoke execute on function public.get_pet_awards_summary(uuid)
  from public, anon;

revoke execute on function public.mark_story_viewed(uuid)
  from public, anon;
