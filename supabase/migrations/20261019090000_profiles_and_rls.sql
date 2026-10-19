-- =============================================================================
-- Auth: profiles table + row level security for the whole schema
-- =============================================================================
-- DEV RESET. This migration drops the old public."user" table and clears the
-- content that referenced it, so the surviving tables can be re-pointed at
-- public.profiles. Password material now lives only in auth.users: the client
-- never reads or writes a password hash again.
--
-- Apply locally with `supabase db reset`, or to the linked project with
-- `supabase db push`.
--
-- The policies below use the column names the generated models in lib/models/
-- already expose. Run `supabase db pull` afterwards and compare: any policy
-- that predates this file and is more permissive must be dropped, otherwise
-- Postgres ORs it with the ones created here.

-- -----------------------------------------------------------------------------
-- 1. Replace public."user" with a profile table keyed to auth.users
-- -----------------------------------------------------------------------------

-- Foreign keys that referenced the old table are dropped along with it.
drop table if exists public."user" cascade;

-- Content pointing at rows that no longer exist is unusable, and the new
-- foreign keys below would refuse it. Children first.
delete from public.message;
delete from public.chat;
delete from public.event_invitation;
delete from public.event;
delete from public.circle_member;
delete from public.circle;
delete from public.friend;
delete from public.blocked_user;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  -- Collected during onboarding, so it is null between sign-up and the end of
  -- the flow. `unique` still rejects a taken name.
  username text unique,
  name text not null default '',
  surname text not null default '',
  birthdate date,
  city text,
  profile_picture text,
  private_account boolean not null default false,
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table public.profiles is
  'Public profile of an auth.users row. Rows are created by the '
  'on_auth_user_created trigger; credentials stay in auth.users.';

-- Re-point the columns that used to reference public."user". Guarded so the
-- migration still applies on a database where the constraint name is taken.
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'event_owner_id_fkey') then
    alter table public.event
      add constraint event_owner_id_fkey
      foreign key (owner_id) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'event_invitation_user_id_fkey') then
    alter table public.event_invitation
      add constraint event_invitation_user_id_fkey
      foreign key (user_id) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'circle_owner_id_fkey') then
    alter table public.circle
      add constraint circle_owner_id_fkey
      foreign key (owner_id) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'circle_member_user_id_fkey') then
    alter table public.circle_member
      add constraint circle_member_user_id_fkey
      foreign key (user_id) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'message_sender_id_fkey') then
    alter table public.message
      add constraint message_sender_id_fkey
      foreign key (sender_id) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'chat_friend_id_fkey') then
    alter table public.chat
      add constraint chat_friend_id_fkey
      foreign key (friend_id) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'friend_user_id_1_fkey') then
    alter table public.friend
      add constraint friend_user_id_1_fkey
      foreign key (user_id_1) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'friend_user_id_2_fkey') then
    alter table public.friend
      add constraint friend_user_id_2_fkey
      foreign key (user_id_2) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'blocked_user_blocker_id_fkey') then
    alter table public.blocked_user
      add constraint blocked_user_blocker_id_fkey
      foreign key (blocker_id) references public.profiles (id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'blocked_user_blocked_id_fkey') then
    alter table public.blocked_user
      add constraint blocked_user_blocked_id_fkey
      foreign key (blocked_id) references public.profiles (id) on delete cascade;
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- 2. Create a profile for every new auth user
-- -----------------------------------------------------------------------------

-- Sign-up metadata (`data:` on `auth.signUp`) carries the names collected by
-- the sign-up form. Everything else is filled in by onboarding.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, surname)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'surname', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 3. Membership helpers
-- -----------------------------------------------------------------------------
-- The policies below ask "does the current user belong to this row's circle /
-- event / chat?". Doing that with a plain subquery makes two tables' policies
-- reference each other, which Postgres rejects with "infinite recursion
-- detected in policy". These are SECURITY DEFINER, so their own reads bypass
-- RLS and the cycle is broken.

