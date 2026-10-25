import 'package:flutter/foundation.dart';

/// Base URL for the EMSafe backend, resolved per environment:
///
/// - Debug (default): http://10.0.2.2:8080/api — the Android emulator reaches
///   the host PC at 10.0.2.2 (its own `localhost` is the emulator itself).
/// - Release: el backend de produccion (Oracle Cloud + Caddy).
/// - Override for any build (e.g. physical device on the same Wi-Fi):
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080/api
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const String _debugDefault = 'http://10.0.2.2:8080/api';
  static const String _production = 'https://emsafe.duckdns.org/api';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return kReleaseMode ? _production : _debugDefault;
  }

  /// STOMP WebSocket endpoint, derived from [baseUrl]
  /// (http://host/api → ws://host/ws, https → wss).
  static String get wsUrl {
    final base = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '${base.replaceFirst('https', 'wss').replaceFirst(RegExp('^http(?!s)'), 'ws')}/ws';
  }
}
