# Python backend helper (conexión a XAMPP MySQL/MariaDB)

Este pequeño backend en Python muestra cómo conectar a la base de datos `lubricantes_arca` (XAMPP) y ejecutar consultas simples.

Requisitos:
- Python 3.10+
- XAMPP con MySQL/MariaDB en ejecución y la base de datos importada (archivo `lubricantes_arca.sql` en la raíz del proyecto)

Pasos rápidos:

1. Instala dependencias (usa un virtualenv recomendado):

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r python_backend/requirements.txt
```

2. Importa la base de datos en XAMPP (phpMyAdmin o CLI). Con CLI (desde la carpeta del proyecto):

```bash
# Ajusta usuario/host si es necesario
mysql -u root -p < lubricantes_arca.sql
```

O bien usa phpMyAdmin y sube `lubricantes_arca.sql` desde la interfaz.

3. Copia y edita la configuración:

```bash
cp python_backend/.env.example python_backend/.env
# Edita python_backend/.env para poner tu contraseña si aplica
```

4. Ejecuta el ejemplo:

```bash
cd python_backend
python example_queries.py
```

5) API con FastAPI (recomendada para que Flutter consuma datos)

Instala dependencias (si no lo hiciste ya):

```bash
pip install -r python_backend/requirements.txt
```

Arranca la API (developer mode):

```bash
cd python_backend
uvicorn api:app --reload --port 8000
```

Endpoints útiles:
- `GET /products?limit=50` — lista productos
- `GET /clients?limit=50` — lista clientes
- `POST /products` — crear producto (JSON body según `ProductIn`)

Desde Flutter usa el paquete `http` o `dio` para solicitar `http://10.0.2.2:8000/products` (emulador Android) o `http://localhost:8000/products` en desktop.

Qué hace el código:
- `db_config.py` lee variables de entorno (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`).
- `db.py` contiene `get_connection()`, `fetch_products()`, `fetch_clients()` y un ejemplo `create_product()`.
- `example_queries.py` muestra cómo leer productos y clientes.

Notas:
- Si tu instalación de MySQL/MariaDB usa contraseña vacía para `root` (común en XAMPP local), deja `DB_PASSWORD` vacío.
- Ajusta `DB_PORT` si tu MySQL corre en otro puerto.
