-- AJ Esencias: bucket público para mostrar imágenes del catálogo.
-- La lectura es pública; solo usuarios autenticados pueden escribir dentro de su propia carpeta.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('aj-product-images', 'aj-product-images', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view AJ product images" on storage.objects;
create policy "Public can view AJ product images"
on storage.objects for select
using (bucket_id = 'aj-product-images');

drop policy if exists "Users upload own AJ product images" on storage.objects;
create policy "Users upload own AJ product images"
on storage.objects for insert to authenticated
with check (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users update own AJ product images" on storage.objects;
create policy "Users update own AJ product images"
on storage.objects for update to authenticated
using (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users delete own AJ product images" on storage.objects;
create policy "Users delete own AJ product images"
on storage.objects for delete to authenticated
using (bucket_id = 'aj-product-images' and (storage.foldername(name))[1] = auth.uid()::text);
