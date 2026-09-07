import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as paths;

/// Configuración centralizada del servidor API.
///
/// IP del servidor, puerto y URL base en un solo lugar, persistida en
/// `lubricantes_arca_config.json` dentro de Documentos. Así se cambia
/// fácilmente para Windows o para celulares Android (red Wi-Fi local).
class ServerConfig {
  static const cloudHost = 'lubricantes-arca-api.onrender.com';
  static const cloudPort = 443;
  static const cloudHttps = true;

  String host = _defaultHost();
  int port = _defaultPort();
  bool enableHttps = _defaultHttps();
  static ServerConfig? instance;

  /// URL base del backend publicado en Render (sin barra final).
  String get baseUrl => '${enableHttps ? 'https' : 'http'}://$host:$port';

  /// Host por defecto según plataforma.
  static String _defaultHost() {
    return cloudHost;
  }

  static int _defaultPort() => cloudPort;

  static bool _defaultHttps() => cloudHttps;

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'enableHttps': enableHttps,
  };
}

/// URL base actual de la API (lo usan los servicios).
String apiBaseUrl() {
  final cfg = ServerConfig.instance ?? ServerConfig();
  return cfg.baseUrl;
}

/// Carga la configuración guardada al inicio de la app.
Future<void> initServerConfig() async {
  final cfg = ServerConfig();
  try {
    final dir = await paths.getApplicationDocumentsDirectory();
    final file = File('$dir/lubricantes_arca_config.json');
    if (await file.exists()) {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedHost = map['host'] as String?;
      final savedPort = map['port'] as int?;
      final savedHttps = map['enableHttps'] as bool?;

      // Las versiones anteriores guardaban la IP local o una URL temporal de
      // Cloudflare. Se reemplazan una sola vez por Render para que el usuario
      // no tenga que reconfigurar cada dispositivo.
      final isLegacyServer =
          savedHost == null ||
          savedHost == 'localhost' ||
          savedHost == '127.0.0.1' ||
          savedHost == '192.168.1.8' ||
          savedHost.endsWith('.trycloudflare.com');
      if (isLegacyServer) {
        cfg.host = ServerConfig.cloudHost;
        cfg.port = ServerConfig.cloudPort;
        cfg.enableHttps = ServerConfig.cloudHttps;
        await file.writeAsString(jsonEncode(cfg.toJson()));
      } else {
        cfg.host = savedHost;
        cfg.port = savedPort ?? cfg.port;
        cfg.enableHttps = savedHttps ?? cfg.enableHttps;
      }
    }
  } catch (_) {
    // Sin acceso a documentos (p.ej. web): se usan los valores por defecto.
  }
  ServerConfig.instance = cfg;
}

/// Guarda la configuración y la actualiza en memoria.
Future<void> saveServerConfig(ServerConfig cfg) async {
  ServerConfig.instance = cfg;
  try {
    final dir = await paths.getApplicationDocumentsDirectory();
    await File(
      '$dir/lubricantes_arca_config.json',
    ).writeAsString(jsonEncode(cfg.toJson()));
  } catch (_) {
    // Sin acceso de escritura: solo queda en memoria esta sesión.
  }
}

/// Comprueba si la API responde en la URL configurada.
Future<bool> testServerConnection() async {
  try {
    final cfg = ServerConfig.instance ?? ServerConfig();
    return await testServerConnectionWith(host: cfg.host, port: cfg.port);
  } catch (_) {
    return false;
  }
}

/// Comprueba la conexión con unos valores concretos (usado en la pantalla
/// de configuración, sin modificar aún la configuración guardada).
Future<bool> testServerConnectionWith({
  required String host,
  required int port,
  bool enableHttps = false,
}) async {
  try {
    final base = '${enableHttps ? 'https' : 'http'}://$host:$port';
    final res = await http.get(Uri.parse('$base/health'));
    if (res.statusCode != 200) return false;
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return map['status'] == 'ok';
  } catch (_) {
    return false;
  }
}
