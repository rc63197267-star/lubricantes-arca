from dotenv import load_dotenv
import os
import sys

# Buscar .env junto al ejecutable (PyInstaller) o al script (desarrollo),
# con prioridad al archivo externo sobre el empaquetado.
if getattr(sys, 'frozen', False):
    _BASE = os.path.dirname(sys.executable)
else:
    _BASE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(_BASE, '.env'))

# Configuración local opcional. Si existe .env.local, reemplaza solo los
# valores necesarios para trabajar sin depender de la nube.
_local_env = os.path.join(_BASE, '.env.local')
if os.path.exists(_local_env):
    load_dotenv(_local_env, override=True)

# Fallback: también prueba en el directorio de trabajo por si acaso.
load_dotenv()

DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
DB_PORT = int(os.getenv('DB_PORT', '3306'))
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'lubricantes_arca')
DB_SSLMODE = os.getenv('DB_SSLMODE', 'require')
