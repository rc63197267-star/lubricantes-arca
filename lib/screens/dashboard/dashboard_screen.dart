import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/product_card.dart';
import '../products_page.dart';
import '../suppliers_page.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';
import 'clients_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'overview_screen.dart';

class DashboardHomePage extends StatefulWidget {
  final Usuario? usuario;
  const DashboardHomePage({super.key, this.usuario});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;

  // Índices (respecto a navItems) que se muestran en la barra inferior compacta
  // del celular: Inicio, Productos, Ventas y Stock.
  static const List<int> _quickIndexes = [0, 1, 3, 2];

  // Posición resaltada en la barra inferior (0.._quickIndexes.length, donde la
  // última es el botón "Más" que abre el menú lateral completo).
  int _quickPos = 0;

  final List<NavItem> navItems = const [
    NavItem('Inicio', Icons.dashboard_outlined),
    NavItem('Productos', Icons.inventory_2_outlined),
    NavItem('Stock', Icons.reorder_outlined),
    NavItem('Ventas', Icons.point_of_sale_outlined),
    NavItem('Clientes', Icons.people_alt_outlined),
    NavItem('Proveedores', Icons.local_shipping_outlined),
    NavItem('Historial', Icons.history_outlined),
    NavItem('Configuración', Icons.settings_outlined),
  ];

  void _select(int index) {
    setState(() {
      selectedIndex = index;
      _quickPos = _quickIndexes.contains(index)
          ? _quickIndexes.indexOf(index)
          : _quickIndexes.length;
    });
  }

  void _onQuickTap(int position) {
    if (position >= _quickIndexes.length) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    _select(_quickIndexes[position]);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final screens = [
      const OverviewScreen(),
      const _InventoryScreen(),
      StockScreen(),
      const SalesScreen(),
      const ClientsScreen(),
      const SuppliersPage(),
      const HistoryScreen(),
      SettingsScreen(usuario: widget.usuario),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0A2540),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                navItems[selectedIndex].label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menú',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: Sidebar(
                items: navItems,
                selectedIndex: selectedIndex,
                onSelect: _select,
              ),
            ),
      body: isDesktop
          ? Row(
              children: [
                Sidebar(
                  items: navItems,
                  selectedIndex: selectedIndex,
                  onSelect: _select,
                ),
                Expanded(child: screens[selectedIndex]),
              ],
            )
          : SafeArea(top: false, bottom: false, child: screens[selectedIndex]),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _quickPos,
              onDestinationSelected: _onQuickTap,
              destinations: [
                for (final idx in _quickIndexes)
                  NavigationDestination(
                    icon: Icon(navItems[idx].icon),
                    label: navItems[idx].label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.menu),
                  label: 'Más',
                ),
              ],
            ),
    );
  }
}

class _InventoryScreen extends StatefulWidget {
  const _InventoryScreen();
  @override
  State<_InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<_InventoryScreen> {
  late Future<List<Product>> _future;
  List<Product> _allProducts = [];
  final Map<int, int> _cart = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final f = fetchProducts();
    setState(() {
      _future = f;
    });
    try {
      final list = await f;
      if (mounted) setState(() => _allProducts = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isLow(Product p) =>
      p.stock == 0 || (p.stockMinimo > 0 && p.stock <= p.stockMinimo);

  List<Product> _filtrar(List<Product> items) {
    final q = _query.toLowerCase();
    return items.where((p) {
      final coincide = q.isEmpty ||
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

  Future<void> _openAddProduct() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProductsPage()),
    );
    if (mounted) {
      _reload();
    }
  }

  int _cartCount() => _cart.values.fold<int>(0, (a, b) => a + b);

  double _cartTotal() {
    double total = 0;
    for (final e in _cart.entries) {
      for (final p in _allProducts) {
        if (p.id == e.key) {
          total += (double.tryParse(p.precioVenta) ?? 0) * e.value;
          break;
        }
      }
    }
    return total;
  }

  void _addToCart(Product p) {
    if (p.stock <= 0) return;
    setState(() {
      final current = _cart[p.id] ?? 0;
      if (current < p.stock) {
        _cart[p.id] = current + 1;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final gridColumns = (() {
      final width = MediaQuery.of(context).size.width;
      if (width < 380) return 1;
      if (width < 600) return 2;
      if (width < 900) return 3;
      return 4;
    })();

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 12 : 20,
                vertical: isPhone ? 12 : 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text(
                'Gestión de inventario',
                style: TextStyle(
                  fontSize: isPhone ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A2540),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestiona y rastrea los detalles del catálogo de productos.',
                style: TextStyle(fontSize: 15, color: Color(0xFF6A7788)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o marca...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (!isPhone) ...[
                    const SizedBox(width: 12),
                    PrimaryButton(
                      label: 'Add Product',
                      icon: Icons.add_rounded,
                      onPressed: _openAddProduct,
                    ),
                  ],
                ],
              ),
              if (isPhone) ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Add Product',
                  icon: Icons.add_rounded,
                  onPressed: _openAddProduct,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip('TODOS', 'Todos'),
                  const SizedBox(width: 8),
                  _chip('BAJO', 'Stock bajo'),
                  const SizedBox(width: 8),
                  _chip('AGOTADO', 'Agotado'),
                ],
              ),
              const SizedBox(height: 22),
              FutureBuilder<List<Product>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final items = _filtrar(snap.data ?? []);
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: Text('No hay productos que coincidan')),
                    );
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: gridColumns,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.9,
                    children: items.map((p) {
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProductsPage()),
                        ),
                        child: ProductCard(
                          nombre: p.nombre,
                          marca: p.marca ?? '-',
                          sku: 'ID ${p.id}',
                          precio: 'Bs. ${p.precioVenta}',
                          stock: '${p.stock} unidades',
                          lowStock: _isLow(p),
                          imagen: fullImageUrl(p.imagen),
                          onAdd: () => _addToCart(p),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
          ),
          _buildCartBar(),
        ],
      ),
    );
  }
