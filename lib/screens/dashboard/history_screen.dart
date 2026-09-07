import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Movimiento>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchMovimientos();
  }

  Future<void> _reload() async {
    final f = fetchMovimientos();
    setState(() {
      _future = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  String _fecha(String f) {
    if (f.length < 16) return f;
    final d = f.substring(0, 10).split('-');
    final t = f.substring(11, 16);
    return '${d[2]}/${d[1]} $t';
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 12 : 20,
          vertical: isPhone ? 12 : 18,
        ),
        child: FutureBuilder<List<Movimiento>>(
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
                    const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFF6A7788)),
                    const SizedBox(height: 12),
                    const Text('No se pudo cargar el historial',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2540))),
                    const SizedBox(height: 6),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6A7788), fontSize: 12)),
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
            return _buildContent(context, snapshot.data ?? []);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Movimiento> movimientos) {
    final isCompact = MediaQuery.of(context).size.width < 380;
    final isPhone = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _reload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Historial',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF0A2540))),
                ),
                if (!isPhone)
                  GestureDetector(
                    onTap: _showNewMovimientoDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3E8EF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.swap_vert_rounded, color: Color(0xFF0A2540)),
                          SizedBox(width: 8),
                          Text('Nuevo movimiento',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0A2540))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (isPhone) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showNewMovimientoDialog,
                  icon: const Icon(Icons.swap_vert_rounded),
                  label: const Text('Nuevo movimiento'),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              movimientos.isEmpty
                  ? 'Movimientos de inventario: entradas, salidas, ajustes y alertas.'
                  : '${movimientos.length} movimiento(s) registrados',
              style: const TextStyle(color: Color(0xFF6A7788)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3E8EF)),
              ),
              child: Column(
                children: [
                  if (movimientos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No hay movimientos registrados',
                            style: TextStyle(color: Color(0xFF6A7788))),
                      ),
                    )
                  else
                    ...movimientos.map((m) => _buildRow(m, isCompact)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Movimiento m, bool compact) {
    final Color color;
    final IconData icon;
    final String label;
    final String signo;
    switch (m.tipo) {
      case 'ENTRADA':
        color = const Color(0xFFE7F7ED);
        icon = Icons.arrow_downward_rounded;
        label = 'Entrada';
        signo = '+';
        break;
      case 'SALIDA':
        color = const Color(0xFFFEE2E2);
        icon = Icons.arrow_upward_rounded;
        label = 'Salida';
        signo = '-';
        break;
      case 'ALERTA':
        color = const Color(0xFFFEF3C7);
        icon = Icons.warning_amber_rounded;
        label = 'Bajo stock';
        signo = '';
        break;
      default:
        color = const Color(0xFFFDEBD0);
        icon = Icons.tune_rounded;
        label = 'Ajuste';
        signo = '-';
    }

    final stockTxt = (m.stockAnterior != null && m.stockNuevo != null)
        ? 'Stock: ${m.stockAnterior} → ${m.stockNuevo}'
        : null;

    final motivoTxt = m.tipo == 'ALERTA' ? (m.observacion ?? m.motivo) : m.motivo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: compact ? 16 : 19, color: const Color(0xFF0A2540)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.producto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: const Color(0xFF0A2540), fontSize: compact ? 12.5 : 14)),
                const SizedBox(height: 3),
                Text('$label${motivoTxt.isNotEmpty ? ' • $motivoTxt' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: const Color(0xFF5A6471), fontSize: compact ? 11 : 12)),
                if (stockTxt != null) ...[
                  const SizedBox(height: 2),
                  Text(stockTxt,
                      style: TextStyle(color: const Color(0xFF6A7788), fontSize: compact ? 10 : 11.5)),
                ],
                const SizedBox(height: 2),
                Text(_fecha(m.fecha),
                    style: TextStyle(color: const Color(0xFF9AA6B5), fontSize: compact ? 10 : 11)),
              ],
            ),
          ),
          if (signo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('$signo${m.cantidad}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: const Color(0xFF0A2540), fontSize: compact ? 12 : 14)),
            ),
        ],
      ),
    );
  }

  Future<void> _showNewMovimientoDialog() async {
    final productos = await fetchProducts();
    if (!mounted) return;

    int? selectedProductId;
    String tipo = 'ENTRADA';
    String motivo = '';
    final cantidadCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Nuevo movimiento'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: productos
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                        .toList(),
                    onChanged: (v) => selectedProductId = v,
                    validator: (v) => v == null ? 'Selecciona un producto' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo de movimiento'),
                    items: const [
                      DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada (compra)')),
                      DropdownMenuItem(value: 'SALIDA', child: Text('Salida (venta)')),
                      DropdownMenuItem(value: 'AJUSTE', child: Text('Ajuste (corrección)')),
                    ],
                    onChanged: (v) => setDlg(() => tipo = v ?? 'ENTRADA'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cantidadCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Ingresa una cantidad válida' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Motivo', hintText: 'Ej: Producto dañado'),
                    onSaved: (v) => motivo = v?.trim() ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(ctx);
                  try {
                    await createMovimiento(
                      idProducto: selectedProductId!,
                      tipo: tipo,
                      cantidad: int.parse(cantidadCtrl.text.trim()),
                      motivo: motivo.isEmpty ? null : motivo,
                    );
                    navigator.pop(true);
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      await _reload();
    }
  }
}