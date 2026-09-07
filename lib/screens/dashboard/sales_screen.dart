import 'package:flutter/material.dart';
import '../../widgets/search_field.dart';
import '../../widgets/buttons.dart';
import '../../services/api_client.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late Future<List<Sale>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchSales();
  }

  void _reload() {
    setState(() {
      _future = fetchSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<Sale>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 40, color: Color(0xFFB91C1C)),
                const SizedBox(height: 10),
                const Text('Error al cargar ventas'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _reload, child: const Text('Reintentar')),
              ]),
            );
          }
          final sales = snapshot.data ?? [];
          return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 12 : 20,
          vertical: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Ventas',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A2540),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Lista de ventas recientes y administración de pedidos',
                          style: TextStyle(color: Color(0xFF6A7788)),
                        ),
                      ],
                    ),
                  ),
                  if (!isPhone)
                    Row(
                      children: [
                        const SecondaryButton(
                          label: 'Filtros',
                          icon: Icons.filter_alt_outlined,
                        ),
                        const SizedBox(width: 12),
                        PrimaryButton(
                          label: 'Nueva venta',
                          icon: Icons.add_shopping_cart_rounded,
                          onPressed: _showNewSaleDialog,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (isPhone) ...[
                const SearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: SecondaryButton(
                        label: 'Filtros',
                        icon: Icons.filter_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Nueva venta',
                        icon: Icons.add_shopping_cart_rounded,
                        onPressed: _showNewSaleDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ] else ...[
                const SizedBox(height: 0),
                const SizedBox(height: 12),
                const SearchField(),
                const SizedBox(height: 18),
              ],

              // Sales list
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3E8EF)),
                ),
                child: isPhone ? _buildMobileList(sales) : _buildDesktopTable(sales),
              ),
            ],
          ),
        ),
      ),
    );
          },
        ),
      );
  }

  Widget _buildMobileList(List<Sale> sales) {
    return Column(
      children: sales.map((sale) {
        final completada = sale.estado == 'COMPLETADA';
        final fecha = sale.fecha.length > 16
            ? sale.fecha.substring(0, 16).replaceAll('T', ' ')
            : sale.fecha;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sale.numero,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: completada ? const Color(0xFFE7F7ED) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        completada ? 'Completado' : 'Anulado',
                        style: TextStyle(
                          color: completada ? const Color(0xFF228B57) : const Color(0xFF5A6471),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(sale.cliente, style: const TextStyle(color: Color(0xFF3E4756), fontWeight: FontWeight.w500)),
                if (sale.productos != null && sale.productos!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sale.productos!,
                      style: const TextStyle(color: Color(0xFF6A7788), fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fecha, style: const TextStyle(color: Color(0xFF6A7788), fontSize: 12)),
                    Text('Bs. ${sale.total}', style: const TextStyle(color: Color(0xFF0A2540), fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTable(List<Sale> sales) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Text('ID Pedido', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540)))),
            Expanded(child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540)))),
            Expanded(child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540)))),
            Expanded(child: Text('Estado', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540)))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: Text('Monto', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540))))),
          ],
        ),
        const SizedBox(height: 10),
        ...sales.map((sale) {
          final completada = sale.estado == 'COMPLETADA';
          final fecha = sale.fecha.length > 16 ? sale.fecha.substring(0, 16).replaceAll('T', ' ') : sale.fecha;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(sale.numero, style: const TextStyle(color: Color(0xFF0A2540), fontWeight: FontWeight.w600))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sale.cliente, style: const TextStyle(color: Color(0xFF3E4756)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (sale.productos != null && sale.productos!.isNotEmpty)
                        Text(sale.productos!, style: const TextStyle(color: Color(0xFF6A7788), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Expanded(child: Text(fecha, style: const TextStyle(color: Color(0xFF3E4756)))),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: completada ? const Color(0xFFE7F7ED) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      completada ? 'Completado' : 'Anulado',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: completada ? const Color(0xFF228B57) : const Color(0xFF5A6471), fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Text('Bs. ${sale.total}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF0A2540), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  Future<void> _showNewSaleDialog() async {
    final clientes = await fetchClients();
    final productos = await fetchProducts();
    if (!mounted) return;

    int? selectedClientId;
    String metodoPago = 'EFECTIVO';
    final items = <Map<String, dynamic>>[];
    double total = 0;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return AlertDialog(
            title: const Text('Nueva venta'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Cliente'),
                            items: clientes
                                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                                .toList(),
                            onChanged: (v) => setDlg(() => selectedClientId = v),
                            validator: (v) => v == null ? 'Selecciona un cliente' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_rounded),
                          tooltip: 'Nuevo cliente',
                          onPressed: () async {
                            final nuevoId = await _mostrarDialogoNuevoCliente(ctx);
                            if (nuevoId == null) return;
                            final nuevos = await fetchClients();
                            if (!ctx.mounted) return;
                            setDlg(() {
                              clientes
                                ..clear()
                                ..addAll(nuevos);
                              selectedClientId = nuevoId;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (items.isNotEmpty) ...[
                      const Text('Productos', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      ...items.asMap().entries.map((e) {
                        final prod = productos.firstWhere((p) => p.id == e.value['id_producto']);
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(prod.nombre),
                          subtitle: Text('${e.value['cantidad']} x Bs. ${e.value['precio_unitario']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setDlg(() {
                              total -= (double.tryParse(e.value['precio_unitario'].toString()) ?? 0) * (e.value['cantidad'] as int);
                              items.removeAt(e.key);
                            }),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar producto'),
                      onPressed: () async {
                        final prod = await showDialog<Product>(
                          context: ctx,
                          builder: (prodCtx) => SimpleDialog(
                            title: const Text('Selecciona un producto'),
                            children: productos.map((p) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(prodCtx, p),
                              child: Text('${p.nombre} — Bs. ${p.precioVenta} (stock: ${p.stock})'),
                            )).toList(),
                          ),
                        );
                        if (prod == null || !ctx.mounted) return;
                        final qtyCtrl = TextEditingController(text: '1');
                        final qty = await showDialog<int>(
                          context: ctx,
                          builder: (qtyCtx) => AlertDialog(
                            title: Text(prod.nombre),
                            content: TextField(
                              controller: qtyCtrl,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Cantidad'),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(qtyCtx), child: const Text('Cancelar')),
                              ElevatedButton(
                                onPressed: () {
                                  final n = int.tryParse(qtyCtrl.text) ?? 0;
                                  if (n > 0 && n <= prod.stock) Navigator.pop(qtyCtx, n);
                                },
                                child: const Text('Agregar'),
                              ),
                            ],
                          ),
                        );
                        if (qty == null || !ctx.mounted) return;
                        setDlg(() {
                          items.add({'id_producto': prod.id, 'cantidad': qty, 'precio_unitario': double.tryParse(prod.precioVenta) ?? 0});
                          total += qty * (double.tryParse(prod.precioVenta) ?? 0);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                      initialValue: metodoPago,
                      decoration: const InputDecoration(labelText: 'Método de pago'),
                      items: const [
                        DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'QR', child: Text('QR')),
                        DropdownMenuItem(value: 'TARJETA', child: Text('Tarjeta')),
                      ],
                      onChanged: (v) => metodoPago = v ?? 'EFECTIVO',
                    ),
                    const SizedBox(height: 14),
                    Text('Total: Bs. ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: (selectedClientId == null || items.isEmpty)
                    ? null
                    : () async {
                        final dialogMessenger = ScaffoldMessenger.of(ctx);
                        final navigator = Navigator.of(ctx);
                        try {
                          final sale = Sale(id: 0, numero: '', idCliente: selectedClientId!, cliente: '', fecha: '', metodoPago: metodoPago, total: total.toString(), estado: '');
                          await createSale(sale, items);
                          if (!mounted) return;
                          navigator.pop();
                          _reload();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta registrada')));
                        } catch (e) {
                          dialogMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: const Text('Registrar venta'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<int?> _mostrarDialogoNuevoCliente(BuildContext ctx) async {
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                ),
                TextFormField(
                  controller: correoCtrl,
                  decoration: const InputDecoration(labelText: 'Correo (opcional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final navigator = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(dialogCtx);
              final telefono = telefonoCtrl.text.trim();
              final correo = correoCtrl.text.trim();
              final c = Client(
                id: 0,
                nombre: nombreCtrl.text.trim(),
                telefono: telefono.isEmpty ? null : telefono,
                correo: correo.isEmpty ? null : correo,
              );
              try {
                final id = await createClient(c);
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
