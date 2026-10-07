# Instalación en Windows — Lubricantes Arca

Este documento explica cómo dejar funcionando **Lubricantes Arca** en la PC del
negocio:

- La PC Windows actúa como **servidor principal** (Python API + MySQL/XAMPP).
- Los celulares (Android) y otras PCs se conectan a esa PC por Wi-Fi/local o por
  Internet.

> **Importante:** la PC del negocio debe quedarse **encendida** para que los
> celulares y otras PCs puedan usar el sistema.

---

## 1. Lo que hago YO (instalación de XAMPP y la base de datos)

No es necesario un instalador de XAMPP. Se hace **una sola vez, de forma manual**:

1. Instalar **XAMPP** en la PC del negocio.
2. Iniciar **Apache** y **MySQL/MariaDB** desde el panel de XAMPP.
3. Crear la base de datos **`lubricantes_arca`** (por ejemplo desde phpMyAdmin).
4. Exportar la base de datos actual desde mi PC (`phpMyAdmin → Exportar`) y
   generar un archivo `.sql`.
5. Importar ese `.sql` en la PC del cliente (`phpMyAdmin → Importar`) en la base
   `lubricantes_arca`.
6. Verificar tablas y datos.
7. Si corresponde, configurar usuario/contraseña de MySQL.

> MySQL queda **solo** en la PC del negocio. **Nunca** se abre a Internet.
> La app siempre pasa por la API de Python.

---

## 2. Lo que hace el instalador (LubricantesArca-Setup.exe)

El instalador **NO instala XAMPP ni MySQL**. Solo instala:

| Componente | Detalle |
|---|---|
| Aplicación Flutter Windows | `LubricantesArca.exe` + archivos de la app |
| Backend Python compilado | `backend/api.exe` |
| Configuración del backend | `backend\.env` (IP/puerto de la API + datos de MySQL) |
| Script de inicio | `start_server.bat` (arranca la API sin abrir duplicados) |
| Logo | `logo.ico` |
| Accesos directos | "Lubricantes Arca" y "Lubricantes Arca - Iniciar Servidor" en el escritorio |

El instalador también **ofrece** la opción:

> ✅ **Iniciar el servidor (API) automáticamente al encender Windows**

Si se marca, la API arranca sola cuando se enciende la PC (sin abrir una segunda
instancia si ya está corriendo).

---

## 3. Pasos de instalación (orden recomendado)

### Paso 1 — Preparar la base de datos (yo)
Ejecutar la Sección 1 (XAMPP + MySQL + importación del `.sql`).

### Paso 2 — Ajustar `backend\.env`
Después de instalar (o antes de compilar el instalador) hay que verificar el
archivo `python_backend\.env`. Debe coincidir con los datos reales de MySQL:

```
API_HOST=0.0.0.0
API_PORT=8000

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=TU_CONTRASEÑA_MYSQL
DB_NAME=lubricantes_arca
```

> Si MySQL quedó sin contraseña, dejar `DB_PASSWORD=` vacío.

### Paso 3 — Compilar el instalador (en mi PC de trabajo)

En una PC Windows con **Flutter**, **Python** e **Inno Setup 6**:

```bat
:: 3.1 Compilar la app Windows
flutter build windows --release

:: 3.2 Compilar el backend Python (genera python_backend\dist\api.exe)
cd python_backend
build_backend.bat
cd ..

:: 3.3 Compilar el instalador (Inno Setup)
::     Abrir installer\LubricantesArca.iss en Inno Setup y compilar
::     Se genera: LubricantesArca-Setup.exe
```

Luego copiar el **APK** (`flutter build apk --release`) y el
**LubricantesArca-Setup.exe** para la entrega.

### Paso 4 — Instalar en la PC del negocio
1. Ejecutar `LubricantesArca-Setup.exe`.
2. Marcar **"Iniciar el servidor (API) automáticamente al encender Windows"**.
3. Finalizar la instalación.
4. Confirmar que XAMPP/MySQL esté iniciado.

### Paso 5 — Abrir el puerto de la API en el Firewall
Permitir el puerto **TCP 8000** para entradas en la red privada (ver
**CONFIGURACION_RED.md**). Esto permite que los celulares se conecten por Wi-Fi.

### Paso 6 — Primer inicio
1. Doble clic en **"Lubricantes Arca"** (escritorio).
2. Iniciar sesión con el usuario **admin**.
3. Ir a **Configuración → Servidor**.
4. Verificar la IP y el puerto y pulsar **"Probar conexión"**.
   - Debe mostrar: 🟢 Conectado (`status: ok`).
5. En cada **celular**, abrir la app y en el login de admin ir a
   **Configuración → Servidor**, poner la **IP local de la PC** (ej. `192.168.1.100`)
   y el puerto `8000`, y pulsar **"Probar conexión"**.

---

## 4. Uso diario

- El usuario **solo** necesita abrir **"Lubricantes Arca"** del escritorio.
- La API arranca sola con Windows (si se marcó la opción en la instalación).
- Si el servidor no arrancó, usar el acceso directo
  **"Lubricantes Arca - Iniciar Servidor"**.
- Si el servidor está apagado (PC apagada o API detenida), la app muestra un
  mensaje amigable:
  > "No se pudo conectar con el servidor. Verifica que la PC esté encendida,
  > el servidor corriendo y estés en la misma red."

---

## 5. Solución de problemas

| Problema | Solución |
|---|---|
| La app dice "No se pudo conectar" | PC apagada o API detenida. Abrir `start_server.bat` y comprobar que en la consola aparece "Escuchando en 0.0.0.0:8000". |
| Las ventas no cargan datos | MySQL no está iniciado. Abrir XAMPP → iniciar MySQL. |
| El celular no conecta por Wi-Fi | Verificar que el celular esté en la misma red y que el Firewall permita el puerto TCP 8000. Ver `CONFIGURACION_RED.md`. |
| "Error de base de datos" | Revisar `backend\.env` (usuario/contraseña/nombre de BD `lubricantes_arca`). |
| Quiero detener la API | Cerrar la ventana "Lubricantes Arca - Servidor API" (o matar el proceso `api.exe` en el Administrador de tareas). |
| Quiero reiniciar la API | Detenerla y volver a ejecutar `start_server.bat`. |

---

## 6. Misma base de datos para todos

Todos los dispositivos (Android y Windows) usan **la misma base de datos**
`lubricantes_arca` a través de la API:

```
📱 Venta desde el celular → Python API → MySQL → actualiza stock
                                                  ↓
💻 Otra PC/otro celular ven el stock actualizado al instante.
```