import base64
import mimetypes
import os
import urllib.error
import urllib.request
import uuid

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from typing import Optional, List

from db import fetch_products, fetch_clients, create_product, fetch_suppliers, create_supplier, fetch_sales, create_sale, create_client, fetch_movimientos, create_movimiento, fetch_categorias, create_categoria, update_product, delete_product, verify_login, fetch_usuarios, create_usuario

app = FastAPI(title="Lubricantes Arca API")


@app.get("/health", response_model=dict)
def health():
    return {"status": "ok"}


@app.get("/api/health", response_model=dict)
def api_health():
    """Alias para compatibilidad con el endpoint documentado (GET /api/health)."""
    return {"status": "ok"}

# Allow local testing from Flutter (adjust origins for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://127.0.0.1", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_STORAGE_BUCKET = os.getenv("SUPABASE_STORAGE_BUCKET", "product-images")


def _upload_to_supabase_storage(raw: bytes, filename: str, content_type: str) -> str:
    """Sube una imagen al bucket público de Supabase Storage.

    La service role key solo se lee en el servidor y nunca se devuelve al
    cliente. Debe configurarse como secreto en Render, no en Flutter.
    """
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise RuntimeError("Supabase Storage no está configurado")

    object_path = f"{uuid.uuid4().hex}-{filename}"
    url = f"{SUPABASE_URL}/storage/v1/object/{SUPABASE_STORAGE_BUCKET}/{object_path}"
    request = urllib.request.Request(
        url,
        data=raw,
        method="POST",
        headers={
            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
            "apikey": SUPABASE_SERVICE_ROLE_KEY,
            "Content-Type": content_type,
            "x-upsert": "true",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            if response.status not in (200, 201):
                raise RuntimeError(f"Supabase Storage respondió HTTP {response.status}")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:300]
        raise RuntimeError(
            f"Error subiendo imagen a Supabase Storage ({exc.code}): {detail}"
        ) from exc
    return f"{SUPABASE_URL}/storage/v1/object/public/{SUPABASE_STORAGE_BUCKET}/{object_path}"


class UploadIn(BaseModel):
    filename: Optional[str] = None
    data: str


class LoginIn(BaseModel):
    usuario: str = Field(..., example="admin")
    contraseña: str = Field(..., example="123456")


class UsuarioIn(BaseModel):
    nombre: str = Field(..., example="Juan Vendedor")
    usuario: str = Field(..., example="juan")
    contraseña: str = Field("123456789")
    rol: Optional[str] = Field("VENDEDOR")


class ProductIn(BaseModel):
    codigo: Optional[str] = Field(None, example="7841234567890")
    id_categoria: Optional[int] = Field(1)
    id_proveedor: Optional[int] = Field(1)
    nombre: str = Field(..., example="Aceite 15W-40 1L")
    marca: Optional[str] = Field(None, example="Shell")
    precio_compra: Optional[float] = Field(0.0)
    precio_venta: Optional[float] = Field(0.0)
    stock_actual: Optional[int] = Field(0)
    stock_minimo: Optional[int] = Field(0)
    estado: Optional[str] = Field("ACTIVO")
    imagen: Optional[str] = Field(None)


class SupplierIn(BaseModel):
    nombre: str = Field(..., example="Proveedor Automotriz S.A.")
    telefono: Optional[str] = Field(None, example="70000000")
    correo: Optional[str] = Field(None, example="proveedor@gmail.com")
    direccion: Optional[str] = Field(None, example="La Paz - Bolivia")
    estado: Optional[str] = Field("ACTIVO")


class ClientIn(BaseModel):
    nombre: str = Field(..., example="Juan Perez")
    telefono: Optional[str] = Field(None, example="70000000")
    correo: Optional[str] = Field(None, example="juan@gmail.com")
    direccion: Optional[str] = Field(None, example="Santa Cruz - Bolivia")
    estado: Optional[str] = Field("ACTIVO")


class CategoriaIn(BaseModel):
    nombre: str = Field(..., example="Aceites")
    descripcion: Optional[str] = Field(None, example="Aceites y lubricantes para vehículos")
    estado: Optional[str] = Field("ACTIVO")


class MovimientoIn(BaseModel):
    id_producto: int
    tipo_movimiento: str = Field("AJUSTE", example="ENTRADA")
    cantidad: int = Field(..., gt=0)
    motivo: Optional[str] = Field(None, example="Producto dañado")
    observacion: Optional[str] = Field(None)


@app.get("/products", response_model=List[dict])
def get_products(limit: int = 50):
    try:
        return fetch_products(limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/clients", response_model=List[dict])
def get_clients(limit: int = 50):
    try:
        return fetch_clients(limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/clients", response_model=dict)
def post_client(payload: ClientIn):
    try:
        new_id = create_client(payload.dict())
        return {"id_cliente": new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/suppliers", response_model=List[dict])
def get_suppliers(limit: int = 50):
    try:
        return fetch_suppliers(limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/suppliers", response_model=dict)
def post_supplier(payload: SupplierIn):
    try:
        new_id = create_supplier(payload.dict())
        return {"id_proveedor": new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/products", response_model=dict)
def post_product(payload: ProductIn):
    try:
        new_id = create_product(payload.dict())
        return {"id_producto": new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/products/{id_producto}", response_model=dict)
def put_product(id_producto: int, payload: ProductIn):
    try:
        rows = update_product(id_producto, payload.dict())
        if rows == 0:
            raise HTTPException(status_code=404, detail="Producto no encontrado")
        return {"id_producto": id_producto}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/products/{id_producto}", response_model=dict)
def del_product(id_producto: int):
    try:
        rows = delete_product(id_producto)
        if rows == 0:
            raise HTTPException(status_code=404, detail="Producto no encontrado")
        return {"id_producto": id_producto, "eliminado": True}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class SaleItem(BaseModel):
    id_producto: int
    cantidad: int = Field(..., gt=0)
    precio_unitario: float = Field(..., gt=0)


class SaleIn(BaseModel):
    id_cliente: int
    id_usuario: Optional[int] = 1
    metodo_pago: Optional[str] = "EFECTIVO"
    descuento: float = Field(0, ge=0)
    monto_recibido: float = Field(0, ge=0)
    total: float
    items: List[SaleItem]


@app.get("/sales", response_model=List[dict])
def get_sales(limit: int = 50):
    try:
        return fetch_sales(limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/sales", response_model=dict)
def post_sale(payload: SaleIn):
    try:
        new_id = create_sale(payload.dict())
        return {"id_venta": new_id}
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/movimientos", response_model=List[dict])
def get_movimientos(limit: int = 100):
    try:
        return fetch_movimientos(limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/movimientos", response_model=dict)
def post_movimiento(payload: MovimientoIn):
    try:
        new_id = create_movimiento(payload.dict())
        return {"id_movimiento": new_id}
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/categorias", response_model=List[dict])
def get_categorias(limit: int = 100):
    try:
        return fetch_categorias(limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/categorias", response_model=dict)
def post_categoria(payload: CategoriaIn):
    try:
        new_id = create_categoria(payload.dict())
        return {"id_categoria": new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/upload", response_model=dict)
def upload_image(payload: UploadIn):
    try:
        raw = base64.b64decode(payload.data, validate=True)
        if not raw:
            raise ValueError("La imagen está vacía")
        ext = os.path.splitext(payload.filename or "")[-1].lower()
        if ext not in [".jpg", ".jpeg", ".png", ".gif", ".webp"]:
            ext = ".jpg"
        fname = f"{uuid.uuid4().hex}{ext}"
        content_type = mimetypes.types_map.get(ext, "image/jpeg")

        if SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY:
            return {"url": _upload_to_supabase_storage(raw, fname, content_type)}

        # Compatibilidad para desarrollo local hasta configurar Storage.
        with open(os.path.join(UPLOAD_DIR, fname), "wb") as f:
            f.write(raw)
        return {"url": f"/uploads/{fname}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/login", response_model=dict)
def login(payload: LoginIn):
    try:
        user = verify_login(payload.usuario, payload.contraseña)
        if not user:
            raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos")
        return user
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/usuarios", response_model=List[dict])
def get_usuarios(limit: int = 100):
    try:
        return fetch_usuarios(limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/usuarios", response_model=dict)
def post_usuario(payload: UsuarioIn):
    try:
        new_id = create_usuario(payload.dict())
        return {"id_usuario": new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
