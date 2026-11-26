-- AJ Esencias: esquema inicial de gestión comercial en Supabase
-- Ejecutar en Supabase > SQL Editor. Las tablas quedan aisladas por usuario.
create extension if not exists pgcrypto;

create table if not exists public.aj_products (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category text,
  price numeric(12,2) not null default 0 check (price >= 0),
  unit_cost numeric(12,2) not null default 0 check (unit_cost >= 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, id)
);

create table if not exists public.aj_sales (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid,
  product_name text not null,
  customer_name text,
  sale_date date not null default current_date,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  unit_cost numeric(12,2) not null check (unit_cost >= 0),
  total numeric(12,2) not null check (total >= 0),
  paid numeric(12,2) not null default 0 check (paid >= 0 and paid <= total),
  payment_mode text not null check (payment_mode in ('Contado','Crédito','Parcial')),
  created_at timestamptz not null default now(),
  unique(owner_id, id),
  constraint aj_sales_product_owner_fk foreign key(owner_id, product_id)
    references public.aj_products(owner_id, id)
);

create table if not exists public.aj_sale_payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  sale_id uuid not null,
  amount numeric(12,2) not null check (amount > 0),
  paid_at timestamptz not null default now(),
  note text,
  foreign key(owner_id, sale_id) references public.aj_sales(owner_id, id) on delete cascade
);

create table if not exists public.aj_expenses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  description text not null,
  category text not null,
  amount numeric(12,2) not null check (amount > 0),
  expense_date date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists aj_products_owner_idx on public.aj_products(owner_id);
create index if not exists aj_sales_owner_date_idx on public.aj_sales(owner_id, sale_date desc);
create index if not exists aj_payments_owner_sale_idx on public.aj_sale_payments(owner_id, sale_id);
create index if not exists aj_expenses_owner_date_idx on public.aj_expenses(owner_id, expense_date desc);

alter table public.aj_products enable row level security;
alter table public.aj_sales enable row level security;
alter table public.aj_sale_payments enable row level security;
alter table public.aj_expenses enable row level security;

drop policy if exists "Users manage own AJ products" on public.aj_products;
create policy "Users manage own AJ products" on public.aj_products
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Users manage own AJ sales" on public.aj_sales;
create policy "Users manage own AJ sales" on public.aj_sales
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Users manage own AJ sale payments" on public.aj_sale_payments;
create policy "Users manage own AJ sale payments" on public.aj_sale_payments
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Users manage own AJ expenses" on public.aj_expenses;
create policy "Users manage own AJ expenses" on public.aj_expenses
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