Widget _buildCartBar() {
    final count = _cartCount();
    final total = _cartTotal();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8EF))),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0A2540)),
          const SizedBox(width: 8),
          Text(
            count == 0 ? 'Carrito vacío' : '$count producto(s)',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0A2540)),
          ),
          const Spacer(),
          if (count > 0) ...[
            Text(
              'Bs. ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _showCartSheet,
              child: const Text('Vender'),
            ),
          ],
        ],
      ),
    );
  }
Future<void> _showCartSheet() async {
    if (_cart.isEmpty) return;
    final clientes = await fetchClients();
    if (!mounted) return;

    int? selectedClientId;
    String metodo = 'EFECTIVO';

    final vendido = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Carrito de venta',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0A2540))),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: _cart.entries.map((e) {
                        final p = _allProducts.firstWhere((x) => x.id == e.key);
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setDlg(() {
                              if (_cart[e.key]! > 1) {
                                _cart[e.key] = _cart[e.key]! - 1;
                              } else {
                                _cart.remove(e.key);
                              }
                            }),
                          ),
                          title: Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Bs. ${p.precioVenta} c/u'),
                          trailing: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        );
                      }).toList(),
                    ),
                  ),
const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Cliente'),
                          items: clientes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                          onChanged: (v) => setDlg(() => selectedClientId = v),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: metodo,
                    decoration: const InputDecoration(labelText: 'Método de pago'),
                    items: const [
                      DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'QR', child: Text('QR')),
                      DropdownMenuItem(value: 'TARJETA', child: Text('Tarjeta')),
                    ],
                    onChanged: (v) => setDlg(() => metodo = v ?? 'EFECTIVO'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Total:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0A2540))),
                      const Spacer(),
                      Text('Bs. ${_cartTotal().toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (selectedClientId == null || _cart.isEmpty)
                          ? null
                          : () async {
                              final navigator = Navigator.of(ctx);
                              final messenger = ScaffoldMessenger.of(ctx);
                              final total = _cartTotal();
                              final items = _cart.entries.map((e) {
                                final p = _allProducts.firstWhere((x) => x.id == e.key);
                                return {
                                  'id_producto': p.id,
                                  'cantidad': e.value,
                                  'precio_unitario': double.tryParse(p.precioVenta) ?? 0,
                                };
                              }).toList();
                              final venta = Sale(
                                id: 0, numero: '', idCliente: selectedClientId!, cliente: '',
                                fecha: '', metodoPago: metodo, total: total.toString(), estado: '',
                              );
                              try {
                                await createSale(venta, items);
                                if (!mounted) return;
                                navigator.pop(true);
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                      child: const Text('Realizar venta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (vendido == true && mounted) {
      setState(() {
        _cart.clear();
      });
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta realizada')));
    }
  }
}

class SalesTable extends StatelessWidget {
  const SalesTable({super.key});

  final rows = const [
    [
      '#ORD-9021',
      'Talleres Martinez S.A.',
      '24 Oct, 10:32',
      'Completado',
      'Bs. 1,240.50',
    ],
    [
      '#ORD-9020',
      'AutoRepuestos Central',
      '24 Oct, 09:15',
      'En proceso',
      'Bs. 850.00',
    ],
    [
      '#ORD-9019',
      'Lubricentro El Faro',
      '23 Oct, 16:45',
      'Completado',
      'Bs. 3,420.00',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    if (isPhone) {
      return Column(
        children: rows.map((row) {
          final state = row[3];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
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
                        row[0],
                        style: const TextStyle(
                          color: Color(0xFF0A2540),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: state == 'Completado'
                              ? const Color(0xFFE7F7ED)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          state,
                          style: TextStyle(
                            color: state == 'Completado'
                                ? const Color(0xFF228B57)
                                : const Color(0xFF5A6471),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    row[1],
                    style: const TextStyle(
                      color: Color(0xFF3E4756),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row[2],
                        style: const TextStyle(
                          color: Color(0xFF6A7788),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        row[4],
                        style: const TextStyle(
                          color: Color(0xFF0A2540),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Order ID',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Client',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Date',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2540),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...rows.map((row) {
          final state = row[3];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row[0],
                    style: const TextStyle(
                      color: Color(0xFF0A2540),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row[1],
                    style: const TextStyle(color: Color(0xFF3E4756)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    row[2],
                    style: const TextStyle(color: Color(0xFF3E4756)),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: state == 'Completado'
                          ? const Color(0xFFE7F7ED)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: state == 'Completado'
                            ? const Color(0xFF228B57)
                            : const Color(0xFF5A6471),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row[4],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF0A2540),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
