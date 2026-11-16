-- T164: Edge Functions passed `JSON.stringify(x)` into `::jsonb` parameters. postgres.js typed the
-- parameter as jsonb and serialised the string again, so these columns stored a JSON string
-- ("{\"a\":1}") instead of an object. The functions now cast through text; this repairs the rows
-- written before that fix.

create or replace function public.unwrap_jsonb_string(value jsonb)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  parsed jsonb;
begin
  if value is null or jsonb_typeof(value) <> 'string' then
    return value;
  end if;
  begin
    parsed := (value #>> '{}')::jsonb;
  exception when others then
    return value;
  end;
  if jsonb_typeof(parsed) in ('object', 'array') then
    return parsed;
  end if;
  return value;
end;
$$;

revoke all on function public.unwrap_jsonb_string(jsonb) from public, anon, authenticated;

update public.player_state set counters = public.unwrap_jsonb_string(counters) where jsonb_typeof(counters) = 'string';
update public.player_state set onboarding_bonus = public.unwrap_jsonb_string(onboarding_bonus) where jsonb_typeof(onboarding_bonus) = 'string';
update public.sessions set summary = public.unwrap_jsonb_string(summary) where jsonb_typeof(summary) = 'string';
update public.activity_events set payload = public.unwrap_jsonb_string(payload) where jsonb_typeof(payload) = 'string';
update public.processed_requests set result = public.unwrap_jsonb_string(result) where jsonb_typeof(result) = 'string';
update public.inbox set payload = public.unwrap_jsonb_string(payload) where jsonb_typeof(payload) = 'string';
update public.bosses set loot = public.unwrap_jsonb_string(loot) where jsonb_typeof(loot) = 'string';
