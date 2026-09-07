import psycopg
from psycopg import Error
from psycopg.errors import ForeignKeyViolation
from psycopg.rows import dict_row
from db_config import DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_SSLMODE


def get_connection():
    try:
        conn = psycopg.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            dbname=DB_NAME,
            sslmode=DB_SSLMODE,
        )
        return conn
    except Error as e:
        raise RuntimeError(f"Error conectando a la base de datos: {e}")


def fetch_products(limit=10):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute("""
            SELECT id_producto, nombre, marca, precio_compra, precio_venta,
                   stock_actual, stock_minimo, imagen
            FROM productos
            WHERE estado = 'ACTIVO'
            ORDER BY id_producto
            LIMIT %s
        """, (limit,))
        rows = cur.fetchall()
        return rows
    finally:
        cur.close()
        conn.close()


def fetch_clients(limit=50):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute("SELECT id_cliente, nombre, telefono, correo, direccion, estado FROM clientes LIMIT %s", (limit,))
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_client(data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO clientes (nombre, telefono, correo, direccion, estado)
               VALUES (%s, %s, %s, %s, %s)
               RETURNING id_cliente""",
            (
                data.get('nombre'),
                data.get('telefono'),
                data.get('correo'),
                data.get('direccion'),
                data.get('estado', 'ACTIVO'),
            ),
        )
        new_id = cur.fetchone()[0]
        conn.commit()
        return new_id
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def fetch_suppliers(limit=50):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute("SELECT id_proveedor, nombre, telefono, correo, direccion, estado FROM proveedores LIMIT %s", (limit,))
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_supplier(data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO proveedores (nombre, telefono, correo, direccion, estado)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id_proveedor
            """,
            (
                data.get('nombre'),
                data.get('telefono'),
                data.get('correo'),
                data.get('direccion'),
                data.get('estado', 'ACTIVO'),
            ),
        )
        new_id = cur.fetchone()['id_movimiento']
        conn.commit()
        return new_id
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def create_product(data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO productos (codigo, id_categoria, id_proveedor, nombre, marca, precio_compra, precio_venta, stock_actual, stock_minimo, estado, imagen)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            RETURNING id_producto
            """,
            (
                data.get('codigo'),
                data.get('id_categoria', 1),
                data.get('id_proveedor', 1),
                data.get('nombre'),
                data.get('marca'),
                data.get('precio_compra', 0.0),
                data.get('precio_venta', 0.0),
                data.get('stock_actual', 0),
                data.get('stock_minimo', 0),
                data.get('estado', 'ACTIVO'),
                data.get('imagen'),
            ),
        )
        new_id = cur.fetchone()[0]
        if (data.get('stock_actual', 0) or 0) > 0:
            cur.execute(
                """INSERT INTO stock_movimientos
                   (id_producto, tipo_movimiento, cantidad, motivo, stock_anterior, stock_nuevo, observacion)
                   VALUES (%s, 'ENTRADA', %s, %s, 0, %s, %s)""",
                (
                    new_id,
                    data.get('stock_actual', 0),
                    'Ingreso de mercadería',
                    data.get('stock_actual', 0),
                    'Entrada inicial de stock',
                ),
            )
        conn.commit()
        return new_id
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
def update_product(id_producto: int, data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """UPDATE productos SET
                 id_categoria = %s, id_proveedor = %s, nombre = %s, marca = %s,
                 precio_compra = %s, precio_venta = %s, stock_actual = %s,
                 stock_minimo = %s, imagen = %s
               WHERE id_producto = %s""",
            (
                data.get('id_categoria', 1),
                data.get('id_proveedor', 1),
                data.get('nombre'),
                data.get('marca'),
                data.get('precio_compra', 0.0),
                data.get('precio_venta', 0.0),
                data.get('stock_actual', 0),
                data.get('stock_minimo', 0),
                data.get('imagen'),
                id_producto,
            ),
        )
        conn.commit()
        return cur.rowcount
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()

def delete_product(id_producto):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM productos WHERE id_producto=%s", (id_producto,))
        rows = cur.rowcount
        conn.commit()
        return rows
    except ForeignKeyViolation:
        conn.rollback()
        cur.execute(
            "UPDATE productos SET estado = 'INACTIVO' WHERE id_producto = %s",
            (id_producto,),
        )
        rows = cur.rowcount
        conn.commit()
        return rows
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()

def fetch_sales(limit=50):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute("""
            SELECT v.id_venta, v.numero_venta, v.id_cliente, c.nombre as cliente,
                   v.fecha, v.metodo_pago, v.total, v.estado,
                   STRING_AGG(p.nombre || ' x' || dv.cantidad::text, ', ' ORDER BY dv.id_detalle_venta) AS productos
            FROM ventas v
            JOIN clientes c ON v.id_cliente = c.id_cliente
            LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
            LEFT JOIN productos p ON p.id_producto = dv.id_producto
            GROUP BY v.id_venta, v.numero_venta, v.id_cliente, c.nombre,
                     v.fecha, v.metodo_pago, v.total, v.estado
            ORDER BY v.fecha DESC
            LIMIT %s
        """, (limit,))
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_sale(data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)

        # 1) Generate numero_venta
        cur.execute("SELECT COALESCE(MAX(id_venta), 0) + 1 AS next_seq FROM ventas")
        seq = cur.fetchone()['next_seq']
        numero_venta = f"V-{seq:06d}"

        # 2) Insert venta
        cur.execute(
            """INSERT INTO ventas (numero_venta, id_cliente, id_usuario, metodo_pago, total)
               VALUES (%s, %s, %s, %s, %s)
               RETURNING id_venta""",
            (
                numero_venta,
                data['id_cliente'],
                data.get('id_usuario', 1),
                data.get('metodo_pago', 'EFECTIVO'),
                data['total'],
            ),
        )
        id_venta = cur.fetchone()['id_venta']

        # 3) Insert detalles, update stock and record movements
        for item in data['items']:
            cur.execute(
                "SELECT stock_actual, stock_minimo FROM productos WHERE id_producto = %s",
                (item['id_producto'],),
            )
            prod = cur.fetchone()
            stock_anterior = int(prod['stock_actual']) if prod else 0

            cur.execute(
                """INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal)
                   VALUES (%s, %s, %s, %s, %s)""",
                (
                    id_venta,
                    item['id_producto'],
                    item['cantidad'],
                    item['precio_unitario'],
                    item['cantidad'] * item['precio_unitario'],
                ),
            )
            cur.execute(
                "UPDATE productos SET stock_actual = stock_actual - %s WHERE id_producto = %s",
                (item['cantidad'], item['id_producto']),
            )
            stock_nuevo = stock_anterior - item['cantidad']

            cur.execute(
                """INSERT INTO stock_movimientos
                   (id_producto, tipo_movimiento, cantidad, motivo, stock_anterior, stock_nuevo, observacion)
                   VALUES (%s, 'SALIDA', %s, %s, %s, %s, %s)""",
                (
                    item['id_producto'],
                    item['cantidad'],
                    f"Venta {numero_venta}",
                    stock_anterior,
                    stock_nuevo,
                    f"Salida por venta {numero_venta}",
                ),
            )

            if prod and int(prod['stock_minimo']) > 0 and stock_nuevo <= int(prod['stock_minimo']):
                deficit = max(1, int(prod['stock_minimo']) - stock_nuevo)
                cur.execute(
                    """INSERT INTO stock_movimientos
                       (id_producto, tipo_movimiento, cantidad, motivo, stock_anterior, stock_nuevo, observacion)
                       VALUES (%s, 'ALERTA', %s, %s, %s, %s, %s)""",
                    (
                        item['id_producto'],
                        deficit,
                        'Bajo stock',
                        stock_anterior,
                        stock_nuevo,
                        f"Producto por debajo del stock mínimo ({prod['stock_minimo']})",
                    ),
                )

        conn.commit()
        return id_venta
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
def fetch_movimientos(limit=100):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute("""
            SELECT m.id_movimiento, m.id_producto, p.nombre as producto,
                   m.tipo_movimiento, m.cantidad, m.motivo, m.observacion,
                   m.fecha, m.stock_anterior, m.stock_nuevo
            FROM stock_movimientos m
            JOIN productos p ON m.id_producto = p.id_producto
            ORDER BY m.fecha DESC, m.id_movimiento DESC
            LIMIT %s
        """, (limit,))
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_movimiento(data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute(
            "SELECT stock_actual, stock_minimo FROM productos WHERE id_producto = %s",
            (data['id_producto'],),
        )
        prod = cur.fetchone()
        if not prod:
            raise RuntimeError('Producto no encontrado')

        tipo = str(data.get('tipo_movimiento', 'AJUSTE')).upper()
        cantidad = int(data.get('cantidad', 0))
        if cantidad <= 0:
            raise RuntimeError('La cantidad debe ser mayor a 0')

        stock_anterior = int(prod['stock_actual'])
        if tipo == 'ENTRADA':
            stock_nuevo = stock_anterior + cantidad
        else:
            stock_nuevo = stock_anterior - cantidad

        if stock_nuevo < 0:
            raise RuntimeError('Stock insuficiente')

        cur.execute(
            "UPDATE productos SET stock_actual = %s WHERE id_producto = %s",
            (stock_nuevo, data['id_producto']),
        )
        cur.execute(
            """INSERT INTO stock_movimientos
               (id_producto, tipo_movimiento, cantidad, motivo, stock_anterior, stock_nuevo, observacion)
               VALUES (%s, %s, %s, %s, %s, %s, %s)
               RETURNING id_movimiento""",
            (
                data['id_producto'],
                tipo,
                cantidad,
                data.get('motivo', ''),
                stock_anterior,
                stock_nuevo,
                data.get('observacion'),
            ),
        )
        new_id = cur.fetchone()['id_movimiento']

        if int(prod['stock_minimo']) > 0 and stock_nuevo <= int(prod['stock_minimo']):
            deficit = max(1, int(prod['stock_minimo']) - stock_nuevo)
            cur.execute(
                """INSERT INTO stock_movimientos
                   (id_producto, tipo_movimiento, cantidad, motivo, stock_anterior, stock_nuevo, observacion)
                   VALUES (%s, 'ALERTA', %s, %s, %s, %s, %s)""",
                (
                    data['id_producto'],
                    deficit,
                    'Bajo stock',
                    stock_anterior,
                    stock_nuevo,
                    f"Producto por debajo del stock mínimo ({prod['stock_minimo']})",
                ),
            )

        conn.commit()
        return new_id
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
def fetch_categorias(limit=100):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute(
            "SELECT id_categoria, nombre, descripcion, estado FROM categorias WHERE estado = 'ACTIVO' LIMIT %s",
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_categoria(data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO categorias (nombre, descripcion, estado)
               VALUES (%s, %s, %s)
               RETURNING id_categoria""",
            (
                data.get('nombre'),
                data.get('descripcion'),
                data.get('estado', 'ACTIVO'),
            ),
        )
        new_id = cur.fetchone()[0]
        conn.commit()
        return new_id
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
def verify_login(usuario: str, contrasena: str):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute(
            "SELECT id_usuario, nombre, usuario, rol, estado FROM usuarios "
            "WHERE usuario = %s AND contraseña = %s AND estado = 'ACTIVO'",
            (usuario, contrasena),
        )
        return cur.fetchone()
    finally:
        cur.close()
        conn.close()


def fetch_usuarios(limit=100):
    conn = get_connection()
    try:
        cur = conn.cursor(row_factory=dict_row)
        cur.execute(
            "SELECT id_usuario, nombre, usuario, rol, estado FROM usuarios LIMIT %s",
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_usuario(data: dict):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO usuarios (nombre, usuario, contraseña, rol, estado) VALUES (%s, %s, %s, %s, %s) RETURNING id_usuario",
            (
                data.get('nombre'),
                data.get('usuario'),
                data.get('contraseña'),
                data.get('rol', 'VENDEDOR'),
                data.get('estado', 'ACTIVO'),
            ),
        )
        conn.commit()
        return cur.fetchone()[0]
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
