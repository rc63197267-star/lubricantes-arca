import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_client.dart';
import '../services/server_config.dart';
import '../utils/input_rules.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, this.editProductId, this.openCreate = false});

  final int? editProductId;
  final bool openCreate;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

String _imageUrl(String image) {
  final value = image.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return '${apiBaseUrl()}$value';
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Product>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    _future = fetchProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (widget.openCreate) {
        await _showCreateDialog();
        return;
      }

      final editId = widget.editProductId;
      if (editId == null) return;

      try {
        final products = await _future;
        if (!mounted) return;
        for (final product in products) {
          if (product.id == editId) {
            await _showEditDialog(product);
            break;
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _filtrar(List<Product> items) {
    final q = _query.toLowerCase();
    return items.where((p) {
      final coincide =
          q.isEmpty ||
          p.nombre.toLowerCase().contains(q) ||
          (p.marca?.toLowerCase().contains(q) ?? false);
      if (!coincide) return false;
      switch (_filtro) {
        case 'BAJO':
          return p.stock > 0 && p.stockMinimo > 0 && p.stock <= p.stockMinimo;
        case 'AGOTADO':
          return p.stock == 0;
        default:
          return true;
      }
    }).toList();
  }

  Widget _chip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _filtro == value,
      onSelected: (_) => setState(() => _filtro = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o marca...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip('TODOS', 'Todos'),
                    const SizedBox(width: 8),
                    _chip('BAJO', 'Stock bajo'),
                    const SizedBox(width: 8),
                    _chip('AGOTADO', 'Agotado'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final items = _filtrar(snap.data ?? []);
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No hay productos que coincidan'),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final p = items[i];
                    final img = p.imagen;
                    return ListTile(
                      onTap: () => _showEditDialog(p),
                      leading: (img != null && img.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageUrl(img),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFFE3E8EF),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 22,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3E8EF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 22,
                                color: Color(0xFF6A7788),
                              ),
                            ),
                      title: Text(p.nombre),
                      subtitle: Text(
                        '${p.marca ?? '-'} • Stock: ${p.stock} (mín. ${p.stockMinimo}) • Compra: Bs. ${p.precioCompra}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Bs. ${p.precioVenta}'),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFD14343),
                            ),
                            tooltip: 'Borrar producto',
                            onPressed: () => _confirmarBorrar(p),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmarBorrar(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar producto'),
        content: Text(
          '¿Seguro que querés borrar "${p.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD14343),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await deleteProduct(p.id);
      if (!mounted) return;
      setState(() {
        _future = fetchProducts();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto borrado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al borrar: $e')));
    }
  }

  /// Pide al usuario elegir entre camara o galeria y devuelve la imagen en base64.
  Future<String?> _elegirImagen() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (xfile == null) return null;
    final bytes = await File(xfile.path).readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _showCreateDialog() async {
    final proveedores = await fetchSuppliers();
    final categorias = await fetchCategorias();
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String marca = '';
    String precioCompra = '';
    String precio = '';
    String stock = '';
    String stockMinimo = '';
    String imagen = '';
    int? selectedProveedorId;
    int? selectedCategoriaId;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Nuevo producto'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    inputFormatters: InputRules.productText,
                    onSaved: (v) => nombre = v?.trim() ?? '',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Marca'),
                    inputFormatters: InputRules.productText,
                    onSaved: (v) => marca = v?.trim() ?? '',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                          ),
                          items: categorias
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setDlg(() => selectedCategoriaId = v),
                          validator: (v) =>
                              v == null ? 'Selecciona una categoría' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined),
                        tooltip: 'Nueva categoría',
                        onPressed: () async {
                          final nuevoId = await _mostrarDialogoNuevaCategoria(
                            ctx,
                          );
                          if (nuevoId == null) return;
                          final nuevos = await fetchCategorias();
                          if (!ctx.mounted) return;
                          setDlg(() {
                            categorias
                              ..clear()
                              ..addAll(nuevos);
                            selectedCategoriaId = nuevoId;
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Proveedor',
                          ),
                          items: proveedores
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setDlg(() => selectedProveedorId = v),
                          validator: (v) =>
                              v == null ? 'Selecciona un proveedor' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_business_rounded),
                        tooltip: 'Nuevo proveedor',
                        onPressed: () async {
                          final nuevoId = await _mostrarDialogoNuevoProveedor(
                            ctx,
                          );
                          if (nuevoId == null) return;
                          final nuevos = await fetchSuppliers();
                          if (!ctx.mounted) return;
                          setDlg(() {
                            proveedores
                              ..clear()
                              ..addAll(nuevos);
                            selectedProveedorId = nuevoId;
                          });
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Precio de compra (Bs.)',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: InputRules.money,
                    onSaved: (v) => precioCompra = v?.trim() ?? '0',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta (Bs.)',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: InputRules.money,
                    onSaved: (v) => precio = v?.trim() ?? '0',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    inputFormatters: InputRules.digits,
                    onSaved: (v) => stock = v?.trim() ?? '0',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: InputRules.digits,
                    onSaved: (v) => stockMinimo = v?.trim() ?? '0',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (imagen.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${apiBaseUrl()}$imagen',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFFE3E8EF),
                              child: const Icon(Icons.image_outlined),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3E8EF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF6A7788),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final b64 = await _elegirImagen();
                                if (b64 == null) return;
                                try {
                                  final url = await uploadProductImage(b64);
                                  if (!ctx.mounted) return;
                                  setDlg(() => imagen = url ?? '');
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al subir imagen: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              label: const Text('Tomar / subir foto'),
                            ),
                            if (imagen.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Imagen cargada ✓',
                                  style: TextStyle(
                                    color: Color(0xFF228B57),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(ctx);
                  final p = Product(
                    id: 0,
                    nombre: nombre,
                    marca: marca.isEmpty ? null : marca,
                    precioCompra: precioCompra.isEmpty ? '0' : precioCompra,
                    precioVenta: precio.isEmpty ? '0' : precio,
                    stock: int.tryParse(stock) ?? 0,
                    stockMinimo: int.tryParse(stockMinimo) ?? 0,
                    idProveedor: selectedProveedorId ?? 1,
                    idCategoria: selectedCategoriaId ?? 1,
                    imagen: imagen.isEmpty ? null : imagen,
                  );
                  try {
                    await createProduct(p);
                    navigator.pop(true);
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error creando producto: $e')),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _future = fetchProducts();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto creado')));
    }
  }

  Future<void> _showEditDialog(Product p) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: p.nombre);
    final marcaCtrl = TextEditingController(text: p.marca ?? '');
    final precioCompraCtrl = TextEditingController(text: p.precioCompra);
    final precioCtrl = TextEditingController(text: p.precioVenta);
    final stockCtrl = TextEditingController(text: '${p.stock}');
    final stockMinimoCtrl = TextEditingController(text: '${p.stockMinimo}');
    final imagenCtrl = TextEditingController(text: p.imagen ?? '');
    String imagenActual = p.imagen ?? '';

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Editar producto'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    inputFormatters: InputRules.productText,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: marcaCtrl,
                    decoration: const InputDecoration(labelText: 'Marca'),
                    inputFormatters: InputRules.productText,
                  ),
                  TextFormField(
                    controller: precioCompraCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Precio de compra (Bs.)',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: InputRules.money,
                  ),
                  TextFormField(
                    controller: precioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta (Bs.)',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: InputRules.money,
                  ),
                  TextFormField(
                    controller: stockCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Stock actual',
                      helperText: 'Para cambiarlo usa el botón + Stock',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  TextFormField(
                    controller: stockMinimoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: InputRules.digits,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (imagenActual.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${apiBaseUrl()}$imagenActual',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFFE3E8EF),
                              child: const Icon(Icons.image_outlined),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3E8EF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF6A7788),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final b64 = await _elegirImagen();
                                if (b64 == null) return;
                                try {
                                  final url = await uploadProductImage(b64);
                                  if (!ctx.mounted) return;
                                  setDlg(() {
                                    imagenActual = url ?? '';
                                    imagenCtrl.text = imagenActual;
                                  });
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al subir imagen: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              label: const Text('Tomar / subir foto'),
                            ),
                            if (imagenActual.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Imagen cargada ✓',
                                  style: TextStyle(
                                    color: Color(0xFF228B57),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(ctx);
                  final nombre = nombreCtrl.text.trim();
                  final marca = marcaCtrl.text.trim();
                  final precioCompra = precioCompraCtrl.text.trim();
                  final precio = precioCtrl.text.trim();
                  final stockMinimo = stockMinimoCtrl.text.trim();
                  final imagen = imagenCtrl.text.trim();
                  final editado = Product(
                    id: p.id,
                    nombre: nombre,
                    marca: marca.isEmpty ? null : marca,
                    precioCompra: precioCompra.isEmpty
                        ? p.precioCompra
                        : precioCompra,
                    precioVenta: precio.isEmpty ? p.precioVenta : precio,
                    stock: p.stock,
                    stockMinimo: int.tryParse(stockMinimo) ?? p.stockMinimo,
                    idProveedor: p.idProveedor,
                    idCategoria: p.idCategoria,
                    imagen: imagen.isEmpty ? null : imagen,
                  );
                  try {
                    await updateProduct(editado);
                    navigator.pop(true);
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error editando producto: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    nombreCtrl.dispose();
    marcaCtrl.dispose();
    precioCompraCtrl.dispose();
    precioCtrl.dispose();
    stockCtrl.dispose();
    stockMinimoCtrl.dispose();
    imagenCtrl.dispose();

    if (updated == true && mounted) {
      setState(() {
        _future = fetchProducts();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
    }
  }

  Future<int?> _mostrarDialogoNuevoProveedor(BuildContext ctx) async {
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Nuevo proveedor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  inputFormatters: InputRules.personName,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: telefonoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: InputRules.digits,
                ),
                TextFormField(
                  controller: correoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo (opcional)',
                  ),
                ),
                TextFormField(
                  controller: direccionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final navigator = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(dialogCtx);
              final telefono = telefonoCtrl.text.trim();
              final correo = correoCtrl.text.trim();
              final direccion = direccionCtrl.text.trim();
              final s = Supplier(
                id: 0,
                nombre: nombreCtrl.text.trim(),
                telefono: telefono.isEmpty ? null : telefono,
                correo: correo.isEmpty ? null : correo,
                direccion: direccion.isEmpty ? null : direccion,
              );
              try {
                final id = await createSupplier(s);
                navigator.pop(id);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<int?> _mostrarDialogoNuevaCategoria(BuildContext ctx) async {
    final nombreCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  inputFormatters: InputRules.productText,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: descripcionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final navigator = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(dialogCtx);
              final descripcion = descripcionCtrl.text.trim();
              final c = Categoria(
                id: 0,
                nombre: nombreCtrl.text.trim(),
                descripcion: descripcion.isEmpty ? null : descripcion,
              );
              try {
                final id = await createCategoria(c);
                navigator.pop(id);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
