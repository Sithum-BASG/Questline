-- Helper functions, RLS, client-write triggers, realtime and indexes (schema §4–§5).
-- Triggers apply only to the authenticated role so Edge Functions can write freely.

create function is_friend(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from friendships
    where user_id = a and friend_id = b and status = 'accepted'
  );
$$;

create function is_raid_member(r uuid, u uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from raid_members
    where raid_id = r and user_id = u and not left_raid
  );
$$;

create function is_raid_creator(r uuid, u uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from raids where id = r and created_by = u
  );
$$;

create function is_guild_member(g uuid, u uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from guild_members where guild_id = g and user_id = u
  );
$$;

create function radar_hidden(u uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce((select hide_radar from profiles where id = u), false);
$$;

revoke all on function
  is_friend(uuid, uuid),
  is_raid_member(uuid, uuid),
  is_raid_creator(uuid, uuid),
  is_guild_member(uuid, uuid),
  radar_hidden(uuid)
from public, anon;
grant execute on function
  is_friend(uuid, uuid),
  is_raid_member(uuid, uuid),
  is_raid_creator(uuid, uuid),
  is_guild_member(uuid, uuid),
  radar_hidden(uuid)
to authenticated;

create function validate_profile_update() returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  item_type text;
  badge text;
  badge_tier int;
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if new.equipped_skin_id is distinct from old.equipped_skin_id then
    select type into item_type from catalog_items where id = new.equipped_skin_id;
    if item_type is distinct from 'skin'
      or not exists (
        select 1 from inventory
        where user_id = new.id and catalog_id = new.equipped_skin_id
      ) then
      raise exception 'equipped skin must be an owned skin';
    end if;
  end if;

  if new.equipped_background_id is distinct from old.equipped_background_id then
    select type into item_type from catalog_items where id = new.equipped_background_id;
    if item_type is distinct from 'background'
      or not exists (
        select 1 from inventory
        where user_id = new.id and catalog_id = new.equipped_background_id
      ) then
      raise exception 'equipped background must be an owned background';
    end if;
  end if;

  if new.equipped_frame_id is distinct from old.equipped_frame_id then
    select type into item_type from catalog_items where id = new.equipped_frame_id;
    if item_type is distinct from 'frame'
      or not exists (
        select 1 from inventory
        where user_id = new.id and catalog_id = new.equipped_frame_id
      ) then
      raise exception 'equipped frame must be an owned frame';
    end if;
  end if;

  if new.title_id is distinct from old.title_id and new.title_id is not null then
    if not exists (
      select 1 from player_state
      where user_id = new.id and new.title_id = any (owned_titles)
    ) then
      raise exception 'title must be owned';
    end if;
  end if;

  if new.pinned_badges is distinct from old.pinned_badges then
    foreach badge in array new.pinned_badges loop
      select tier into badge_tier
      from achievements
      where user_id = new.id and badge_id = badge;
      if badge_tier is null or badge_tier < 1 then
        raise exception 'pinned badge needs tier 1';
      end if;
    end loop;
  end if;

  return new;
end;
$$;

create trigger validate_profile_update
  before update on profiles
  for each row execute function validate_profile_update();

create function validate_task_update() returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if new.status is distinct from old.status
    and not (old.status = 'draft' and new.status = 'open' and new.difficulty is not null) then
    raise exception 'only a judged draft can be opened';
  end if;

  if new.stat is distinct from old.stat and old.status = 'done' then
    raise exception 'stat cannot change after completion';
  end if;

  return new;
end;
$$;

create trigger validate_task_update
  before update on tasks
  for each row execute function validate_task_update();

alter table catalog_items enable row level security;
alter table level_rewards enable row level security;
alter table game_config enable row level security;
alter table profiles enable row level security;
alter table player_state enable row level security;
alter table user_settings enable row level security;
alter table bosses enable row level security;
alter table tasks enable row level security;
alter table sessions enable row level security;
alter table inventory enable row level security;
alter table achievements enable row level security;
alter table daily_stats enable row level security;
alter table friendships enable row level security;
alter table friend_summaries enable row level security;
alter table guilds enable row level security;
alter table guild_members enable row level security;
alter table guild_trophies enable row level security;
alter table activity_events enable row level security;
alter table weekly_scores enable row level security;
alter table inbox enable row level security;
alter table presence enable row level security;
alter table raids enable row level security;
alter table raid_members enable row level security;
alter table raid_damage enable row level security;
alter table raid_events enable row level security;
alter table demo_allowlist enable row level security;
alter table processed_requests enable row level security;

create policy catalog_items_select on catalog_items for select to authenticated using (true);
create policy level_rewards_select on level_rewards for select to authenticated using (true);
create policy game_config_select on game_config for select to authenticated using (true);

create policy profiles_select on profiles for select to authenticated
  using (auth.uid() is not null);
create policy profiles_update on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy player_state_select on player_state for select to authenticated
  using (user_id = auth.uid());
create policy sessions_select on sessions for select to authenticated
  using (user_id = auth.uid());
create policy bosses_select on bosses for select to authenticated
  using (user_id = auth.uid());
create policy inventory_select on inventory for select to authenticated
  using (user_id = auth.uid());
create policy achievements_select on achievements for select to authenticated
  using (user_id = auth.uid());
create policy friendships_select on friendships for select to authenticated
  using (user_id = auth.uid());

create policy user_settings_select on user_settings for select to authenticated
  using (user_id = auth.uid());
create policy user_settings_update on user_settings for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy tasks_select on tasks for select to authenticated
  using (user_id = auth.uid());
create policy tasks_insert on tasks for insert to authenticated
  with check (
    user_id = auth.uid()
    and status = 'draft'
    and (
      boss_id is null
      or exists (select 1 from bosses where id = boss_id and user_id = auth.uid())
    )
    and (raid_id is null or is_raid_member(raid_id, auth.uid()))
  );
create policy tasks_update on tasks for update to authenticated
  using (user_id = auth.uid() and status in ('draft', 'open'))
  with check (user_id = auth.uid() and status in ('draft', 'open'));
create policy tasks_delete on tasks for delete to authenticated
  using (user_id = auth.uid() and status in ('draft', 'open'));

create policy daily_stats_select on daily_stats for select to authenticated
  using (
    user_id = auth.uid()
    or (is_friend(user_id, auth.uid()) and not radar_hidden(user_id))
  );

create policy friend_summaries_select on friend_summaries for select to authenticated
  using (user_id = auth.uid() or is_friend(user_id, auth.uid()));
create policy weekly_scores_select on weekly_scores for select to authenticated
  using (user_id = auth.uid() or is_friend(user_id, auth.uid()));

create policy guilds_select on guilds for select to authenticated
  using (is_guild_member(id, auth.uid()));
create policy guild_members_select on guild_members for select to authenticated
  using (is_guild_member(guild_id, auth.uid()));
create policy guild_trophies_select on guild_trophies for select to authenticated
  using (is_guild_member(guild_id, auth.uid()));

create policy activity_events_select on activity_events for select to authenticated
  using (auth.uid() = any (visible_to));

create policy inbox_select on inbox for select to authenticated
  using (user_id = auth.uid());
create policy inbox_update on inbox for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy presence_select on presence for select to authenticated
  using (
    user_id = auth.uid()
    or is_friend(user_id, auth.uid())
    or (raid_id is not null and is_raid_member(raid_id, auth.uid()))
  );
create policy presence_update on presence for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy raids_select on raids for select to authenticated
  using (is_raid_member(id, auth.uid()));
create policy raid_members_select on raid_members for select to authenticated
  using (is_raid_member(raid_id, auth.uid()));
create policy raid_events_select on raid_events for select to authenticated
  using (is_raid_member(raid_id, auth.uid()));
create policy raid_damage_select on raid_damage for select to authenticated
  using (user_id = auth.uid() or is_raid_creator(raid_id, auth.uid()));

alter publication supabase_realtime add table raids, raid_members, raid_events, presence, inbox;

create index tasks_user_status_due on tasks (user_id, status, due_at);
create index tasks_provisional on tasks (provisional) where provisional;
create index bosses_open_deadlines on bosses (status, deadline) where status in ('active', 'staggered');
create index raids_active_deadlines on raids (status, deadline) where status = 'active';
create index raid_members_user on raid_members (user_id);
create index activity_events_visible on activity_events using gin (visible_to);
create index activity_events_created on activity_events (created_at desc);
create index player_state_rollover on player_state (next_rollover_at);
create index sessions_active on sessions (status, started_at) where status = 'active';
create index daily_stats_user_day on daily_stats (user_id, day desc);
create index weekly_scores_week_xp on weekly_scores (week_id, raw_xp desc);
