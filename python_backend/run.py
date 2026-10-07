# -*- coding: utf-8 -*-
"""
Lubricantes Arca - Punto de entrada del servidor API.
Arranca FastAPI/Uvicorn y escucha en la red local (0.0.0.0).
Sirve tanto para ejecutar con Python como para el ejecutable (PyInstaller).

Uso:
    python run.py
"""
import os
import socket
import sys

from dotenv import load_dotenv

# Carga .env junto al ejecutable (PyInstaller) o al script (desarrollo).
if getattr(sys, 'frozen', False):
    _BASE = os.path.dirname(sys.executable)
else:
    _BASE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(_BASE, '.env'))
_local_env = os.path.join(_BASE, '.env.local')
if os.path.exists(_local_env):
    load_dotenv(_local_env, override=True)
load_dotenv()  # fallback desde el directorio de trabajo

import uvicorn  # noqa: E402

from api import app  # noqa: E402


def get_host_ip() -> list:
    """Devuelve las IPs locales de la máquina (para configurar los celulares)."""
    hostname = socket.gethostname()
    try:
        addresses = socket.gethostbyname_ex(hostname)[2]
    except Exception:
        addresses = []
    # También la IP de la puerta de enlace local
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        if ip and ip not in addresses:
            addresses.insert(0, ip)
    except Exception:
        pass
    finally:
        s.close()
    return addresses


def main():
    api_host = os.getenv("API_HOST", "0.0.0.0")
    api_port = int(os.getenv("API_PORT", "8000"))

    print("==============================================")
    print("  Lubricantes Arca - Servidor API")
    print("==============================================")
    print(f"  Escuchando en:  {api_host}:{api_port}")
    for ip in get_host_ip():
        print(f"  Para celulares:  http://{ip}:{api_port}")
    print("  (Cierra esta ventana para detener el servidor)")
    print("==============================================")
    uvicorn.run(
        app,
        host=api_host,
        port=api_port,
        reload=False,
    )


if __name__ == "__main__":
    main()