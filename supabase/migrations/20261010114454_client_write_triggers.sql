-- Client-write triggers must see the invoker. security definer hides that role,
-- so the checks never ran for authenticated updates.

create or replace function validate_profile_update() returns trigger
language plpgsql security invoker set search_path = public
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

create or replace function validate_task_update() returns trigger
language plpgsql security invoker set search_path = public
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
