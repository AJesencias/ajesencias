-- AJ Esencias: galería pública de imágenes y orientación de fotografías por producto.
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- No elimina ni modifica las fotografías principales ya guardadas.

alter table public.aj_public_catalog
  add column if not exists image_gallery jsonb not null default '[]'::jsonb,
  add column if not exists image_rotation smallint not null default 0;

alter table public.aj_public_catalog
  drop constraint if exists aj_public_catalog_image_gallery_is_array;

alter table public.aj_public_catalog
  add constraint aj_public_catalog_image_gallery_is_array
  check (jsonb_typeof(image_gallery) = 'array');

alter table public.aj_public_catalog
  drop constraint if exists aj_public_catalog_image_rotation_valid;

alter table public.aj_public_catalog
  add constraint aj_public_catalog_image_rotation_valid
  check (image_rotation between 0 and 359);

-- La tienda puede leer únicamente las nuevas imágenes públicas y su orientación.
grant select (image_gallery, image_rotation)
  on public.aj_public_catalog to anon;

-- La cuenta autenticada conserva los permisos de administración existentes.
grant select, insert, update, delete
  on public.aj_public_catalog to authenticated;
