2626# Ver la app desde Internet (cualquier lugar) — Cloudflare Tunnel

Esta guía es para poder abrir **Lubricantes Arca** desde **fuera** del negocio
(otra ciudad, otra red, o con datos del celular).

> **Regla de oro:** solo se publica la API (puerto **8000**) a través de un
> túnel HTTPS seguro. **Nunca** se publica MySQL (puerto `3306`).

---

## ¿Por qué Cloudflare Tunnel?

- ✅ **Gratis** y sin tocar el router (sin "port forwarding").
- ✅ Te da una dirección **HTTPS** segura, tipo `https://tu-negocio.trycloudflare.com`
  o `https://inventario.tudominio.com`.
- ✅ No se expone tu IP pública ni tu red directamente.

**Requisito:** la PC del negocio debe estar **encendida**, con la API
(`start_server.bat`) y **XAMPP/MySQL** corriendo.

---

## Opción A — Rápida (para probar YA, sin cuenta)

Te da una URL que **cambia cada vez** que reiniciás la PC. Útil para probar.

### 1. Instalar `cloudflared` en la PC (Windows)

Abrí **PowerShell** y ejecutá:

```powershell
winget install --id Cloudflare.cloudflared
```

(Si no tenés `winget`, descargalo de
https://github.com/cloudflare/cloudflared/releases → `cloudflared-windows-amd64.exe`,
renombralo a `cloudflared.exe` y dejala en una carpeta conocida.)

### 2. Crear el túnel

En **PowerShell** o **CMD** (con la API ya corriendo en `127.0.0.1:8000`):

```powershell
cloudflared tunnel --url http://127.0.0.1:8000
```

Te va a mostrar algo como:

```
Your quick Tunnel has been created! Visit it at:
https://xxxx-yyyy-zzzz.trycloudflare.com
```

### 3. Configurar el celular con esa URL

1. En la app → **Configurar servidor** (pantalla de login) o
   **Configuración → Servidor** (dentro).
2. **Dirección:** `xxxx-yyyy-zzzz.trycloudflare.com` (sin `https://`).
3. **Puerto:** `443`.
4. **Usar HTTPS:** ✅ activado.
5. **Probar** → 🟢 Conectado → **Guardar**.

⚠️ Esta URL cambia al reiniciar el túnel. Para algo fijo, usá la **Opción B**.

---

## Opción B — Permanente (recomendada para el negocio)

URL fija, tipo `https://inventario.tudominio.com`. Requiere una cuenta gratis
de Cloudflare y un dominio (puede ser uno barato o uno que ya tengas).

### 1. Prepara tu dominio en Cloudflare
1. Creá una cuenta en https://dash.cloudflare.com (gratis).
2. Agregá tu dominio a Cloudflare (o comprá uno nuevo).
3. Si el dominio ya existía, cambiá los **nameservers** de tu dominio a los que
   te indica Cloudflare (te lo explica el propio panel).

### 2. Instalar `cloudflared`
Igual que en la Opción A: `winget install --id Cloudflare.cloudflared`.

### 3. Conectar `cloudflared` con tu cuenta
```powershell
cloudflared tunnel login
```
Se abre el navegador → elegí tu dominio → **Authorize**.

### 4. Crear el túnel
```powershell
cloudflared tunnel create lubricantes-arca
```
Anotá el **Tunnel ID** que aparece (ej. `a1b2c3d4-...-xxxx`).

### 5. Crear el archivo de configuración
Crea el archivo en `C:\Users\TU_USUARIO\.cloudflared\config.yml`:

```yaml
tunnel: AQUI-VA-EL-TUNNEL-ID
credentials-file: C:\Users\TU_USUARIO\.cloudflared\AQUI-VA-EL-TUNNEL-ID.json

ingress:
  - hostname: inventario.tudominio.com
    service: http://127.0.0.1:8000
  - service: http_status:404
```

(Las comillas NO son necesarias si no hay espacios.)

### 6. Publicar la URL (DNS)
```powershell
cloudflared tunnel route dns lubricantes-arca inventario.tudominio.com
```

### 7. Ejecutar el túnel
```powershell
cloudflared tunnel run lubricantes-arca
```

Probá desde el celular (con datos móviles):
`https://inventario.tudominio.com/health` → debe responder `{"status":"ok"}`.

### 8. Que arranque automáticamente con Windows
```powershell
cloudflared service install
```
A partir de ahora, el túnel arranca solo cuando se enciende la PC.

---

## Configurar la app para Internet (resumen)

En **Configuración → Servidor** (o **Configurar servidor** en el login):

| Campo | Valor |
|---|---|
| Dirección del servidor | `inventario.tudominio.com` (o el `xxx.trycloudflare.com`) |
| Puerto | `443` |
| Usar HTTPS | ✅ Activado |

Luego **Probar conexión** → 🟢 Conectado → **Guardar**.

---

## Problemas comunes

| Problema | Solución |
|---|---|
| "No se pudo conectar" fuera del negocio | La PC está apagada o `cloudflared` no corre. Encendé la PC y ejecutá `cloudflared tunnel run ...` (o el servicio). |
| La URL rápida dejó de andar | Cambió al reiniciar el túnel. Usá la nueva URL o pasá a la Opción B. |
| `cloudflared` no se reconoce | Reiniciá la terminal, o usá la ruta completa al `.exe`. |
| Lentitud | Es normal el primer acceso; la API no es pesada. |
| Quiero mayor seguridad | Cloudflare ya da HTTPS; además podés agregar autenticación con Cloudflare Access, pero no es obligatorio para empezar. |