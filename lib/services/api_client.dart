import 'dart:convert';

import 'package:http/http.dart' as http;
import 'server_config.dart';

String _baseHost() => apiBaseUrl();

class Product {
  final int id;
  final String nombre;
  final String? marca;
  final String precioCompra;
  final String precioVenta;
  final int stock;
  final int stockMinimo;
  final int idProveedor;
  final int idCategoria;
  final String? imagen;

  Product({
    required this.id,
    required this.nombre,
    this.marca,
    this.precioCompra = '0',
    required this.precioVenta,
    required this.stock,
    this.stockMinimo = 0,
    this.idProveedor = 1,
    this.idCategoria = 1,
    this.imagen,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id_producto'] as int,
    nombre: j['nombre'] as String,
    marca: j['marca'] as String?,
    precioCompra: j['precio_compra']?.toString() ?? '0',
    precioVenta: j['precio_venta']?.toString() ?? '',
    stock: (j['stock_actual'] is int)
        ? j['stock_actual'] as int
        : int.parse(j['stock_actual'].toString()),
    stockMinimo: j['stock_minimo'] == null
        ? 0
        : (j['stock_minimo'] is int)
            ? j['stock_minimo'] as int
            : int.parse(j['stock_minimo'].toString()),
    imagen: j['imagen'] as String?,
  );

  Map<String, dynamic> toJsonCreate() => {
    'codigo': 'GEN${DateTime.now().millisecondsSinceEpoch}',
    'id_categoria': idCategoria,
    'id_proveedor': idProveedor,
    'nombre': nombre,
    'marca': marca,
    'precio_compra': double.tryParse(precioCompra.replaceAll(',', '')) ?? 0.0,
    'precio_venta': double.tryParse(precioVenta.replaceAll(',', '')) ?? 0.0,
    'stock_actual': stock,
    'stock_minimo': stockMinimo,
    'estado': 'ACTIVO',
    'imagen': imagen,
  };

  Map<String, dynamic> toJsonUpdate() => {
    'id_categoria': idCategoria,
    'id_proveedor': idProveedor,
    'nombre': nombre,
    'marca': marca,
    'precio_compra': double.tryParse(precioCompra.replaceAll(',', '')) ?? 0.0,
    'precio_venta': double.tryParse(precioVenta.replaceAll(',', '')) ?? 0.0,
    'stock_actual': stock,
    'stock_minimo': stockMinimo,
    'imagen': imagen,
  };
}

Future<List<Product>> fetchProducts() async {
  final host = _baseHost();
  final res = await http.get(Uri.parse('$host/products'));
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final data = jsonDecode(res.body) as List;
  return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
}

Future<int> createProduct(Product p) async {
  final host = _baseHost();
  final body = jsonEncode(p.toJsonCreate());
  final res = await http.post(
    Uri.parse('$host/products'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Create failed ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['id_producto'] as int;
}

Future<void> updateProduct(Product p) async {
  final host = _baseHost();
  final body = jsonEncode(p.toJsonUpdate());
  final res = await http.put(
    Uri.parse('$host/products/${p.id}'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Update failed ${res.statusCode}');
}

Future<void> deleteProduct(int id) async {
  final host = _baseHost();
  final res = await http.delete(Uri.parse('$host/products/$id'));
  if (res.statusCode != 200) throw Exception('Delete failed ${res.statusCode}');
}

/// Sube una imagen (en base64) al servidor y devuelve la ruta relativa
/// que se guarda en el producto, ej: /uploads/abc123.jpg
Future<String?> uploadProductImage(String base64Data, {String? filename}) async {
  final host = _baseHost();
  final res = await http.post(
    Uri.parse('$host/upload'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'data': base64Data, 'filename': filename ?? 'foto.jpg'}),
  );
  if (res.statusCode != 200) throw Exception('Upload failed ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['url'] as String?;
}

class Client {
  final int id;
  final String nombre;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final String estado;

  Client({
    required this.id,
    required this.nombre,
    this.telefono,
    this.correo,
    this.direccion,
    this.estado = 'ACTIVO',
  });

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id_cliente'] as int,
        nombre: j['nombre'] as String,
        telefono: j['telefono'] as String?,
        correo: j['correo'] as String?,
        direccion: j['direccion'] as String?,
        estado: j['estado']?.toString() ?? 'ACTIVO',
      );

  Map<String, dynamic> toJsonCreate() => {
        'nombre': nombre,
        'telefono': telefono,
        'correo': correo,
        'direccion': direccion,
        'estado': estado,
      };
}

Future<List<Client>> fetchClients() async {
  final host = _baseHost();
  final res = await http.get(Uri.parse('$host/clients'));
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final data = jsonDecode(res.body) as List;
  return data.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
}

Future<int> createClient(Client c) async {
  final host = _baseHost();
  final body = jsonEncode(c.toJsonCreate());
  final res = await http.post(
    Uri.parse('$host/clients'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Create failed ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['id_cliente'] as int;
}



class Supplier {
  final int id;
  final String nombre;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final String estado;

  Supplier({
    required this.id,
    required this.nombre,
    this.telefono,
    this.correo,
    this.direccion,
    this.estado = 'ACTIVO',
  });

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
    id: j['id_proveedor'] as int,
    nombre: j['nombre'] as String,
    telefono: j['telefono'] as String?,
    correo: j['correo'] as String?,
    direccion: j['direccion'] as String?,
    estado: j['estado']?.toString() ?? 'ACTIVO',
  );

  Map<String, dynamic> toJsonCreate() => {
    'nombre': nombre,
    'telefono': telefono,
    'correo': correo,
    'direccion': direccion,
    'estado': estado,
  };
}

Future<List<Supplier>> fetchSuppliers() async {
  final host = _baseHost();
  final res = await http.get(Uri.parse('$host/suppliers'));
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final data = jsonDecode(res.body) as List;
  return data.map((e) => Supplier.fromJson(e as Map<String, dynamic>)).toList();
}

Future<int> createSupplier(Supplier s) async {
  final host = _baseHost();
  final body = jsonEncode(s.toJsonCreate());
  final res = await http.post(
    Uri.parse('$host/suppliers'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Create failed ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['id_proveedor'] as int;
}
class Sale {
  final int id;
  final String numero;
  final int idCliente;
  final String cliente;
  final String fecha;
  final String metodoPago;
  final String total;
  final String estado;
  final String? productos;

  Sale({
    required this.id,
    required this.numero,
    required this.idCliente,
    required this.cliente,
    required this.fecha,
    required this.metodoPago,
    required this.total,
    required this.estado,
    this.productos,
  });

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id_venta'] as int,
        numero: j['numero_venta'] as String,
        idCliente: j['id_cliente'] as int,
        cliente: j['cliente'] as String,
        fecha: j['fecha']?.toString() ?? '',
        metodoPago: j['metodo_pago']?.toString() ?? '',
        total: j['total']?.toString() ?? '0',
        estado: j['estado']?.toString() ?? '',
        productos: j['productos'] as String?,
      );
}

Future<List<Sale>> fetchSales() async {
  final host = _baseHost();
  final res = await http.get(Uri.parse('$host/sales'));
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final data = jsonDecode(res.body) as List;
  return data.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
}

Future<int> createSale(Sale sale, List<Map<String, dynamic>> items) async {
  final host = _baseHost();
  final body = jsonEncode({
    'id_cliente': sale.idCliente,
    'metodo_pago': sale.metodoPago,
    'total': double.tryParse(sale.total) ?? 0,
    'items': items,
  });
  final res = await http.post(
    Uri.parse('$host/sales'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['id_venta'] as int;
}
class Movimiento {
  final int id;
  final int idProducto;
  final String producto;
  final String tipo;
  final int cantidad;
  final String motivo;
  final String? observacion;
  final String fecha;
  final int? stockAnterior;
  final int? stockNuevo;

  Movimiento({
    required this.id,
    required this.idProducto,
    required this.producto,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
    this.observacion,
    required this.fecha,
    this.stockAnterior,
    this.stockNuevo,
  });

  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
        id: j['id_movimiento'] as int,
        idProducto: j['id_producto'] as int,
        producto: j['producto'] as String,
        tipo: j['tipo_movimiento'] as String,
        cantidad: j['cantidad'] as int,
        motivo: j['motivo'] as String,
        observacion: j['observacion'] as String?,
        fecha: j['fecha']?.toString() ?? '',
        stockAnterior: j['stock_anterior'] as int?,
        stockNuevo: j['stock_nuevo'] as int?,
      );
}

Future<List<Movimiento>> fetchMovimientos() async {
  final host = _baseHost();
  final res = await http.get(Uri.parse('$host/movimientos'));
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final data = jsonDecode(res.body) as List;
  return data.map((e) => Movimiento.fromJson(e as Map<String, dynamic>)).toList();
}

Future<int> createMovimiento({
  required int idProducto,
  required String tipo,
  required int cantidad,
  String? motivo,
}) async {
  final host = _baseHost();
  final body = jsonEncode({
    'id_producto': idProducto,
    'tipo_movimiento': tipo,
    'cantidad': cantidad,
    'motivo': motivo ?? '',
  });
  final res = await http.post(
    Uri.parse('$host/movimientos'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['id_movimiento'] as int;
}
class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final String estado;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.estado = 'ACTIVO',
  });

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
        id: j['id_categoria'] as int,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        estado: j['estado']?.toString() ?? 'ACTIVO',
      );

  Map<String, dynamic> toJsonCreate() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': estado,
      };
}

Future<List<Categoria>> fetchCategorias() async {
  final host = _baseHost();
  final res = await http.get(Uri.parse('$host/categorias'));
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final data = jsonDecode(res.body) as List;
  return data.map((e) => Categoria.fromJson(e as Map<String, dynamic>)).toList();
}

Future<int> createCategoria(Categoria c) async {
  final host = _baseHost();
  final body = jsonEncode(c.toJsonCreate());
  final res = await http.post(
    Uri.parse('$host/categorias'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Create failed ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['id_categoria'] as int;
}
String fullImageUrl(String? imagen) {
  if (imagen == null || imagen.isEmpty) return '';
  if (imagen.startsWith('http')) return imagen;
  return '${_baseHost()}$imagen';
}

Future<String> uploadImage({
  required String filename,
  required String base64Data,
}) async {
  final host = _baseHost();
  final body = jsonEncode({'filename': filename, 'data': base64Data});
  final res = await http.post(
    Uri.parse('$host/upload'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (res.statusCode != 200) throw Exception('Upload failed ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['url'] as String;
}
Usuario? usuarioActual;

class Usuario {
  final int id;
  final String nombre;
  final String usuario;
  final String rol;
  final String estado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.rol,
    this.estado = 'ACTIVO',
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id_usuario'] as int,
        nombre: j['nombre'] as String,
        usuario: j['usuario'] as String,
        rol: j['rol']?.toString() ?? 'VENDEDOR',
        estado: j['estado']?.toString() ?? 'ACTIVO',
      );

  bool get esAdmin => rol == 'ADMIN';
}

Future<Usuario?> login(String usuario, String contrasena) async {
  final host = _baseHost();
  final res = await http.post(
    Uri.parse('$host/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'usuario': usuario, 'contraseña': contrasena}),
  );
  if (res.statusCode == 401) return null;
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  return Usuario.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
}

Future<List<Usuario>> fetchUsuarios() async {
  final host = _baseHost();
  final res = await http.get(Uri.parse('$host/usuarios'));
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final data = jsonDecode(res.body) as List;
  return data.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
}

Future<int> createUsuario({
  required String nombre,
  required String usuario,
  String contrasena = '123456789',
}) async {
  final host = _baseHost();
  final res = await http.post(
    Uri.parse('$host/usuarios'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'nombre': nombre,
      'usuario': usuario,
      'contraseña': contrasena,
      'rol': 'VENDEDOR',
    }),
  );
  if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
  final js = jsonDecode(res.body) as Map<String, dynamic>;
  return js['id_usuario'] as int;
}
