import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as paths;

/// Configuración centralizada del servidor API.
///
/// IP del servidor, puerto y URL base en un solo lugar, persistida en
/// `lubricantes_arca_config.json` dentro de Documentos. Así se cambia
/// fácilmente para Windows o para celulares Android (red Wi-Fi local).
class ServerConfig {
  String host = _defaultHost();
  int port = 8000;
  bool enableHttps = false;
  static ServerConfig? instance;

  /// URL base p.ej. http://192.168.1.8:8000 (sin barra final).
  /// La IP debe coincidir con la IP LAN actual de la PC servidora.
  String get baseUrl => '${enableHttps ? 'https' : 'http'}://$host:$port';

  /// Host por defecto según plataforma.
  static String _defaultHost() {
    if (kIsWeb) return 'localhost';
    // IP LAN actual de la PC servidora. Para que no cambie, reservar esta IP
    // en el router mediante DHCP Reservation/Static Lease.
    if (Platform.isAndroid) return '192.168.1.8';
    return '127.0.0.1';
  }

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
      cfg.host = (map['host'] as String?) ?? cfg.host;
      cfg.port = (map['port'] as int?) ?? cfg.port;
      cfg.enableHttps = (map['enableHttps'] as bool?) ?? cfg.enableHttps;
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
