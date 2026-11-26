-- AJ Esencias: almacenamiento privado de respaldo en la nube.
-- Ejecutar una sola vez en Supabase > SQL Editor.
create table if not exists public.aj_business_data (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.aj_business_data enable row level security;

drop policy if exists "Users manage own AJ cloud backup" on public.aj_business_data;
create policy "Users manage own AJ cloud backup"
  on public.aj_business_data
  for all to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.aj_business_data to authenticated;
