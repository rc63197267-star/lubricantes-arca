# Lubricantes Arca — Sistema cliente‑servidor

Sistema de gestión para Lubricantes Arca (ventas, inventario, clientes,
proveedores, stock e imágenes) con arquitectura cliente‑servidor en red local
y con soporte para uso remoto vía Internet.

## Arquitectura

```
            🌐 INTERNET
                 │
        📡 ROUTER DEL NEGOCIO
                 │
        🖥️  PC WINDOWS (SERVIDOR)
                 │
        ┌────────┴────────┐
        │                 │
   🐍 Python API     🗄️ MySQL (XAMPP)
   (FastAPI)          lubricantes_arca
        │
   Wi-Fi / LAN / Internet
        │
 ┌──────┼──────┐
 ↓      ↓      ↓
📱    📱     💻
Android Android Windows (Flutter)
```

**Regla de oro:** `Flutter → Python API → MySQL`. **Nunca** `Flutter → MySQL`.
MySQL permanece solo en la PC del negocio y no se expone a Internet.

## Estructura del proyecto

```
ml/
├── lib/                     # Código Flutter (app Android + Windows)
│   ├── main.dart
│   ├── services/
│   │   ├── api_client.dart      # Todas las llamadas HTTP a la API
│   │   └── server_config.dart   # Configuración centralizada de la API (IP/puerto)
│   └── screens/...
├── python_backend/          # API Python (FastAPI + MySQL)
│   ├── api.py               # Endpoints REST
│   ├── db.py / db_config.py # Acceso a MySQL (lee .env)
│   ├── run.py               # Punto de entrada (uvicorn en 0.0.0.0)
│   ├── .env                 # Configuración (API_HOST/API_PORT + DB_*)
│   ├── requirements.txt
│   ├── LubricantesArcaAPI.spec  # Spec de PyInstaller (→ api.exe)
│   └── build_backend.bat    # Compila api.exe en Windows
├── windows/                 # Runner nativo de Flutter para Windows
├── android/                 # Proyecto Android de Flutter
├── installer/
│   └── LubricantesArca.iss  # Instalador (Inno Setup) → LubricantesArca-Setup.exe
├── logo/logo.ico            # Icono de la app y del servidor
├── start_server.bat         # Inicia el backend sin instancias duplicadas
├── INSTALACION_WINDOWS.md   # Instalación paso a paso
└── CONFIGURACION_RED.md     # Red local, firewall, port forwarding, DDNS, HTTPS
```

## Configuración centralizada

- **Backend** (archivos `.env` y `.env.example`):
  ```
  API_HOST=0.0.0.0     # escucha en toda la red local
  API_PORT=8000        # puerto de la API

  DB_HOST=127.0.0.1
  DB_PORT=3306
  DB_USER=root
  DB_PASSWORD=
  DB_NAME=lubricantes_arca
  ```
- **App Flutter**: configuración central en `lib/services/server_config.dart`.
  - Android (celular): por defecto apunta a `192.168.1.100:8000` (la IP local de la PC).
  - Windows/escritorio: por defecto `127.0.0.1:8000` (la propia PC servidor).
  - El usuario **admin** puede cambiarla desde **Configuración → Servidor**
    (se guarda de forma persistente en la carpeta de datos de la app).

## Endpoint de salud

- `GET /health` → `{"status": "ok"}`
- `GET /api/health` → `{"status": "ok"}` (alias)

La app lo usa con el botón **“Probar conexión”**.

## Inicio rápido (desarrollo)

```bash
# Backend
cd python_backend
python run.py                 # escucha en 0.0.0.0:8000

# App (desde la raíz del proyecto)
flutter run -d windows
flutter run -d <dispositivo-android>
```

## Compilación para producción

```bash
# APK Android
flutter build apk --release

# Windows (genera build\windows\x64\runner\Release\LubricantesArca.exe)
flutter build windows --release

# Backend como ejecutable (en Windows)
cd python_backend
build_backend.bat             # → dist\api.exe

# Instalador de Windows (requiere Inno Setup 6)
#   Compila el .iss que está en installer/  →  LubricantesArca-Setup.exe
```

Ver **INSTALACION_WINDOWS.md** y **CONFIGURACION_RED.md** para el despliegue
en la PC del negocio.
