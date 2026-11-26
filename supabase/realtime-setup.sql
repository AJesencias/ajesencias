-- Habilitar cambios Postgres en tiempo real para la tabla de respaldo de AJ Esencias.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'aj_business_data'
  ) then
    alter publication supabase_realtime add table public.aj_business_data;
  end if;
end $$;
