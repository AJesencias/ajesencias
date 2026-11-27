-- AJ Esencias: catálogo público separado de los datos privados.
-- Ejecutar en Supabase > SQL Editor después de la migración de administradores autorizados.
-- Esta tabla contiene exclusivamente campos aptos para clientes: nombre, categoría,
-- precio e imagen. No almacenar costos, stock, proveedores, ventas ni datos de clientes.

create table if not exists public.aj_public_catalog (
  product_id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  category text not null default 'Productos',
  name text not null,
  price numeric(12,2) not null default 0 check (price >= 0),
  image_url text,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create index if not exists aj_public_catalog_active_category_idx
  on public.aj_public_catalog (is_active, category, name);

alter table public.aj_public_catalog enable row level security;

drop policy if exists "AJ public catalog read active" on public.aj_public_catalog;
create policy "AJ public catalog read active"
  on public.aj_public_catalog
  for select to anon, authenticated
  using (is_active = true);

drop policy if exists "AJ authorized admin manage public catalog" on public.aj_public_catalog;
create policy "AJ authorized admin manage public catalog"
  on public.aj_public_catalog
  for all to authenticated
  using (owner_id = auth.uid() and public.aj_is_authorized_admin())
  with check (owner_id = auth.uid() and public.aj_is_authorized_admin());

revoke all on table public.aj_public_catalog from anon, authenticated;
grant select (product_id, category, name, price, image_url, is_active)
  on public.aj_public_catalog to anon;
grant select, insert, update, delete
  on public.aj_public_catalog to authenticated;

-- La política RLS permite al público leer solo filas activas.
-- La cuenta administrativa autorizada puede gestionar sus propias filas.
