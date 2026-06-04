-- Revoke anon EXECUTE on SECURITY DEFINER functions that should only be
-- callable by authenticated users. Flagged by Supabase security advisors.

-- Chat / social RPCs
REVOKE EXECUTE ON FUNCTION public.ensure_direct_chat_thread(uuid, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_chat_inbox(uuid) FROM anon;

-- Matching discovery (contains location + pet data — authenticated only)
REVOKE EXECUTE ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer, integer, text[], integer, integer) FROM anon;
