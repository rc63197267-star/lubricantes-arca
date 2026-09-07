"""Migra imágenes locales de productos a Supabase Storage.

Uso desde la raíz del proyecto:
    python python_backend/migrate_images_to_storage.py

Requiere SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY y
SUPABASE_STORAGE_BUCKET=product-images en el entorno. No elimina los archivos
locales: primero sube cada archivo y solo actualiza la URL de la fila si la
subida fue exitosa.
"""

import mimetypes
import os
import urllib.error
import urllib.request
from pathlib import Path

import psycopg

from db_config import DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_SSLMODE


BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"
SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
BUCKET = os.getenv("SUPABASE_STORAGE_BUCKET", "product-images")


def upload(path: Path) -> str:
    object_name = path.name
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{object_name}"
    content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    request = urllib.request.Request(
        url,
        data=path.read_bytes(),
        method="POST",
        headers={
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "apikey": SUPABASE_KEY,
            "Content-Type": content_type,
            "x-upsert": "true",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            if response.status not in (200, 201):
                raise RuntimeError(f"HTTP {response.status}")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:300]
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc
    return f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{object_name}"


def main() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("Faltan SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY")
    if not UPLOAD_DIR.exists():
        raise SystemExit(f"No existe la carpeta {UPLOAD_DIR}")

    with psycopg.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        dbname=DB_NAME,
        sslmode=DB_SSLMODE,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id_producto, imagen FROM productos WHERE imagen IS NOT NULL")
            rows = cur.fetchall()
            migrated = 0
            skipped = 0
            for product_id, image in rows:
                if not isinstance(image, str) or image.startswith("http://") or image.startswith("https://"):
                    skipped += 1
                    continue
                filename = Path(image).name
                local_path = UPLOAD_DIR / filename
                if not local_path.is_file():
                    print(f"OMITIDA producto={product_id}: no existe {local_path}")
                    continue
                public_url = upload(local_path)
                cur.execute(
                    "UPDATE productos SET imagen = %s WHERE id_producto = %s",
                    (public_url, product_id),
                )
                migrated += 1
                print(f"OK producto={product_id}: {public_url}")
            conn.commit()
    print(f"Migradas: {migrated}; ya remotas/omitidas: {skipped}")


if __name__ == "__main__":
    main()