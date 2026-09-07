from db import fetch_products, fetch_clients, create_product


if __name__ == '__main__':
    print('Productos (limit 5):')
    for p in fetch_products(5):
        print(f"- {p['id_producto']}: {p['nombre']} ({p['marca']}) - {p['precio_venta']} Bs. - stock {p['stock_actual']}")

    print('\nClientes (limit 5):')
    for c in fetch_clients(5):
        print(f"- {c['id_cliente']}: {c['nombre']} - {c.get('telefono') or '-'} - {c.get('correo') or '-'}")

    # Ejemplo de inserción (descomenta si quieres crear un producto)
    # new_id = create_product({
    #     'codigo': '9999999999999',
    #     'nombre': 'Producto demo 1L',
    #     'marca': 'Demo',
    #     'precio_compra': 10.0,
    #     'precio_venta': 15.0,
    #     'stock_actual': 12,
    # })
    # print('Producto creado, id:', new_id)
