import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../utils/input_rules.dart';
import '../../widgets/sale_product_card.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late Future<List<Product>> _productsFuture;
  late Future<List<Client>> _clientsFuture;
  late Future<List<Categoria>> _categoriesFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _cashReceivedCtrl = TextEditingController();
  final Map<int, int> _cart = <int, int>{};

  List<Product> _products = <Product>[];
  List<Client> _clients = <Client>[];
  List<Categoria> _categories = <Categoria>[];

  String _query = '';
  int? _selectedCategoryId;
  int? _selectedClientId;
  String _paymentMethod = 'EFECTIVO';
  int _mobileStep = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
    _clientsFuture = fetchClients();
    _categoriesFuture = fetchCategorias();
    _hydrate();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    _cashReceivedCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    try {
      final results = await Future.wait<dynamic>([
        _productsFuture,
        _clientsFuture,
        _categoriesFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _clients = results[1] as List<Client>;
        _categories = results[2] as List<Categoria>;
      });
    } catch (_) {}
  }

  Future<void> _reloadAll() async {
    final productsFuture = fetchProducts();
    final clientsFuture = fetchClients();
    final categoriesFuture = fetchCategorias();

    setState(() {
      _productsFuture = productsFuture;
      _clientsFuture = clientsFuture;
      _categoriesFuture = categoriesFuture;
    });

    try {
      final results = await Future.wait<dynamic>([
        productsFuture,
        clientsFuture,
        categoriesFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _clients = results[1] as List<Client>;
        _categories = results[2] as List<Categoria>;
      });
    } catch (_) {}
  }

  List<Product> _filteredProducts(List<Product> items) {
    final q = _query.toLowerCase();
    return items.where((p) {
      final matchesText =
          q.isEmpty ||
          p.nombre.toLowerCase().contains(q) ||
          (p.marca?.toLowerCase().contains(q) ?? false) ||
          p.codigo.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategoryId == null || p.idCategoria == _selectedCategoryId;
      return matchesText && matchesCategory;
    }).toList();
  }

  Product? _productById(int id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  int _cartCount() => _cart.values.fold<int>(0, (sum, value) => sum + value);

  double _cartTotal() {
    var total = 0.0;
    for (final entry in _cart.entries) {
      final p = _productById(entry.key);
      if (p == null) continue;
      total +=
          (double.tryParse(p.precioVenta.replaceAll(',', '.')) ?? 0) *
          entry.value;
    }
    return total;
  }

  double _discountValue() {
    return double.tryParse(_discountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
  }

  double _finalTotal() {
    final result = _cartTotal() - _discountValue();
    return result < 0 ? 0 : result;
  }

  double _cashReceivedValue() {
    return double.tryParse(
          _cashReceivedCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  double _changeDue() {
    final change = _cashReceivedValue() - _finalTotal();
    return change < 0 ? 0 : change;
  }

  int? get _generalClientId {
    for (final client in _clients) {
      final name = client.nombre.trim().toLowerCase();
      if (name == 'cliente general' || name == 'consumidor final') {
        return client.id;
      }
    }
    return null;
  }

  bool _isLow(Product p) =>
      p.stock == 0 || (p.stockMinimo > 0 && p.stock <= p.stockMinimo);

  void _addOne(Product p) {
    if (p.stock <= 0) return;
    final current = _cart[p.id] ?? 0;
    if (current >= p.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más stock disponible')),
      );
      return;
    }
    setState(() => _cart[p.id] = current + 1);
  }

  void _removeOne(Product p) {
    final current = _cart[p.id] ?? 0;
    if (current <= 0) return;
    setState(() {
      if (current == 1) {
        _cart.remove(p.id);
      } else {
        _cart[p.id] = current - 1;
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _discountCtrl.text = '0';
      _cashReceivedCtrl.clear();
      _mobileStep = 0;
    });
  }

  Future<void> _registerSale() async {
    if (_cart.isEmpty || _saving) return;

    final subtotal = _cartTotal();
    final descuento = _discountValue();
    if (descuento < 0 || descuento > subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El descuento debe estar entre Bs. 0 y el subtotal.'),
        ),
      );
      return;
    }

    if (_paymentMethod == 'EFECTIVO' && _cashReceivedValue() < _finalTotal()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto recibido es menor al total a pagar.'),
        ),
      );
      return;
    }

    final clientId = _selectedClientId ?? _generalClientId;
    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un cliente o crea "Cliente general" para venta rápida.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final items = _cart.entries.map((entry) {
      final p = _productById(entry.key)!;
      return <String, dynamic>{
        'id_producto': p.id,
        'cantidad': entry.value,
        'precio_unitario':
            double.tryParse(p.precioVenta.replaceAll(',', '.')) ?? 0,
      };
    }).toList();

    final sale = Sale(
      id: 0,
      numero: '',
      idCliente: clientId,
      cliente: '',
      fecha: '',
      metodoPago: _paymentMethod,
      descuento: descuento.toStringAsFixed(2),
      montoRecibido: _paymentMethod == 'EFECTIVO'
          ? _cashReceivedValue().toStringAsFixed(2)
          : '0',
      total: (subtotal - descuento).toStringAsFixed(2),
      estado: '',
    );

    try {
      await createSale(sale, items);
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _selectedClientId = null;
        _paymentMethod = 'EFECTIVO';
        _discountCtrl.text = '0';
        _cashReceivedCtrl.clear();
        _mobileStep = 0;
      });
      await _reloadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar la venta: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return _mobileStep == 0
              ? _buildMobileProducts()
              : _buildMobileCheckout();
        }
        return _buildWideLayout(constraints.maxWidth);
      },
    );
  }

  Widget _buildMobileProducts() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle('Ventas', 'Paso 1: Agregar productos'),
                    const SizedBox(height: 14),
                    _buildSearch(),
                    const SizedBox(height: 12),
                    _buildCategoryChips(),
                    const SizedBox(height: 14),
                    _buildProductGrid(compact: true),
                  ],
                ),
              ),
            ),
          ),
          _buildMobileCartBar(),
        ],
      ),
    );
  }

  Widget _buildMobileCheckout() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver a productos',
                        onPressed: () => setState(() => _mobileStep = 0),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ventas',
                              style: TextStyle(
                                color: Color(0xFF0A2540),
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Paso 2: Revisar y pagar',
                              style: TextStyle(
                                color: Color(0xFF6A7788),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildCartItemsCard(),
                  const SizedBox(height: 12),
                  _buildClientSection(),
                  const SizedBox(height: 12),
                  _buildPaymentSection(),
                  const SizedBox(height: 12),
                  _buildSummaryCard(),
                ],
              ),
            ),
          ),
          _buildRegisterBar(),
        ],
      ),
    );
  }

  Widget _buildWideLayout(double width) {
    final panelWidth = width < 1050 ? 340.0 : 400.0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reloadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('Ventas', 'Agrega productos al carrito'),
                      const SizedBox(height: 14),
                      _buildSearch(),
                      const SizedBox(height: 12),
                      _buildCategoryChips(),
                      const SizedBox(height: 14),
                      _buildProductGrid(compact: false),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(width: panelWidth, child: _buildDesktopCheckoutPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0A2540),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6A7788), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (value) => setState(() => _query = value.trim()),
      decoration: InputDecoration(
        hintText: 'Buscar producto, marca o código...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E1EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E1EC)),
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildCategoryChips() {
    return FutureBuilder<List<Categoria>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? _categories;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _categoryChip(null, 'Todos', Icons.grid_view_rounded),
              ...categories.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _categoryChip(c.id, c.nombre, _categoryIcon(c.nombre)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('aceite')) return Icons.water_drop_outlined;
    if (value.contains('filtro')) return Icons.filter_alt_outlined;
    if (value.contains('grasa')) return Icons.settings_outlined;
    if (value.contains('refriger')) return Icons.ac_unit_rounded;
    return Icons.category_outlined;
  }

  Widget _categoryChip(int? id, String label, IconData icon) {
    final selected = _selectedCategoryId == id;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedCategoryId = id),
      avatar: Icon(
        icon,
        size: 17,
        color: selected ? Colors.white : const Color(0xFF0A2540),
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF0A2540),
        fontWeight: FontWeight.w700,
      ),
      selectedColor: const Color(0xFF1677F2),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFDCE3ED)),
      showCheckmark: false,
    );
  }

  Widget _buildProductGrid({required bool compact}) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(42),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _messageCard(
            icon: Icons.error_outline_rounded,
            title: 'No se pudieron cargar los productos',
            actionLabel: 'Reintentar',
            onAction: _reloadAll,
          );
        }

        final all = snapshot.data ?? <Product>[];
        if (_products.isEmpty && all.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _products.isEmpty) {
              setState(() => _products = all);
            }
          });
        }

        final products = _filteredProducts(all);

        if (products.isEmpty) {
          return _messageCard(
            icon: Icons.search_off_rounded,
            title: 'No hay productos que coincidan',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            int columns;

            if (compact) {
              columns = w < 330 ? 1 : 2;
            } else if (w < 560) {
              columns = 2;
            } else if (w < 820) {
              columns = 3;
            } else {
              columns = 4;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: compact ? 285 : 295,
              ),
              itemBuilder: (context, index) {
                final p = products[index];
                final quantity = _cart[p.id] ?? 0;

                return SaleProductCard(
                  nombre: p.nombre,
                  marca: p.marca ?? '-',
                  precio: 'Bs. ${p.precioVenta}',
                  stock: p.stock,
                  cantidad: quantity,
                  lowStock: _isLow(p),
                  imagen: fullImageUrl(p.imagen),
                  onAdd: p.stock <= 0 ? null : () => _addOne(p),
                  onRemove: quantity <= 0 ? null : () => _removeOne(p),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMobileCartBar() {
    final count = _cartCount();
    final total = _cartTotal();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Color(0xFF0A3D7A),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 29,
                ),
                if (count > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0 ? 'Carrito vacío' : '$count producto(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Total Bs. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFD9E9FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: count == 0
                  ? null
                  : () => setState(() => _mobileStep = 1),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                disabledBackgroundColor: const Color(0xFF64748B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Continuar'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCheckoutPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCartHeader(),
                  const SizedBox(height: 12),
                  if (_cart.isEmpty)
                    _emptyCart()
                  else ...[
                    _buildCartItemsList(),
                    const SizedBox(height: 14),
                    _buildClientSection(),
                    const SizedBox(height: 14),
                    _buildPaymentSection(),
                    const SizedBox(height: 14),
                    _buildSummaryCard(),
                  ],
                ],
              ),
            ),
          ),
          if (_cart.isNotEmpty) _buildRegisterBar(),
        ],
      ),
    );
  }

  Widget _buildCartItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCartHeader(),
          const SizedBox(height: 10),
          _buildCartItemsList(),
        ],
      ),
    );
  }

  Widget _buildCartHeader() {
    return Row(
      children: [
        const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0A2540)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Carrito de venta (${_cartCount()})',
            style: const TextStyle(
              color: Color(0xFF0A2540),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (_cart.isNotEmpty)
          TextButton.icon(
            onPressed: _clearCart,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Vaciar'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD14343),
            ),
          ),
      ],
    );
  }

  Widget _buildCartItemsList() {
    return Column(
      children: _cart.entries.map((entry) {
        final p = _productById(entry.key);
        if (p == null) return const SizedBox.shrink();

        final qty = entry.value;
        final unit = double.tryParse(p.precioVenta.replaceAll(',', '.')) ?? 0.0;
        final subtotal = unit * qty;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _smallProductImage(p),
              const SizedBox(width: 9),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bs. ${unit.toStringAsFixed(2)} c/u',
                      style: const TextStyle(
                        color: Color(0xFF6A7788),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _cartQtyControls(p, qty),
              const SizedBox(width: 8),
              SizedBox(
                width: 66,
                child: Text(
                  'Bs. ${subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF0A2540),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _smallProductImage(Product p) {
    final image = fullImageUrl(p.imagen);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F8),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: image.isEmpty
          ? const Icon(Icons.oil_barrel_rounded, color: Color(0xFF4C7ED9))
          : Image.network(
              image,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.oil_barrel_rounded,
                color: Color(0xFF4C7ED9),
              ),
            ),
    );
  }

  Widget _cartQtyControls(Product p, int qty) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6DEE9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniQtyButton(Icons.remove, qty > 0 ? () => _removeOne(p) : null),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          _miniQtyButton(Icons.add, qty < p.stock ? () => _addOne(p) : null),
        ],
      ),
    );
  }

  Widget _miniQtyButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 32,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? const Color(0xFFB6C0CE)
              : const Color(0xFF1665D8),
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return _sectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Cliente',
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey(_selectedClientId),
            initialValue: _selectedClientId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: _generalClientId == null
                  ? 'Seleccionar cliente'
                  : 'Cliente general (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            items: _clients
                .where((c) => c.id != _generalClientId)
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedClientId = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_generalClientId != null)
                Expanded(
                  child: Text(
                    _selectedClientId == null
                        ? 'Se usará Cliente general'
                        : 'Cliente seleccionado',
                    style: const TextStyle(
                      color: Color(0xFF6A7788),
                      fontSize: 11,
                    ),
                  ),
                )
              else
                const Spacer(),
              TextButton.icon(
                onPressed: _createClientDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Nuevo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final recibido = _cashReceivedValue();
    final total = _finalTotal();
    final falta = total - recibido;

    return _sectionCard(
      icon: Icons.credit_card_rounded,
      title: 'Método de pago',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _paymentOption(
                  'EFECTIVO',
                  'Efectivo',
                  Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _paymentOption(
                  'TARJETA',
                  'Tarjeta',
                  Icons.credit_card_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _paymentOption('QR', 'QR', Icons.qr_code_2_rounded),
              ),
            ],
          ),
          if (_paymentMethod == 'EFECTIVO') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _cashReceivedCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: InputRules.money,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Monto recibido',
                prefixText: 'Bs. ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: recibido > 0 && recibido < total
                    ? 'Faltan Bs. ${falta.toStringAsFixed(2)}'
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: recibido >= total && total > 0
                    ? const Color(0xFFEAF6EE)
                    : const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: recibido >= total && total > 0
                      ? const Color(0xFF86D7A2)
                      : const Color(0xFFDDE5EF),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_exchange_rounded,
                    color: recibido >= total && total > 0
                        ? const Color(0xFF15803D)
                        : const Color(0xFF6A7788),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cambio a devolver',
                      style: TextStyle(
                        color: Color(0xFF0A2540),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Bs. ${_changeDue().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: recibido >= total && total > 0
                          ? const Color(0xFF15803D)
                          : const Color(0xFF0A2540),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF6EE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? const Color(0xFF16A34A) : const Color(0xFFDDE5EF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF15803D)
                  : const Color(0xFF0A2540),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF15803D)
                    : const Color(0xFF0A2540),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final subtotal = _cartTotal();
    final descuento = _discountValue();
    final descuentoInvalido = descuento < 0 || descuento > subtotal;

    return _sectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Resumen de venta',
      child: Column(
        children: [
          _summaryRow('Total de productos', '${_cartCount()}'),
          const SizedBox(height: 8),
          _summaryRow('Subtotal', 'Bs. ${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Descuento',
                  style: TextStyle(color: Color(0xFF6A7788), fontSize: 13),
                ),
              ),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: InputRules.money,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: 'Bs. ',
                    hintText: '0.00',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    errorText: descuentoInvalido ? 'Inválido' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (descuento > 0 && !descuentoInvalido) ...[
            const SizedBox(height: 8),
            _summaryRow('Ahorro', '- Bs. ${descuento.toStringAsFixed(2)}'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Text(
                'Total a pagar',
                style: TextStyle(
                  color: Color(0xFF0A2540),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Bs. ${_finalTotal().toStringAsFixed(2)}',
                style: TextStyle(
                  color: descuentoInvalido
                      ? const Color(0xFFD14343)
                      : const Color(0xFF0B57D0),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF6A7788), fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0A2540),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0A2540), size: 21),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0A2540),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildRegisterBar() {
    final descuento = _discountValue();
    final descuentoValido = descuento >= 0 && descuento <= _cartTotal();
    final efectivoValido =
        _paymentMethod != 'EFECTIVO' || _cashReceivedValue() >= _finalTotal();
    final enabled =
        _cart.isNotEmpty && !_saving && descuentoValido && efectivoValido;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: enabled ? _registerSale : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              _saving ? 'Registrando...' : 'Registrar venta',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 44,
            color: Color(0xFF90A0B5),
          ),
          SizedBox(height: 10),
          Text(
            'Todavía no agregaste productos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0A2540),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Usa los botones + de las tarjetas para armar la venta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6A7788), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF6A7788)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF3E4756)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  Future<void> _createClientDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final id = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  inputFormatters: InputRules.personName,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: InputRules.digits,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final phone = phoneCtrl.text.trim();
              final email = emailCtrl.text.trim();

              final client = Client(
                id: 0,
                nombre: nameCtrl.text.trim(),
                telefono: phone.isEmpty ? null : phone,
                correo: email.isEmpty ? null : email,
              );

              try {
                final newId = await createClient(client);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, newId);
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Error al crear cliente: $e')),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (id == null || !mounted) return;

    final clientsFuture = fetchClients();
    setState(() {
      _clientsFuture = clientsFuture;
    });

    try {
      final clients = await clientsFuture;
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _selectedClientId = id;
      });
    } catch (_) {}
  }
}
