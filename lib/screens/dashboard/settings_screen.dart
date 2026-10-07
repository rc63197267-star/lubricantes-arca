import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/server_config.dart';
import '../../utils/input_rules.dart';

class SettingsScreen extends StatefulWidget {
  final Usuario? usuario;
  const SettingsScreen({super.key, this.usuario});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<List<Usuario>> _futuroUsers;
  final TextEditingController _hostCtrl = TextEditingController();
  final TextEditingController _portCtrl = TextEditingController();
  String _serverStatus = '';
  bool _testing = false;
  bool _https = false;

  bool get _esAdmin => widget.usuario?.esAdmin ?? false;

  @override
  void initState() {
    super.initState();
    final cfg = ServerConfig.instance;
    if (cfg != null) {
      _hostCtrl.text = cfg.host;
      _portCtrl.text = '${cfg.port}';
      _https = cfg.enableHttps;
    }
    _futuroUsers = _esAdmin ? fetchUsuarios() : Future.value(const []);
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _probarServidor() async {
    setState(() {
      _testing = true;
      _serverStatus = '';
    });
    final cfg = ServerConfig();
    cfg.host = _hostCtrl.text.trim().isEmpty
        ? '127.0.0.1'
        : _hostCtrl.text.trim();
    cfg.port = int.tryParse(_portCtrl.text.trim()) ?? 8000;
    final ok = await testServerConnectionWith(
      host: cfg.host,
      port: cfg.port,
      enableHttps: _https,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _serverStatus = ok
          ? '🟢 Conectado al servidor'
          : '🔴 No se pudo conectar.\nVerifica que la PC esté encendida, el servidor corriendo y estés en la misma Wi-Fi.';
    });
  }

  Future<void> _guardarServidor() async {
    final cfg = ServerConfig();
    cfg.host = _hostCtrl.text.trim().isEmpty
        ? '127.0.0.1'
        : _hostCtrl.text.trim();
    cfg.port = int.tryParse(_portCtrl.text.trim()) ?? 8000;
    cfg.enableHttps = _https;
    await saveServerConfig(cfg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración del servidor guardada')),
    );
  }

  void _reload() {
    setState(() {
      _futuroUsers = fetchUsuarios();
    });
  }

  Widget _buildServidorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servidor (PC principal)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A2540),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dirección a la que se conectan la app y los celulares.',
            style: TextStyle(color: Color(0xFF6A7788), fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hostCtrl,
            onChanged: (_) => setState(() => _serverStatus = ''),
            decoration: InputDecoration(
              labelText: 'Dirección del servidor',
              hintText:
                  'IP local o dominio (ej: 192.168.1.100 o app.tudominio.com)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: InputRules.digits,
            onChanged: (_) => setState(() => _serverStatus = ''),
            decoration: InputDecoration(
              labelText: 'Puerto de la API',
              hintText: 'Ej: 8000 (con HTTPS suele ser 443)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Usar HTTPS (para ver desde Internet)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A2540),
              ),
            ),
            subtitle: const Text(
              'Actívalo si te conectas por un dominio seguro (ej. Cloudflare Tunnel).',
              style: TextStyle(fontSize: 12, color: Color(0xFF6A7788)),
            ),
            value: _https,
            activeThumbColor: const Color(0xFF3B82F6),
            onChanged: (v) => setState(() {
              _https = v;
              _serverStatus = '';
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testing ? null : _probarServidor,
                  icon: const Icon(Icons.settings_ethernet_outlined),
                  label: Text(_testing ? 'Probando...' : 'Probar conexión'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _guardarServidor,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
          if (_serverStatus.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _serverStatus,
              style: const TextStyle(fontSize: 12, color: Color(0xFF3E4756)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _nuevoVendedor() async {
    final nombreCtrl = TextEditingController();
    final usuarioCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final creado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo vendedor'),
        content: Form(
          key: formKey,
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
                controller: usuarioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Usuario (para login)',
                ),
                inputFormatters: InputRules.alphanumeric,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Contraseña por defecto: 123456789',
                style: TextStyle(color: Color(0xFF6A7788), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(ctx);
              try {
                await createUsuario(
                  nombre: nombreCtrl.text.trim(),
                  usuario: usuarioCtrl.text.trim(),
                );
                navigator.pop(true);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Crear vendedor'),
          ),
        ],
      ),
    );

    if (creado == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendedor creado (contraseña 123456789)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final isPhone = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 12 : 20,
          vertical: isPhone ? 12 : 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuración',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu cuenta y la gestión de usuarios del sistema.',
                style: TextStyle(color: Color(0xFF6A7788)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3E8EF)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: Color(0xFF0A2540),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u?.nombre ?? 'Usuario',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A2540),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${u?.usuario ?? '-'}',
                            style: const TextStyle(color: Color(0xFF6A7788)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _esAdmin
                            ? const Color(0xFFE7F7ED)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _esAdmin ? 'ADMIN' : 'VENDEDOR',
                        style: TextStyle(
                          color: _esAdmin
                              ? const Color(0xFF228B57)
                              : const Color(0xFF0A2540),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_esAdmin) ...[
                _buildServidorCard(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
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
                              'Gestión de usuarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A2540),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _nuevoVendedor,
                            icon: const Icon(Icons.person_add_alt_rounded),
                            label: const Text('Nuevo vendedor'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Usuario>>(
                        future: _futuroUsers,
                        builder: (ctx, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snap.hasError) {
                            return Text('Error: ${snap.error}');
                          }
                          final users = snap.data ?? [];
                          if (users.isEmpty) {
                            return const Text(
                              'No hay usuarios.',
                              style: TextStyle(color: Color(0xFF6A7788)),
                            );
                          }
                          return Column(
                            children: users
                                .map(
                                  (us) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      us.esAdmin
                                          ? Icons.admin_panel_settings
                                          : Icons.person_outline,
                                      color: const Color(0xFF0A2540),
                                    ),
                                    title: Text(us.nombre),
                                    subtitle: Text('@${us.usuario}'),
                                    trailing: Text(
                                      us.rol,
                                      style: TextStyle(
                                        color: us.esAdmin
                                            ? const Color(0xFF228B57)
                                            : const Color(0xFF6A7788),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
