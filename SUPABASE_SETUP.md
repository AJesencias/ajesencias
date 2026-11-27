# Configuración de sincronización segura para AJ Esencias

El módulo actual de Gestión Comercial funciona en el navegador y ofrece respaldo/restauración JSON. Para sincronizar datos privados entre teléfonos y computadoras, AJ Esencias necesita un proyecto Supabase propio.

## 1. Crear el proyecto
1. Crear un proyecto en https://supabase.com/ con una cuenta controlada por los propietarios de AJ Esencias.
2. Elegir una contraseña de base de datos fuerte y guardarla en un gestor de contraseñas.
3. En Authentication > Providers, mantener habilitado Email y configurar confirmación de correo.
4. En Authentication > URL Configuration, agregar el dominio publicado de AJ Esencias como Site URL y Redirect URL.

## 2. Crear las tablas protegidas
1. Abrir SQL Editor en Supabase.
2. Copiar y ejecutar el contenido de `supabase/schema.sql`.
3. Verificar que las cinco tablas `aj_products`, `aj_sales`, `aj_sale_payments`, `aj_expenses` y `aj_purchases` tengan Row Level Security (RLS) habilitado.

Cada registro tiene `owner_id` y las políticas solo permiten a un usuario autenticado consultar o modificar sus propios registros. No desactivar RLS.

## 3. Credenciales
En Project Settings > API, copiar:
- Project URL.
- Publishable key (o anon key heredada).

La clave pública/publishable puede utilizarse en el navegador únicamente porque las políticas RLS protegen las tablas. **Nunca** colocar la service_role key, una contraseña de base de datos ni tokens privados en el HTML, GitHub o mensajes.

## 4. Restringir la administración a cuentas autorizadas
1. En Supabase > SQL Editor, ejecutar también `supabase/migrations/20261127_aj_admin_allowlist.sql`.
2. Esta migración activa RLS y reemplaza las políticas de las tablas privadas para que solo la cuenta cuyo correo esté en la lista autorizada pueda leer o modificar datos. Actualmente la lista contiene `ambardilone06@gmail.com`.
3. No añadas correos que no sean de los propietarios. Para incorporar a Jeremy más adelante, agrega su correo verificado a la lista dentro de `aj_is_authorized_admin()` y vuelve a ejecutar la migración.
4. Las fotografías de productos mantienen lectura pública para que la tienda pueda mostrarlas; la carga, sustitución y eliminación quedan limitadas a la cuenta autorizada.

## 5. Conectar el sitio
La conexión de inicio de sesión y sincronización debe añadirse al frontend usando esas dos credenciales. No está activada todavía: no se debe asumir que el sistema ya sincroniza entre dispositivos. Para completar la conexión hacen falta el Project URL y la publishable/anon key del proyecto que cree el propietario.

## 6. Migración de datos
Antes de activar la nube:
1. Abrir Gestión Comercial en el sitio que contiene los datos actuales.
2. Pulsar **Respaldar datos** y guardar el archivo JSON en un lugar privado.
3. Probar la restauración del archivo en un navegador secundario.
4. Solo después de validar el respaldo, importar productos y registros a Supabase.

No subir el archivo de respaldo a un repositorio público: puede contener nombres de clientes, ventas, saldos y otros datos comerciales.

## Alcance actual
- Registro de ventas con validación de existencia y descuento de inventario.
- Costos unitarios, precios y existencias editables.
- Gastos por categoría.
- Compras de mercancía con actualización de existencias y costo promedio ponderado.
- Abonos y cuentas por cobrar.
- Resumen de ventas, costo de ventas, ganancia bruta y resultado estimado.
- Respaldo y restauración manual en JSON.

El resultado es gerencial y estimado; no sustituye contabilidad formal, conciliación bancaria, comprobantes fiscales ni declaraciones DGII.
