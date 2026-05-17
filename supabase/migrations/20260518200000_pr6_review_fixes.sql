REVOKE ALL ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) TO authenticated;
