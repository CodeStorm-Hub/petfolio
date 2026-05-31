-- Pin search_path on flagged functions (advisor 0011 function_search_path_mutable).
-- All bodies already schema-qualify their objects, so an empty search_path is safe
-- and removes the privilege-escalation surface for the SECURITY DEFINER triggers.

create or replace function public.is_admin()
  returns boolean
  language sql
  stable
  set search_path = ''
as $function$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean,
    false
  );
$function$;

create or replace function public.handle_post_like_sync()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $function$
begin
  if (tg_op = 'INSERT') then
    update public.posts set like_count = like_count + 1 where id = new.post_id;
  elsif (tg_op = 'DELETE') then
    update public.posts set like_count = greatest(0, like_count - 1) where id = old.post_id;
  end if;
  return null;
end;
$function$;

create or replace function public.handle_comment_like_sync()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $function$
begin
  if (tg_op = 'INSERT') then
    update public.comments set like_count = like_count + 1 where id = new.comment_id;
  elsif (tg_op = 'DELETE') then
    update public.comments set like_count = greatest(0, like_count - 1) where id = old.comment_id;
  end if;
  return null;
end;
$function$;

create or replace function public.handle_post_comment_sync()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $function$
begin
  if (tg_op = 'INSERT') then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif (tg_op = 'DELETE') then
    update public.posts set comment_count = greatest(0, comment_count - 1) where id = old.post_id;
  end if;
  return null;
end;
$function$;

create or replace function public.handle_new_chat_message()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $function$
begin
  update public.chat_threads
  set last_message_at = new.created_at,
      last_message_content = new.content
  where id = new.thread_id;
  return new;
end;
$function$;
