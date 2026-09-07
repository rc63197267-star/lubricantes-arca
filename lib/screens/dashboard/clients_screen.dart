import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late Future<List<Client>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchClients();
  }

  Future<void> _reload() async {
    final f = fetchClients();
    setState(() {
      _future = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Client>>(
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
                    'No se pudo cargar los clientes',
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
          return _buildContent(context, snapshot.data ?? []);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Client> clients) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;
    final crossAxisCount = (width / 220).floor().clamp(1, 4);

    final total = clients.length;
    final activos = clients.where((c) => c.estado == 'ACTIVO').length;
    final conTelefono = clients
        .where((c) => (c.telefono ?? '').isNotEmpty)
        .length;
    final conCorreo = clients.where((c) => (c.correo ?? '').isNotEmpty).length;

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Clientes',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A2540),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Relación con clientes y actividad comercial.',
                        style: TextStyle(color: Color(0xFF6A7788)),
                      ),
                    ],
                  ),
                ),
                if (!isPhone)
                  GestureDetector(
                    onTap: _showCreateDialog,
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
                          Icon(
                            Icons.person_add_alt_rounded,
                            color: Color(0xFF0A2540),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Nuevo cliente',
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
            if (isPhone) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.person_add_alt_rounded),
                  label: const Text('Nuevo cliente'),
                ),
              ),
            ],
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
                _StatCard(
                  label: 'Total clientes',
                  value: '$total',
                  accent: const Color(0xFF0A2540),
                ),
                _StatCard(
                  label: 'Activos',
                  value: '$activos',
                  accent: const Color(0xFFDCFCE7),
                ),
                _StatCard(
                  label: 'Con teléfono',
                  value: '$conTelefono',
                  accent: const Color(0xFFDBEAFE),
                ),
                _StatCard(
                  label: 'Con correo',
                  value: '$conCorreo',
                  accent: const Color(0xFFE7F7ED),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
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
                          'Clientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A2540),
                          ),
                        ),
                      ),
                      Text(
                        '${clients.length} registrados',
                        style: const TextStyle(
                          color: Color(0xFF6A7788),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (clients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No hay clientes registrados',
                          style: TextStyle(color: Color(0xFF6A7788)),
                        ),
                      ),
                    )
                  else
                    ...clients.map((c) => _buildClientRow(c, width)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientRow(Client c, double width) {
    final compact = width < 400;
    final activo = c.estado == 'ACTIVO';
    final contacto = [
      if ((c.telefono ?? '').isNotEmpty) 'Tel: ${c.telefono}',
      if ((c.correo ?? '').isNotEmpty) c.correo!,
      if ((c.direccion ?? '').isNotEmpty) c.direccion!,
    ].join('  •  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF0A2540),
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 11.5 : 13,
                  ),
                ),
                if (contacto.isNotEmpty)
                  Text(
                    contacto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF5A6471),
                      fontSize: compact ? 10.5 : 11.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activo ? const Color(0xFFE7F7ED) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activo ? 'ACTIVO' : 'INACTIVO',
              style: TextStyle(
                color: activo
                    ? const Color(0xFF228B57)
                    : const Color(0xFFB91C1C),
                fontWeight: FontWeight.w700,
                fontSize: compact ? 9.5 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String telefono = '';
    String correo = '';
    String direccion = '';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onSaved: (v) => nombre = v?.trim() ?? '',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  onSaved: (v) => telefono = v?.trim() ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (v) => correo = v?.trim() ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  onSaved: (v) => direccion = v?.trim() ?? '',
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
                final client = Client(
                  id: 0,
                  nombre: nombre,
                  telefono: telefono.isEmpty ? null : telefono,
                  correo: correo.isEmpty ? null : correo,
                  direccion: direccion.isEmpty ? null : direccion,
                );
                try {
                  await createClient(client);
                  navigator.pop(true);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error creando cliente: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _future = fetchClients();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cliente creado')));
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
                : 34,
            height: isDesktop
                ? 30
                : isSmall
                ? 28
                : 34,
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
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  }
}
