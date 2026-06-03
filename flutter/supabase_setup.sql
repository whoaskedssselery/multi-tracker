-- Multi-tracker cloud sync — run ONCE in Supabase SQL Editor.
-- Creates a single per-user row holding the whole app database as JSON,
-- protected by Row Level Security so each user only sees their own data.

create table if not exists public.app_state (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  device     text
);

alter table public.app_state enable row level security;

-- A user can read/write only their own row.
create policy "app_state select own" on public.app_state
  for select using (auth.uid() = user_id);

create policy "app_state insert own" on public.app_state
  for insert with check (auth.uid() = user_id);

create policy "app_state update own" on public.app_state
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "app_state delete own" on public.app_state
  for delete using (auth.uid() = user_id);
