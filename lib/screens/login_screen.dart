import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/server_config.dart';
import '../utils/input_rules.dart';
import 'dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioCtrl = TextEditingController();
  final TextEditingController _contrasenaCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    final usuario = _usuarioCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text;
    if (usuario.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa usuario y contraseña')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await login(usuario, contrasena);
      if (!mounted) return;
      if (user == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos')),
        );
        return;
      }
      usuarioActual = user;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardHomePage(usuario: user)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo conectar con el servidor.\nVerifica que la PC esté encendida, el servidor corriendo y estés en la misma red.',
          ),
        ),
      );
    }
  }

  Future<void> _configurarServidor() async {
    final cfg = ServerConfig.instance ?? ServerConfig();
    final hostCtrl = TextEditingController(text: cfg.host);
    final portCtrl = TextEditingController(text: '${cfg.port}');
    bool https = cfg.enableHttps;
    String status = '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Configurar servidor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hostCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección (IP o dominio)',
                    hintText: 'Ej: lubricantes-arca-api.onrender.com',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: portCtrl,
                  decoration: const InputDecoration(labelText: 'Puerto'),
                  keyboardType: TextInputType.number,
                  inputFormatters: InputRules.digits,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usar HTTPS (desde Internet)'),
                  value: https,
                  onChanged: (v) => setDlg(() => https = v),
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3E4756),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final host = hostCtrl.text.trim().isEmpty
                    ? '127.0.0.1'
                    : hostCtrl.text.trim();
                final port = int.tryParse(portCtrl.text.trim()) ?? 8000;
                final ok = await testServerConnectionWith(
                  host: host,
                  port: port,
                  enableHttps: https,
                );
                if (!ctx.mounted) return;
                setDlg(() {
                  status = ok
                      ? '🟢 Conectado'
                      : '🔴 No se pudo conectar. Verifica la IP, el puerto y que el celular esté en la misma Wi-Fi.';
                });
              },
              child: const Text('Probar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nueva = ServerConfig();
                nueva.host = hostCtrl.text.trim().isEmpty
                    ? '127.0.0.1'
                    : hostCtrl.text.trim();
                nueva.port = int.tryParse(portCtrl.text.trim()) ?? 8000;
                nueva.enableHttps = https;
                await saveServerConfig(nueva);
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Servidor guardado')),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.oil_barrel,
                  size: 56,
                  color: Color(0xFF0A2540),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lubricantes Arca',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2540),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicia sesión para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6A7788)),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usuarioCtrl,
                  inputFormatters: InputRules.alphanumeric,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contrasenaCtrl,
                  obscureText: _obscure,
                  onSubmitted: (_) => _ingresar(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _ingresar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF0A2540),
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Ingresar'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Servidor: ${apiBaseUrl()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6A7788),
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: _configurarServidor,
                  icon: const Icon(Icons.settings_ethernet_outlined, size: 18),
                  label: const Text('Configurar servidor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
