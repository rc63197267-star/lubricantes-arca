import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/metric_card.dart';

String _fmtFecha(String f) {
  if (f.length < 16) return f;
  final d = f.substring(0, 10).split('-');
  return '${d[2]}/${d[1]} ${f.substring(11, 16)}';
}

String _fmtMoney(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return 'Bs. ${parts[0].replaceAllMapped(regex, (m) => ',')}.${parts[1]}';
}

class SalesTable extends StatelessWidget {
  const SalesTable({super.key, required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    if (sales.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No hay ventas registradas',
            style: TextStyle(color: Color(0xFF6A7788)),
          ),
        ),
      );
    }

    final recents = sales.take(6).toList();

    if (isPhone) {
      return Column(
        children: recents.map((s) {
          final completada = s.estado == 'COMPLETADA';
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
                        s.numero,
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
                          color: completada
                              ? const Color(0xFFE7F7ED)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          completada ? 'Completado' : 'Anulado',
                          style: TextStyle(
                            color: completada
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
                    s.cliente,
                    style: const TextStyle(
                      color: Color(0xFF3E4756),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (s.productos != null && s.productos!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.productos!,
                      style: const TextStyle(
                        color: Color(0xFF6A7788),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmtFecha(s.fecha),
                        style: const TextStyle(
                          color: Color(0xFF6A7788),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Bs. ${s.total}',
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
                'ID Pedido',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Cliente',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Fecha',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Estado',
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
                  'Monto',
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
        ...recents.map((s) {
          final completada = s.estado == 'COMPLETADA';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.numero,
                    style: const TextStyle(
                      color: Color(0xFF0A2540),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.cliente,
                        style: const TextStyle(color: Color(0xFF3E4756)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (s.productos != null && s.productos!.isNotEmpty)
                        Text(
                          s.productos!,
                          style: const TextStyle(
                            color: Color(0xFF6A7788),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    _fmtFecha(s.fecha),
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
                      color: completada
                          ? const Color(0xFFE7F7ED)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      completada ? 'Completado' : 'Anulado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: completada
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
                    'Bs. ${s.total}',
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

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() {
    return Future.wait([fetchProducts(), fetchSales()]);
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() {
      _future = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  bool _isLow(Product p) =>
      p.stock <= 0 || (p.stockMinimo > 0 && p.stock <= p.stockMinimo);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;
    final isDesktop = width >= 900;
    final gridColumns = (width / 260).floor().clamp(1, 4);

    return SafeArea(
      child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: Color(0xFF6A7788),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No se pudo cargar el resumen',
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
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final productos = snapshot.data![0] as List<Product>;
          final ventas = snapshot.data![1] as List<Sale>;

          final ingresos = ventas.fold<double>(
            0,
            (s, v) => s + (double.tryParse(v.total) ?? 0),
          );
          final lowStock = productos.where(_isLow).toList();

          return RefreshIndicator(
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 12 : 20,
                vertical: isPhone ? 12 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen',
                              style: TextStyle(
                                fontSize: isPhone ? 24 : 32,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A2540),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Resumen general del negocio.',
                              style: TextStyle(
                                fontSize: isPhone ? 13 : 16,
                                color: const Color(0xFF6A7788),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: gridColumns,
                    crossAxisSpacing: isPhone ? 10 : 18,
                    mainAxisSpacing: isPhone ? 10 : 18,
                    childAspectRatio: width >= 900
                        ? 1.8
                        : isPhone
                        ? 1.5
                        : 1.7,
                    children: [
                      MetricCard(
                        titulo: 'Ingresos totales',
                        valor: _fmtMoney(ingresos),
                        trend: '${ventas.length} ventas registradas',
                        icono: Icons.payments_outlined,
                        accento: const Color(0xFFECF3FF),
                        positivo: true,
                      ),
                      MetricCard(
                        titulo: 'Ventas registradas',
                        valor: '${ventas.length}',
                        trend: 'Actualizado ahora',
                        icono: Icons.point_of_sale_outlined,
                        accento: const Color(0xFFECF3FF),
                        positivo: false,
                      ),
                      MetricCard(
                        titulo: 'Total de productos',
                        valor: '${productos.length}',
                        trend: 'En inventario',
                        icono: Icons.widgets_outlined,
                        accento: const Color(0xFFECF3FF),
                        positivo: false,
                      ),
                      WarningMetricCard(
                        titulo: 'Stock\nbajo',
                        valor: '${lowStock.length}',
                        subtitulo: 'Productos requieren reabastecimiento',
                        icono: Icons.warning_amber_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildSalesGrowthCard(ventas)),
                        const SizedBox(width: 18),
                        Expanded(child: _buildLowStockCard(lowStock)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildSalesGrowthCard(ventas),
                        const SizedBox(height: 18),
                        _buildLowStockCard(lowStock),
                      ],
                    ),
                  const SizedBox(height: 28),
                  Container(
                    padding: EdgeInsets.all(isPhone ? 12 : 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE3E8EF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ventas recientes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A2540),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SalesTable(sales: ventas),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesGrowthCard(List<Sale> ventas) {
    final now = DateTime.now();
    final dias = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final sales = ventas.where((v) => v.fecha.startsWith(key)).toList();
      final label = i == 0
          ? 'Hoy'
          : i == 1
          ? 'Ayer'
          : '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';
      dias.add({'label': label, 'sales': sales});
    }
    final diasConActividad = dias
        .where((d) => (d['sales'] as List).isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ventas por día',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
              Text(
                'Últimos 7 días',
                style: TextStyle(fontSize: 12, color: Color(0xFF6A7788)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (diasConActividad.isEmpty)
            const Text(
              'Sin ventas en los últimos 7 días',
              style: TextStyle(color: Color(0xFF6A7788)),
            )
          else
            ...diasConActividad.map((d) {
              final sales = d['sales'] as List<Sale>;
              final total = sales.fold<double>(
                0,
                (s, v) => s + (double.tryParse(v.total) ?? 0),
              );
              final nombres = sales
                  .map((s) => s.productos)
                  .where((p) => p != null && p.isNotEmpty)
                  .toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${d['label']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A2540),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sales.length} venta(s) • ${_fmtMoney(total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E4756),
                              fontSize: 12.5,
                            ),
                          ),
                          if (nombres.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            ...nombres.map(
                              (n) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '• $n',
                                  style: const TextStyle(
                                    color: Color(0xFF6A7788),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildLowStockCard(List<Product> lowStock) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bajo stock',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
              Text(
                '${lowStock.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (lowStock.isEmpty)
            const Text(
              'Todo el inventario está en niveles saludables ✓',
              style: TextStyle(color: Color(0xFF228B57)),
            )
          else
            ...lowStock
                .take(5)
                .map(
                  (p) => TopProductRow(
                    nombre: p.nombre,
                    sku: 'mín. ${p.stockMinimo}',
                    ventas: p.stock,
                  ),
                ),
        ],
      ),
    );
  }
}
