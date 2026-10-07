# Configuración de red — Lubricantes Arca

Guía para que los celulares y otras PCs puedan conectarse a la API de la PC del
negocio, tanto **dentro** de la red local como **fuera** (por Internet).

> **Regla de oro:** MySQL **nunca** se abre a Internet. Solo se expone la API
> de Python (puerto **8000**).

---

## 1. Datos de referencia

| Dato | Valor |
|---|---|
| Puerto de la API | **8000** (TCP) |
| Escucha | `0.0.0.0` (toda la red local) |
| Endpoint de salud | `http://IP:8000/health` |
| URL local (celular, misma Wi-Fi) | `http://192.168.x.x:8000` |
| URL en la PC servidor | `http://127.0.0.1:8000` |

---

## 2. IP local de la PC

Necesitás conocer la **IP local** de la PC del negocio. Desde la ventana de la
API (o con `start_server.bat`) se muestra:

```
Escuchando en:  0.0.0.0:8000
Para celulares: http://192.168.1.8:8000
```

También podés verla con:

```bat
ipconfig
```

Buscá la dirección `IPv4` del adaptador Wi-Fi/Ethernet (en esta PC actualmente
es `192.168.1.8`).

### IP local fija / reservada (recomendado)
Para que la IP no cambie (así los celulares no se desconfiguran):

1. Entrá al router del negocio (normalmente `http://192.168.1.1` o `192.168.0.1`).
2. Buscá **DHCP → Reserva de dirección (DHCP Reservation / Static Lease)**.
3. Asigná siempre la misma IP a la **MAC** de la PC del negocio.
4. Guardá y reiniciá el router si es necesario.

---

## 3. Firewall de Windows (permitir el puerto TCP 8000)

Para que los celulares lleguen a la API dentro de la red local:

1. Abrí **Panel de control → Firewall de Windows Defender → Configuración
   avanzada**.
2. Click en **Reglas de entrada → Nueva regla...**.
3. Tipo de regla: **Puerto** → Siguiente.
4. **TCP** y **Puertos locales específicos:** `8000` → Siguiente.
5. **Permitir la conexión** → Siguiente.
6. Marcá **Dominio**, **Privada** (y **Pública** solo si lo necesitás para
   Internet) → Siguiente.
7. Nombre: `Lubricantes Arca API` → Finalizar.

> También podés habilitarla desde la consola (como administrador):
>
> ```bat
> netsh advfirewall firewall add rule name="Lubricantes Arca API" dir=in action=allow protocol=TCP localport=8000
> ```

> ⚠️ **NO** abras el puerto **3306** (MySQL). MySQL es solo local (`127.0.0.1`).

---

## 4. Prueba desde el celular (misma red Wi-Fi)

1. Conectá el celular a la **misma red Wi-Fi** que la PC del negocio.
2. Asegurate de que la API esté corriendo.
3. En el navegador del celular abrí:

   ```
   http://192.168.1.8:8000/health
   ```

4. Debe responder: `{"status":"ok"}`.
5. En la app, en **Configuración → Servidor**, poné `192.168.1.8` y el puerto `8000`
   y pulsá **"Probar conexión"**.

---

## 5. Acceso desde fuera del negocio (Internet)

Para usar la app desde Datos móviles u otra ubicación hay que publicar la API
hacia Internet **de forma segura**.

### 5.1 IP pública
- Sabé tu **IP pública** preguntando "cuál es mi IP" desde el negocio.
- Si tu proveedor la cambia seguido, usá **DDNS** (Sección 5.4).

### 5.2 Port Forwarding / NAT en el router
Redirige el puerto externo al puerto interno de la API:

| Campo | Valor |
|---|---|
| Servicio/Nombre | Lubricantes Arca |
| Puerto externo (WAN) | 8000 (o el que prefieras) |
| IP interna (LAN) | IP local de la PC (ej. `192.168.1.100`) |
| Puerto interno | 8000 |
| Protocolo | TCP |

> Tras configurar el reenvío, probá desde un celular con datos móviles:
> `http://IP_PUBLICA:8000/health`.

### 5.3 HTTPS/SSL (recomendado para producción)
Exponer la API con HTTP plano no es seguro. Opciones:

1. **Terminación HTTPS con un proxy** (recomendado):
   - Poner un **reverse proxy** con HTTPS (por ejemplo Caddy, Nginx o
     Cloudflare Tunnel) delante de la API.
   - El proxy escucha en `443` y reenvía a `http://127.0.0.1:8000`.
   - La app apunta a `https://DOMINIO` (sin puerto).
2. **Cloudflare Tunnel** (sencillo, sin abrir puertos del router):
   - Da un `https://...trycloudflare.com` o un dominio propio.
   - No hay que abrir el router ni exponer la IP directamente.

> En cualquiera de las dos opciones, en la app se configura
> **Configuración → Servidor**:
> 1. En **Dirección del servidor** poné el dominio (ej. `app.tudominio.com` o
>    `...trycloudflare.com`), **sin** `http://` ni `https://`.
> 2. En **Puerto** poné `443` (HTTPS) o dejá `8000` si el proxy/túnel entrega
>    en ese puerto.
> 3. Activá el interruptor **"Usar HTTPS (para ver desde Internet)"**.
> 4. Pulsá **"Probar conexión"** → debe mostrar 🟢 Conectado.
>
> Para LAN (misma Wi-Fi) dejá el interruptor **apagado** y usá la IP local
> con puerto `8000` (ej. `192.168.1.100:8000`).

### 5.4 DDNS (cuando la IP pública cambia)
- Registrá un nombre en un proveedor de DDNS (ej. NO-IP, DuckDNS).
- El router o un pequeño programa actualizan el nombre con tu IP.
- La app usaría `https://tu-nombre.ddns.net`.

### 5.5 Dominio (opcional)
- Comprá un dominio y apuntá un registro **A** a tu IP pública (o usá el
  tunnel de la Sección 5.3).
- Con HTTPS configurado, la app apunta a `https://tudominio.com`.

---

## 6. Qué hago yo manualmente (no automático)

Cline **no** configura nada del router ni de tu conexión. Lo hacés vos:

- Reservar la IP local de la PC.
- Configurar el **port forwarding** del puerto 8000.
- Configurar **DDNS** y/o **dominio** y **HTTPS**.
- Abrir el puerto en el **Firewall de Windows**.

---

## 7. Resumen de la ruta de conexión

```
DENTRO del negocio:
   Celular → Wi-Fi → IP local PC (192.168.x.x:8000) → Python API → MySQL

FUERA del negocio (Internet):
   Celular → Internet → IP pública/dominio → Router (port forwarding)
           → PC Windows → Python API → MySQL
```