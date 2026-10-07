import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchProducts();
  }

  Future<void> _reload() async {
    final f = fetchProducts();
    setState(() {
      _future = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  bool _isLow(Product p) =>
      p.stock <= 0 || (p.stockMinimo > 0 && p.stock <= p.stockMinimo);

  String _statusOf(Product p) {
    if (p.stock <= 0) return 'Agotado';
    if (p.stockMinimo > 0 && p.stock <= p.stockMinimo) return 'Bajo';
    return 'Bueno';
  }

  String _fmtMoney(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final intFmt = parts[0].replaceAllMapped(regex, (m) => ',');
    return 'Bs. $intFmt.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 46,
                      color: Color(0xFF6A7788),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo cargar el inventario',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A2540),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6A7788),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildContent(context, snapshot.data ?? []);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Product> products) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;
    final crossAxisCount = (width / 220).floor().clamp(1, 4);

    final total = products.length;
    final bajos = products.where(_isLow).length;
    final disponibles = products.length - bajos;
    final valorTotal = products.fold<double>(
      0.0,
      (sum, p) => sum + (double.tryParse(p.precioCompra) ?? 0) * p.stock,
    );

    final sorted = [...products]
      ..sort((a, b) {
        final aLow = _isLow(a) ? 0 : 1;
        final bLow = _isLow(b) ? 0 : 1;
        if (aLow != bLow) return aLow - bLow;
        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });

    return RefreshIndicator(
      onRefresh: _reload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 10 : 20,
          vertical: isPhone ? 10 : 18,
        ),
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
                        'Stock',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A2540),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Control del inventario y productos con bajo nivel.',
                        style: TextStyle(color: Color(0xFF6A7788)),
                      ),
                    ],
                  ),
                ),
                if (!isPhone)
                  GestureDetector(
                    onTap: _reload,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3E8EF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh_rounded, color: Color(0xFF0A2540)),
                          SizedBox(width: 8),
                          Text(
                            'Actualizar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0A2540),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: width >= 900
                  ? 1.8
                  : width >= 600
                  ? 1.45
                  : 1.35,
              children: [
                _SummaryTile(
                  label: 'Productos',
                  value: '$total',
                  accent: const Color(0xFF0A2540),
                ),
                _SummaryTile(
                  label: 'Stock bajo',
                  value: '$bajos',
                  accent: const Color(0xFFDBEAFE),
                ),
                _SummaryTile(
                  label: 'Disponibles',
                  value: '$disponibles',
                  accent: const Color(0xFFDCFCE7),
                ),
                _SummaryTile(
                  label: 'Valor inventario',
                  value: _fmtMoney(valorTotal),
                  accent: const Color(0xFFE0F2FE),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildInventoryList(context, sorted, width),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    List<Product> products,
    double width,
  ) {
    final compact = width < 400;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Inventario',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2540),
                  ),
                ),
              ),
              Text(
                '${products.length} productos',
                style: const TextStyle(color: Color(0xFF6A7788), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay productos registrados',
                  style: TextStyle(color: Color(0xFF6A7788)),
                ),
              ),
            )
          else
            ...products.map((p) {
              final status = _statusOf(p);
              final critical = status != 'Bueno';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: compact ? 2 : 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF0A2540),
                              fontWeight: FontWeight.w600,
                              fontSize: compact ? 11.5 : 13,
                            ),
                          ),
                          Text(
                            compact
                                ? '${p.marca ?? 'Sin marca'}  •  ${p.stock} u.'
                                : p.marca ?? 'Sin marca',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5A6471),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${p.stock} u.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF5A6471),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 62,
                        child: Text(
                          'mín. ${p.stockMinimo}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF5A6471),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: critical
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE7F7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: critical
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF228B57),
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 9.5 : 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: compact ? 55 : 90,
                      child: Text(
                        'Bs. ${p.precioVenta}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A2540),
                          fontSize: compact ? 10.5 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;
    final isDesktop = width >= 900;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(
            isSmall
                ? 12
                : isDesktop
                ? 14
                : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isDesktop
                    ? 30
                    : isSmall
                    ? 28
                    : 36,
                height: isDesktop
                    ? 30
                    : isSmall
                    ? 28
                    : 36,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(
                height: isDesktop
                    ? 10
                    : isSmall
                    ? 10
                    : 14,
              ),
              SizedBox(
                width: constraints.maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isDesktop
                          ? 18
                          : isSmall
                          ? 18
                          : 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A2540),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isDesktop
                      ? 11
                      : isSmall
                      ? 11
                      : 12,
                  color: const Color(0xFF6A7788),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