create or replace function public.is_event_owner(target_event uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.event e
    where e.id = target_event
      and e.owner_id = (select auth.uid())
  );
$$;

create or replace function public.is_event_invited(target_event uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.event_invitation i
    where i.event_id = target_event
      and i.user_id = (select auth.uid())
  );
$$;

create or replace function public.is_circle_owner(target_circle uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.circle c
    where c.id = target_circle
      and c.owner_id = (select auth.uid())
  );
$$;

create or replace function public.is_circle_member(target_circle uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.circle_member m
    where m.circle_id = target_circle
      and m.user_id = (select auth.uid())
  );
$$;

create or replace function public.is_chat_participant(target_chat uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.chat c
    where c.id = target_chat
      and (
        c.friend_id = (select auth.uid())
        or public.is_circle_member(c.circle_id)
        or public.is_event_owner(c.event_id)
        or public.is_event_invited(c.event_id)
      )
  );
$$;

-- -----------------------------------------------------------------------------
-- 4. Row level security
-- -----------------------------------------------------------------------------
-- Every table is locked down to signed-in users; there is no anonymous access
-- path. A client can only ever write rows it owns.

alter table public.profiles enable row level security;
alter table public.event enable row level security;
alter table public.event_invitation enable row level security;
alter table public.circle enable row level security;
alter table public.circle_member enable row level security;
alter table public.chat enable row level security;
alter table public.message enable row level security;
alter table public.friend enable row level security;
alter table public.blocked_user enable row level security;

-- profiles: readable by anyone signed in (usernames and names are the point of
-- the app), writable only by its owner. Rows are created by the trigger and
-- removed by the auth.users cascade, so the client has neither insert nor
-- delete rights -- except the insert below, which covers a profile whose
-- trigger never ran.
drop policy if exists profiles_select_authenticated on public.profiles;
create policy profiles_select_authenticated on public.profiles
  for select to authenticated
  using (true);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- event: public events are visible to everyone signed in; private ones only to
-- their owner and the people invited to them.
drop policy if exists event_select_visible on public.event;
create policy event_select_visible on public.event
  for select to authenticated
  using (
    is_public
    or owner_id = (select auth.uid())
    or public.is_event_invited(id)
  );

drop policy if exists event_insert_own on public.event;
create policy event_insert_own on public.event
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

drop policy if exists event_update_own on public.event;
create policy event_update_own on public.event
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists event_delete_own on public.event;
create policy event_delete_own on public.event
  for delete to authenticated
  using (owner_id = (select auth.uid()));

-- event_invitation: the organiser manages the guest list, a guest sees and
-- answers their own invitation.
drop policy if exists event_invitation_select on public.event_invitation;
create policy event_invitation_select on public.event_invitation
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_event_owner(event_id));

drop policy if exists event_invitation_insert on public.event_invitation;
create policy event_invitation_insert on public.event_invitation
  for insert to authenticated
  with check (
    user_id = (select auth.uid()) or public.is_event_owner(event_id)
  );

drop policy if exists event_invitation_update on public.event_invitation;
create policy event_invitation_update on public.event_invitation
  for update to authenticated
  using (user_id = (select auth.uid()) or public.is_event_owner(event_id))
  with check (user_id = (select auth.uid()) or public.is_event_owner(event_id));

drop policy if exists event_invitation_delete on public.event_invitation;
create policy event_invitation_delete on public.event_invitation
  for delete to authenticated
  using (user_id = (select auth.uid()) or public.is_event_owner(event_id));

-- circle: the owner manages it, members can see it.
drop policy if exists circle_select_member on public.circle;
create policy circle_select_member on public.circle
  for select to authenticated
  using (owner_id = (select auth.uid()) or public.is_circle_member(id));

drop policy if exists circle_insert_own on public.circle;
create policy circle_insert_own on public.circle
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

drop policy if exists circle_update_own on public.circle;
create policy circle_update_own on public.circle
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists circle_delete_own on public.circle;
create policy circle_delete_own on public.circle
  for delete to authenticated
  using (owner_id = (select auth.uid()));

