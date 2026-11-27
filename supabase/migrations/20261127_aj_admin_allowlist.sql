-- AJ Esencias: limitar TODOS los datos privados a cuentas administrativas autorizadas.
-- Ejecutar en Supabase > SQL Editor del proyecto egkqaymaqednmweaqbaz.
-- Actualmente solo Ámbar está autorizada. Para agregar a Jeremy en el futuro,
-- añade su correo verificado al arreglo de la función aj_is_authorized_admin().

create or replace function public.aj_is_authorized_admin()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce((auth.jwt() ->> 'email') = any (array[
    'ambardilone06@gmail.com'
  ]::text[]), false);
$$;

revoke all on function public.aj_is_authorized_admin() from public;
grant execute on function public.aj_is_authorized_admin() to authenticated;

do $$
declare
  t text;
  p record;
  private_tables text[] := array[
    'aj_business_data',
    'aj_business_backups',
    'aj_product_image_history',
    'aj_activity_log',
    'aj_products',
    'aj_sales',
    'aj_sale_payments',
    'aj_expenses',
    'aj_purchases'
  ];
begin
  foreach t in array private_tables loop
    if to_regclass('public.' || t) is not null then
      execute format('alter table public.%I enable row level security', t);

      -- Elimina políticas previas para impedir que una política permisiva
      -- antigua permita saltarse la lista de administradores.
      for p in
        select policyname
        from pg_policies
        where schemaname = 'public' and tablename = t
      loop
        execute format('drop policy if exists %I on public.%I', p.policyname, t);
      end loop;

      execute format(
        'create policy %I on public.%I for all to authenticated using (owner_id = auth.uid() and public.aj_is_authorized_admin()) with check (owner_id = auth.uid() and public.aj_is_authorized_admin())',
        'AJ authorized admin only', t
      );

      execute format('revoke all on table public.%I from anon', t);
      execute format('grant select, insert, update, delete on table public.%I to authenticated', t);
    end if;
  end loop;
end $$;

-- El bucket conserva lectura pública de imágenes de productos,
-- pero solo la cuenta administrativa autorizada puede gestionarlas.
drop policy if exists "AJ users upload their own product images" on storage.objects;
create policy "AJ users upload their own product images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'aj-product-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.aj_is_authorized_admin()
);

drop policy if exists "AJ users update their own product images" on storage.objects;
create policy "AJ users update their own product images"
on storage.objects for update to authenticated
using (
  bucket_id = 'aj-product-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.aj_is_authorized_admin()
)
with check (
  bucket_id = 'aj-product-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.aj_is_authorized_admin()
);

drop policy if exists "AJ users delete their own product images" on storage.objects;
create policy "AJ users delete their own product images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'aj-product-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.aj_is_authorized_admin()
);

-- No se habilita el acceso público a ninguna tabla privada.
