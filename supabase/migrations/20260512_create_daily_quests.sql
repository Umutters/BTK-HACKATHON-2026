-- Daily quests table for Supabase-only quest state
-- Compatible with SupabaseService.getOrCreateDailyQuests/startDailyQuest/completeDailyQuest

create table if not exists public.daily_quests (
  user_id uuid not null,
  quest_date date not null,
  id text not null,
  title text not null,
  description text not null,
  xp_reward integer not null check (xp_reward >= 0),
  status text not null default 'notStarted' check (status in ('notStarted', 'inProgress', 'completed')),
  icon_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint daily_quests_pk primary key (user_id, quest_date, id),
  constraint daily_quests_user_fk foreign key (user_id) references auth.users(id) on delete cascade
);

create index if not exists daily_quests_user_date_idx
  on public.daily_quests (user_id, quest_date desc);

create index if not exists daily_quests_status_idx
  on public.daily_quests (status);

-- Keep updated_at fresh on updates
create or replace function public.set_daily_quests_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_daily_quests_updated_at on public.daily_quests;
create trigger trg_daily_quests_updated_at
before update on public.daily_quests
for each row execute function public.set_daily_quests_updated_at();

alter table public.daily_quests enable row level security;

-- Users can read only their own quests
drop policy if exists "daily_quests_select_own" on public.daily_quests;
create policy "daily_quests_select_own"
on public.daily_quests
for select
using (auth.uid() = user_id);

-- Users can insert only their own quests
drop policy if exists "daily_quests_insert_own" on public.daily_quests;
create policy "daily_quests_insert_own"
on public.daily_quests
for insert
with check (auth.uid() = user_id);

-- Users can update only their own quests
drop policy if exists "daily_quests_update_own" on public.daily_quests;
create policy "daily_quests_update_own"
on public.daily_quests
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Optional: users can delete only their own quests
drop policy if exists "daily_quests_delete_own" on public.daily_quests;
create policy "daily_quests_delete_own"
on public.daily_quests
for delete
using (auth.uid() = user_id);
