import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../utils/input_rules.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = fetchProducts();
    });
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

  Future<void> _openAddProduct() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProductsPage(openCreate: true)),
    );
    if (mounted) {
      _reload();
    }
  }

  Future<void> _showStockEntry(Product p) async {
    final suppliers = await fetchSuppliers();
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: p.precioCompra);
    int? supplierId = suppliers.any((s) => s.id == p.idProveedor)
        ? p.idProveedor
        : (suppliers.isNotEmpty ? suppliers.first.id : null);
    String motivo = 'Compra de mercadería';
    int previewQty = 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final nuevoStock = p.stock + previewQty;
            final image = fullImageUrl(p.imagen);

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              title: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Entrada de stock',
                      style: TextStyle(
                        color: Color(0xFF0A2540),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(dialogContext, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0F8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: image.isEmpty
                                    ? const Icon(
                                        Icons.oil_barrel_rounded,
                                        color: Color(0xFF4C7ED9),
                                        size: 34,
                                      )
                                    : Image.network(
                                        image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.oil_barrel_rounded,
                                          color: Color(0xFF4C7ED9),
                                          size: 34,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF0A2540),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      p.marca ?? '-',
                                      style: const TextStyle(
                                        color: Color(0xFF6A7788),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _stockInfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Stock actual',
                          value: '${p.stock}',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: InputRules.digits,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad que ingresa',
                            prefixIcon: Icon(Icons.add_box_outlined),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              previewQty = int.tryParse(value) ?? 0;
                            });
                          },
                          validator: (value) {
                            final qty = int.tryParse(value ?? '') ?? 0;
                            return qty <= 0
                                ? 'Ingresa una cantidad mayor a 0'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: InputRules.money,
                          decoration: const InputDecoration(
                            labelText: 'Nuevo precio de compra',
                            prefixText: 'Bs. ',
                            prefixIcon: Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final parsed =
                                double.tryParse(
                                  (value ?? '').replaceAll(',', '.'),
                                ) ??
                                0;
                            return parsed <= 0
                                ? 'Ingresa un precio válido'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: supplierId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Proveedor',
                            prefixIcon: Icon(Icons.local_shipping_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: suppliers
                              .map(
                                (s) => DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(
                                    s.nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() => supplierId = value);
                          },
                          validator: (value) =>
                              value == null ? 'Selecciona un proveedor' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: motivo,
                          decoration: const InputDecoration(
                            labelText: 'Motivo',
                            prefixIcon: Icon(Icons.description_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Compra de mercadería',
                              child: Text('Compra de mercadería'),
                            ),
                            DropdownMenuItem(
                              value: 'Reposición de stock',
                              child: Text('Reposición de stock'),
                            ),
                            DropdownMenuItem(
                              value: 'Devolución de cliente',
                              child: Text('Devolución de cliente'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              motivo = value ?? 'Compra de mercadería';
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB8E2C5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                color: Color(0xFF15803D),
                                size: 30,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Nuevo stock',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '$nuevoStock',
                                style: const TextStyle(
                                  color: Color(0xFF15803D),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: suppliers.isEmpty
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          final qty = int.parse(qtyCtrl.text);
                          final price = double.parse(
                            priceCtrl.text.replaceAll(',', '.'),
                          );
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(dialogContext);

                          try {
                            await createMovimiento(
                              idProducto: p.id,
                              tipo: 'ENTRADA',
                              cantidad: qty,
                              precioCompra: price,
                              idProveedor: supplierId,
                              motivo: motivo,
                              observacion:
                                  'Entrada registrada desde Inventario',
                            );
                            if (!dialogContext.mounted) return;
                            navigator.pop(true);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No se pudo registrar la entrada: $e',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Registrar entrada'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    qtyCtrl.dispose();
    priceCtrl.dispose();

    if (saved == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock actualizado: ${p.stock} → ${p.stock + previewQty}',
          ),
        ),
      );
    }
  }

  Widget _stockInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0A2540)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6A7788),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0A2540),
              fontWeight: FontWeight.w800,
            ),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        if (!isPhone) ...[
                          const SizedBox(width: 12),
                          PrimaryButton(
                            label: 'Nuevo producto',
                            icon: Icons.add_rounded,
                            onPressed: _openAddProduct,
                          ),
                        ],
                      ],
                    ),
                    if (isPhone) ...[
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Nuevo producto',
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
                            child: Center(
                              child: Text('No hay productos que coincidan'),
                            ),
                          );
                        }
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: gridColumns,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: gridColumns == 1 ? 1.05 : 0.60,
                          children: items.map((p) {
                            return ProductCard(
                              nombre: p.nombre,
                              marca: p.marca ?? '-',
                              sku: p.codigo.isEmpty ? 'ID ${p.id}' : p.codigo,
                              precio: 'Bs. ${p.precioVenta}',
                              stock: '${p.stock} unidades',
                              lowStock: _isLow(p),
                              imagen: fullImageUrl(p.imagen),
                              onEdit: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductsPage(editProductId: p.id),
                                  ),
                                );
                                if (mounted) _reload();
                              },
                              onStock: () => _showStockEntry(p),
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
        ],
      ),
    );
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
