# Despliegue permanente de Lubricantes Arca en Render

Este proyecto ya incluye `Dockerfile` y `render.yaml` para publicar la API
Python en Render y mantener Supabase como base de datos.

## 1. Preparar el repositorio

Sube este proyecto a un repositorio privado de GitHub/GitLab. El archivo
`python_backend/.env` está excluido por `.gitignore`: **no lo subas**.

Si la contraseña de Supabase fue compartida, cámbiala antes de desplegarla.

## 2. Crear el servicio

1. Entra en <https://dashboard.render.com> y crea una cuenta o inicia sesión.
2. Pulsa **New → Blueprint**.
3. Selecciona el repositorio del proyecto.
4. Render detectará `/render.yaml` y creará el servicio
   `lubricantes-arca-api`.
5. En las variables marcadas como `sync: false`, introduce los valores de
   Supabase:

   En **Supabase → Connect → Session pooler** copia los valores exactos de la
   cadena de conexión. Para Render debe ser el **Session pooler**, no la
   conexión directa `db.<project-ref>.supabase.co`, porque Render puede usar
   una red IPv4 y la conexión directa de proyectos sin IPv4 add-on usa IPv6.

   ```text
   DB_HOST=aws-0-us-east-2.pooler.supabase.com
   DB_PORT=5432
   DB_USER=postgres.yxnmcpcycejkoiriisag
   DB_PASSWORD=<contraseña nueva de Supabase>
   DB_NAME=postgres
   DB_SSLMODE=require
   SUPABASE_URL=https://yxnmcpcycejkoiriisag.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
   SUPABASE_STORAGE_BUCKET=product-images
   ```

6. Pulsa **Apply** y espera a que el despliegue termine.

Antes de publicar, crea en Supabase Storage un bucket llamado
`product-images` y márcalo como **public**. La `SUPABASE_SERVICE_ROLE_KEY` es
un secreto: configúrala solo en Render, nunca en Flutter, GitHub o este
repositorio.

## 3. Comprobar el servicio

Render mostrará una URL similar a:

```text
https://lubricantes-arca-api.onrender.com
```

Comprueba:

```text
https://lubricantes-arca-api.onrender.com/health
```

Debe devolver:

```json
{"status":"ok"}
```

También se puede comprobar el acceso a Supabase con:

```text
https://lubricantes-arca-api.onrender.com/products?limit=1
```

## 4. Configurar Flutter

En la app, en **Configuración → Servidor**:

```text
Dirección: lubricantes-arca-api.onrender.com
Puerto: 443
Usar HTTPS: activado
```

Guarda la configuración y pulsa **Probar conexión**.

## Nota sobre las imágenes

Las imágenes nuevas se guardan en Supabase Storage cuando están configuradas
las variables anteriores. Para migrar las imágenes existentes, configura esas
variables también en el entorno local y ejecuta:

```bash
python python_backend/migrate_images_to_storage.py
```

El script no borra los archivos locales y solo actualiza cada fila después de
subir correctamente su imagen.

## Prueba local del contenedor

Desde la raíz del proyecto se puede comprobar la imagen sin incluir secretos:

```bash
docker build -t lubricantes-arca-api .
docker run --rm -p 8000:8000 --env-file python_backend/.env lubricantes-arca-api
```

Luego abre `http://127.0.0.1:8000/health`.

## Nota sobre el plan gratuito

Render puede suspender servicios gratuitos cuando no reciben tráfico. El
primer acceso después de una pausa puede tardar unos segundos. Para operación
continua sin pausas se necesita un plan de pago.