import mysql.connector
from mysql.connector import Error, IntegrityError

from db_config import DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME


def get_connection():
    try:
        return mysql.connector.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset="utf8mb4",
            collation="utf8mb4_unicode_ci",
            autocommit=False,
        )
    except Error as e:
        raise RuntimeError(f"Error conectando a MySQL: {e}")


def _dict_cursor(conn):
    return conn.cursor(dictionary=True)


def fetch_products(limit=10):
    conn = get_connection()
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT id_producto, codigo, id_categoria, id_proveedor,
                   nombre, marca, precio_compra, precio_venta,
                   stock_actual, stock_minimo, imagen
            FROM productos
            WHERE estado = 'ACTIVO'
            ORDER BY id_producto
            LIMIT %s
            """,
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def fetch_clients(limit=50):
    conn = get_connection()
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT id_cliente, nombre, telefono, correo, direccion, estado
            FROM clientes
            ORDER BY id_cliente
            LIMIT %s
            """,
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_client(data: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO clientes (nombre, telefono, correo, direccion, estado)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                data.get("nombre"),
                data.get("telefono"),
                data.get("correo"),
                data.get("direccion"),
                data.get("estado", "ACTIVO"),
            ),
        )
        new_id = cur.lastrowid
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
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT id_proveedor, nombre, telefono, correo, direccion, estado
            FROM proveedores
            ORDER BY id_proveedor
            LIMIT %s
            """,
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_supplier(data: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO proveedores (nombre, telefono, correo, direccion, estado)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                data.get("nombre"),
                data.get("telefono"),
                data.get("correo"),
                data.get("direccion"),
                data.get("estado", "ACTIVO"),
            ),
        )
        new_id = cur.lastrowid
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
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO productos
            (codigo, id_categoria, id_proveedor, nombre, marca, precio_compra,
             precio_venta, stock_actual, stock_minimo, estado, imagen)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                data.get("codigo"),
                data.get("id_categoria", 1),
                data.get("id_proveedor", 1),
                data.get("nombre"),
                data.get("marca"),
                data.get("precio_compra", 0.0),
                data.get("precio_venta", 0.0),
                data.get("stock_actual", 0),
                data.get("stock_minimo", 0),
                data.get("estado", "ACTIVO"),
                data.get("imagen"),
            ),
        )
        new_id = cur.lastrowid
        stock_inicial = int(data.get("stock_actual", 0) or 0)
        if stock_inicial > 0:
            cur.execute(
                """
                INSERT INTO stock_movimientos
                (id_producto, tipo_movimiento, cantidad, motivo,
                 stock_anterior, stock_nuevo, observacion)
                VALUES (%s, 'ENTRADA', %s, %s, 0, %s, %s)
                """,
                (
                    new_id,
                    stock_inicial,
                    "Ingreso de mercadería",
                    stock_inicial,
                    "Entrada inicial de stock",
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
    cur = conn.cursor()
    try:
        cur.execute(
            """
            UPDATE productos SET
                id_categoria = %s,
                id_proveedor = %s,
                nombre = %s,
                marca = %s,
                precio_compra = %s,
                precio_venta = %s,
                stock_actual = %s,
                stock_minimo = %s,
                imagen = %s
            WHERE id_producto = %s
            """,
            (
                data.get("id_categoria", 1),
                data.get("id_proveedor", 1),
                data.get("nombre"),
                data.get("marca"),
                data.get("precio_compra", 0.0),
                data.get("precio_venta", 0.0),
                data.get("stock_actual", 0),
                data.get("stock_minimo", 0),
                data.get("imagen"),
                id_producto,
            ),
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


def delete_product(id_producto):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM productos WHERE id_producto = %s", (id_producto,))
        rows = cur.rowcount
        conn.commit()
        return rows
    except IntegrityError as e:
        conn.rollback()
        if getattr(e, "errno", None) != 1451:
            raise
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
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT
                v.id_venta,
                v.numero_venta,
                v.id_cliente,
                c.nombre AS cliente,
                v.fecha,
                v.metodo_pago,
                v.descuento,
                v.monto_recibido,
                v.cambio,
                v.total,
                v.estado,
                GROUP_CONCAT(
                    CONCAT(p.nombre, ' x', dv.cantidad)
                    ORDER BY dv.id_detalle_venta
                    SEPARATOR ', '
                ) AS productos
            FROM ventas v
            JOIN clientes c ON v.id_cliente = c.id_cliente
            LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
            LEFT JOIN productos p ON p.id_producto = dv.id_producto
            GROUP BY
                v.id_venta, v.numero_venta, v.id_cliente, c.nombre,
                v.fecha, v.metodo_pago, v.descuento,
                v.monto_recibido, v.cambio, v.total, v.estado
            ORDER BY v.fecha DESC
            LIMIT %s
            """,
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_sale(data: dict):
    conn = get_connection()
    cur = _dict_cursor(conn)
    try:
        cur.execute("SELECT COALESCE(MAX(id_venta), 0) + 1 AS next_seq FROM ventas")
        seq = int(cur.fetchone()["next_seq"])
        numero_venta = f"V-{seq:06d}"

        subtotal = sum(
            int(item["cantidad"]) * float(item["precio_unitario"])
            for item in data["items"]
        )
        descuento = max(0.0, float(data.get("descuento", 0) or 0))
        if descuento > subtotal:
            raise RuntimeError("El descuento no puede ser mayor al subtotal")
        total_final = subtotal - descuento

        metodo_pago = data.get("metodo_pago", "EFECTIVO")
        monto_recibido = max(
            0.0, float(data.get("monto_recibido", 0) or 0)
        )
        if metodo_pago == "EFECTIVO":
            if monto_recibido < total_final:
                raise RuntimeError("El monto recibido es menor al total a pagar")
            cambio = monto_recibido - total_final
        else:
            monto_recibido = 0.0
            cambio = 0.0

        cur.execute(
            """
            INSERT INTO ventas
            (numero_venta, id_cliente, id_usuario, metodo_pago, descuento,
             monto_recibido, cambio, total)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                numero_venta,
                data["id_cliente"],
                data.get("id_usuario", 1),
                metodo_pago,
                descuento,
                monto_recibido,
                cambio,
                total_final,
            ),
        )
        id_venta = cur.lastrowid

        for item in data["items"]:
            cur.execute(
                """
                SELECT stock_actual, stock_minimo
                FROM productos
                WHERE id_producto = %s
                FOR UPDATE
                """,
                (item["id_producto"],),
            )
            prod = cur.fetchone()
            if not prod:
                raise RuntimeError(
                    f"Producto {item['id_producto']} no encontrado"
                )

            cantidad = int(item["cantidad"])
            stock_anterior = int(prod["stock_actual"])
            if cantidad <= 0:
                raise RuntimeError("La cantidad debe ser mayor a 0")
            if cantidad > stock_anterior:
                raise RuntimeError(
                    f"Stock insuficiente para el producto {item['id_producto']}"
                )

            precio = item["precio_unitario"]
            cur.execute(
                """
                INSERT INTO detalle_ventas
                (id_venta, id_producto, cantidad, precio_unitario, subtotal)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    id_venta,
                    item["id_producto"],
                    cantidad,
                    precio,
                    cantidad * precio,
                ),
            )

            stock_nuevo = stock_anterior - cantidad
            cur.execute(
                """
                UPDATE productos
                SET stock_actual = %s
                WHERE id_producto = %s
                """,
                (stock_nuevo, item["id_producto"]),
            )

            cur.execute(
                """
                INSERT INTO stock_movimientos
                (id_producto, tipo_movimiento, cantidad, motivo,
                 stock_anterior, stock_nuevo, observacion)
                VALUES (%s, 'SALIDA', %s, %s, %s, %s, %s)
                """,
                (
                    item["id_producto"],
                    cantidad,
                    f"Venta {numero_venta}",
                    stock_anterior,
                    stock_nuevo,
                    f"Salida por venta {numero_venta}",
                ),
            )

            stock_minimo = int(prod["stock_minimo"])
            if stock_minimo > 0 and stock_nuevo <= stock_minimo:
                deficit = max(1, stock_minimo - stock_nuevo)
                cur.execute(
                    """
                    INSERT INTO stock_movimientos
                    (id_producto, tipo_movimiento, cantidad, motivo,
                     stock_anterior, stock_nuevo, observacion)
                    VALUES (%s, 'ALERTA', %s, %s, %s, %s, %s)
                    """,
                    (
                        item["id_producto"],
                        deficit,
                        "Bajo stock",
                        stock_anterior,
                        stock_nuevo,
                        f"Producto por debajo del stock mínimo ({stock_minimo})",
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
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT
                m.id_movimiento,
                m.id_producto,
                p.nombre AS producto,
                m.tipo_movimiento,
                m.cantidad,
                m.precio_compra,
                m.id_proveedor,
                pr.nombre AS proveedor,
                m.motivo,
                m.observacion,
                m.fecha,
                m.stock_anterior,
                m.stock_nuevo
            FROM stock_movimientos m
            JOIN productos p ON m.id_producto = p.id_producto
            LEFT JOIN proveedores pr ON m.id_proveedor = pr.id_proveedor
            ORDER BY m.fecha DESC, m.id_movimiento DESC
            LIMIT %s
            """,
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_movimiento(data: dict):
    conn = get_connection()
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT stock_actual, stock_minimo, precio_compra, id_proveedor
            FROM productos
            WHERE id_producto = %s
            FOR UPDATE
            """,
            (data["id_producto"],),
        )
        prod = cur.fetchone()
        if not prod:
            raise RuntimeError("Producto no encontrado")

        tipo = str(data.get("tipo_movimiento", "AJUSTE")).upper()
        cantidad = int(data.get("cantidad", 0))
        if tipo not in {"ENTRADA", "SALIDA", "AJUSTE"}:
            raise RuntimeError("Tipo de movimiento no válido")
        if cantidad <= 0:
            raise RuntimeError("La cantidad debe ser mayor a 0")

        stock_anterior = int(prod["stock_actual"])
        if tipo == "ENTRADA":
            stock_nuevo = stock_anterior + cantidad
        else:
            stock_nuevo = stock_anterior - cantidad

        if stock_nuevo < 0:
            raise RuntimeError("Stock insuficiente")

        precio_compra = data.get("precio_compra")
        id_proveedor = data.get("id_proveedor")

        if tipo == "ENTRADA":
            if precio_compra is None or float(precio_compra) <= 0:
                raise RuntimeError("Ingresa un precio de compra válido")
            if id_proveedor is None:
                raise RuntimeError("Selecciona un proveedor")

            cur.execute(
                """
                UPDATE productos
                SET stock_actual = %s,
                    precio_compra = %s,
                    id_proveedor = %s
                WHERE id_producto = %s
                """,
                (
                    stock_nuevo,
                    float(precio_compra),
                    id_proveedor,
                    data["id_producto"],
                ),
            )
        else:
            cur.execute(
                """
                UPDATE productos
                SET stock_actual = %s
                WHERE id_producto = %s
                """,
                (stock_nuevo, data["id_producto"]),
            )

        cur.execute(
            """
            INSERT INTO stock_movimientos
            (id_producto, tipo_movimiento, cantidad, precio_compra,
             id_proveedor, motivo, stock_anterior, stock_nuevo, observacion)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                data["id_producto"],
                tipo,
                cantidad,
                float(precio_compra) if precio_compra is not None else None,
                id_proveedor,
                data.get("motivo", ""),
                stock_anterior,
                stock_nuevo,
                data.get("observacion"),
            ),
        )
        new_id = cur.lastrowid

        stock_minimo = int(prod["stock_minimo"])
        if stock_minimo > 0 and stock_nuevo <= stock_minimo:
            deficit = max(1, stock_minimo - stock_nuevo)
            cur.execute(
                """
                INSERT INTO stock_movimientos
                (id_producto, tipo_movimiento, cantidad, motivo,
                 stock_anterior, stock_nuevo, observacion)
                VALUES (%s, 'ALERTA', %s, %s, %s, %s, %s)
                """,
                (
                    data["id_producto"],
                    deficit,
                    "Bajo stock",
                    stock_anterior,
                    stock_nuevo,
                    f"Producto por debajo del stock mínimo ({stock_minimo})",
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
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT id_categoria, nombre, descripcion, estado
            FROM categorias
            WHERE estado = 'ACTIVO'
            ORDER BY id_categoria
            LIMIT %s
            """,
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_categoria(data: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO categorias (nombre, descripcion, estado)
            VALUES (%s, %s, %s)
            """,
            (
                data.get("nombre"),
                data.get("descripcion"),
                data.get("estado", "ACTIVO"),
            ),
        )
        new_id = cur.lastrowid
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
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT id_usuario, nombre, usuario, rol, estado
            FROM usuarios
            WHERE usuario = %s
              AND `contraseña` = %s
              AND estado = 'ACTIVO'
            """,
            (usuario, contrasena),
        )
        return cur.fetchone()
    finally:
        cur.close()
        conn.close()


def fetch_usuarios(limit=100):
    conn = get_connection()
    cur = _dict_cursor(conn)
    try:
        cur.execute(
            """
            SELECT id_usuario, nombre, usuario, rol, estado
            FROM usuarios
            ORDER BY id_usuario
            LIMIT %s
            """,
            (limit,),
        )
        return cur.fetchall()
    finally:
        cur.close()
        conn.close()


def create_usuario(data: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO usuarios
            (nombre, usuario, `contraseña`, rol, estado)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                data.get("nombre"),
                data.get("usuario"),
                data.get("contraseña"),
                data.get("rol", "VENDEDOR"),
                data.get("estado", "ACTIVO"),
            ),
        )
        new_id = cur.lastrowid
        conn.commit()
        return new_id
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