-- circle_member: members see each other, the owner runs the roster, and anyone
-- can remove themselves (leave a circle).
drop policy if exists circle_member_select on public.circle_member;
create policy circle_member_select on public.circle_member
  for select to authenticated
  using (
    user_id = (select auth.uid()) or public.is_circle_member(circle_id)
  );

drop policy if exists circle_member_insert on public.circle_member;
create policy circle_member_insert on public.circle_member
  for insert to authenticated
  with check (
    user_id = (select auth.uid()) or public.is_circle_owner(circle_id)
  );

drop policy if exists circle_member_update on public.circle_member;
create policy circle_member_update on public.circle_member
  for update to authenticated
  using (
    user_id = (select auth.uid()) or public.is_circle_owner(circle_id)
  )
  with check (
    user_id = (select auth.uid()) or public.is_circle_owner(circle_id)
  );

drop policy if exists circle_member_delete on public.circle_member;
create policy circle_member_delete on public.circle_member
  for delete to authenticated
  using (
    user_id = (select auth.uid()) or public.is_circle_owner(circle_id)
  );

-- chat: participants only. A chat is a direct message (friend_id), a circle
-- thread or an event thread.
drop policy if exists chat_select_participant on public.chat;
create policy chat_select_participant on public.chat
  for select to authenticated
  using (
    friend_id = (select auth.uid())
    or public.is_circle_member(circle_id)
    or public.is_event_owner(event_id)
    or public.is_event_invited(event_id)
  );

drop policy if exists chat_insert_participant on public.chat;
create policy chat_insert_participant on public.chat
  for insert to authenticated
  with check (
    friend_id = (select auth.uid())
    or public.is_circle_member(circle_id)
    or public.is_event_owner(event_id)
    or public.is_event_invited(event_id)
  );

-- message: readable by the chat's participants, written by its sender.
drop policy if exists message_select_participant on public.message;
create policy message_select_participant on public.message
  for select to authenticated
  using (public.is_chat_participant(chat_id));

drop policy if exists message_insert_own on public.message;
create policy message_insert_own on public.message
  for insert to authenticated
  with check (
    sender_id = (select auth.uid()) and public.is_chat_participant(chat_id)
  );

drop policy if exists message_update_own on public.message;
create policy message_update_own on public.message
  for update to authenticated
  using (sender_id = (select auth.uid()))
  with check (sender_id = (select auth.uid()));

drop policy if exists message_delete_own on public.message;
create policy message_delete_own on public.message
  for delete to authenticated
  using (sender_id = (select auth.uid()));

-- friend: either side of the friendship can see and write the row.
drop policy if exists friend_select_own on public.friend;
create policy friend_select_own on public.friend
  for select to authenticated
  using (
    user_id_1 = (select auth.uid()) or user_id_2 = (select auth.uid())
  );

drop policy if exists friend_insert_own on public.friend;
create policy friend_insert_own on public.friend
  for insert to authenticated
  with check (
    user_id_1 = (select auth.uid()) or user_id_2 = (select auth.uid())
  );

drop policy if exists friend_delete_own on public.friend;
create policy friend_delete_own on public.friend
  for delete to authenticated
  using (
    user_id_1 = (select auth.uid()) or user_id_2 = (select auth.uid())
  );

-- blocked_user: private to the person who did the blocking.
drop policy if exists blocked_user_select_own on public.blocked_user;
create policy blocked_user_select_own on public.blocked_user
  for select to authenticated
  using (blocker_id = (select auth.uid()));

drop policy if exists blocked_user_insert_own on public.blocked_user;
create policy blocked_user_insert_own on public.blocked_user
  for insert to authenticated
  with check (blocker_id = (select auth.uid()));

drop policy if exists blocked_user_delete_own on public.blocked_user;
create policy blocked_user_delete_own on public.blocked_user
  for delete to authenticated
  using (blocker_id = (select auth.uid()));
