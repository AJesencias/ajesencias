-- AJ Esencias: backups, image recovery and activity history
-- Run this file in Supabase SQL Editor while connected to the AJ Esencias project.

create table if not exists public.aj_business_backups (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  payload jsonb not null,
  label text not null default 'Respaldo automático',
  created_at timestamptz not null default now()
);

create index if not exists aj_business_backups_owner_created_idx
  on public.aj_business_backups (owner_id, created_at desc);

create table if not exists public.aj_product_image_history (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null,
  product_name text not null,
  image_url text not null,
  action text not null check (action in ('reemplazada', 'eliminada')),
  created_at timestamptz not null default now()
);

create index if not exists aj_product_image_history_owner_product_created_idx
  on public.aj_product_image_history (owner_id, product_id, created_at desc);

create table if not exists public.aj_activity_log (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  entity_type text not null,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists aj_activity_log_owner_created_idx
  on public.aj_activity_log (owner_id, created_at desc);

alter table public.aj_business_backups enable row level security;
alter table public.aj_product_image_history enable row level security;
alter table public.aj_activity_log enable row level security;

drop policy if exists "AJ owner reads backups" on public.aj_business_backups;
create policy "AJ owner reads backups" on public.aj_business_backups
  for select to authenticated using (owner_id = auth.uid());
drop policy if exists "AJ owner creates backups" on public.aj_business_backups;
create policy "AJ owner creates backups" on public.aj_business_backups
  for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists "AJ owner deletes backups" on public.aj_business_backups;
create policy "AJ owner deletes backups" on public.aj_business_backups
  for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "AJ owner reads image history" on public.aj_product_image_history;
create policy "AJ owner reads image history" on public.aj_product_image_history
  for select to authenticated using (owner_id = auth.uid());
drop policy if exists "AJ owner creates image history" on public.aj_product_image_history;
create policy "AJ owner creates image history" on public.aj_product_image_history
  for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists "AJ owner deletes image history" on public.aj_product_image_history;
create policy "AJ owner deletes image history" on public.aj_product_image_history
  for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "AJ owner reads activity" on public.aj_activity_log;
create policy "AJ owner reads activity" on public.aj_activity_log
  for select to authenticated using (owner_id = auth.uid());
drop policy if exists "AJ owner creates activity" on public.aj_activity_log;
create policy "AJ owner creates activity" on public.aj_activity_log
  for insert to authenticated with check (owner_id = auth.uid());

grant select, insert, delete on public.aj_business_backups to authenticated;
grant select, insert, delete on public.aj_product_image_history to authenticated;
grant select, insert on public.aj_activity_log to authenticated;

-- The existing AJ product-image bucket is public so product photos can be displayed
-- on the public storefront. Upload/change/delete is restricted to each account's folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('aj-product-images', 'aj-product-images', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
set public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

drop policy if exists "AJ product images are publicly readable" on storage.objects;
create policy "AJ product images are publicly readable" on storage.objects
  for select to public using (bucket_id = 'aj-product-images');

drop policy if exists "AJ users upload their own product images" on storage.objects;
create policy "AJ users upload their own product images" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "AJ users update their own product images" on storage.objects;
create policy "AJ users update their own product images" on storage.objects
  for update to authenticated
  using (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "AJ users delete their own product images" on storage.objects;
create policy "AJ users delete their own product images" on storage.objects
  for delete to authenticated
  using (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- Ensure each account can only read/write its own synchronized business record.
alter table public.aj_business_data enable row level security;

-- Remove any older policies on this AJ-specific table so a permissive legacy
-- policy cannot accidentally bypass owner isolation.
do $
declare policy_row record;
begin
  for policy_row in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'aj_business_data'
  loop
    execute format('drop policy if exists %I on public.aj_business_data', policy_row.policyname);
  end loop;
end $;

drop policy if exists "AJ owner reads business data" on public.aj_business_data;
create policy "AJ owner reads business data" on public.aj_business_data
  for select to authenticated using (owner_id = auth.uid());
drop policy if exists "AJ owner inserts business data" on public.aj_business_data;
create policy "AJ owner inserts business data" on public.aj_business_data
  for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists "AJ owner updates business data" on public.aj_business_data;
create policy "AJ owner updates business data" on public.aj_business_data
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
grant select, insert, update on public.aj_business_data to authenticated;
