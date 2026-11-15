import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the authenticated client's session (JWT + basic identity).
/// The token is held in memory for fast access and mirrored to SharedPreferences
/// so the session survives app restarts.
class SessionStore {
  static const _tokenKey = 'emsafe_token';
  static const _nameKey = 'emsafe_name';
  static const _emailKey = 'emsafe_email';
  static const _roleKey = 'emsafe_role';
  static const _userIdKey = 'emsafe_user_id';
  static const _segmentKey = 'emsafe_segment';

  static String? _token;
  static String? _segment;
  static String? get token => _token;

  /// Lectura síncrona del segmento para la navegación (se carga en [load]).
  static bool get isOperator => _segment == 'operator';

  static Future<void> save({
    required String token,
    required String name,
    required String email,
    required String role,
    required int userId,
  }) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_roleKey, role);
    await prefs.setInt(_userIdKey, userId);
  }

  /// Loads the token from disk into memory. Call once at startup.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _segment = prefs.getString(_segmentKey);
  }

  /// Una sesión con el token vencido no cuenta: se borra para volver al login.
  static Future<bool> isLoggedIn() async {
    await load();
    if (isExpired(_token)) await clear();
    return _token != null && _token!.isNotEmpty;
  }

  /// True si el JWT trae `exp` y ya pasó. Si no se puede leer, no se da por
  /// vencido: el backend decide.
  static bool isExpired(String? token, {DateTime? now}) {
    final parts = token?.split('.') ?? const [];
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! num) return false;
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
      return !(now ?? DateTime.now()).isBefore(expiresAt);
    } catch (_) {
      return false;
    }
  }

  static Future<String> name() async =>
      (await SharedPreferences.getInstance()).getString(_nameKey) ?? '';

  static Future<String> email() async =>
      (await SharedPreferences.getInstance()).getString(_emailKey) ?? '';

  /// The authenticated user's id — matches the `clientId` carried by every
  /// [ReadingDto] over the WebSocket, so the app can subscribe only to its own
  /// readings (`/topic/clients/{userId}/readings`). Null if not stored yet.
  static Future<int?> userId() async =>
      (await SharedPreferences.getInstance()).getInt(_userIdKey);

  static Future<String> role() async =>
      (await SharedPreferences.getInstance()).getString(_roleKey) ?? '';

  /// Segmento detectado al entrar (`home` | `operator`), o null si no se sabe.
  static Future<String?> segment() async =>
      (await SharedPreferences.getInstance()).getString(_segmentKey);

  static Future<void> saveSegment(String segment) async {
    _segment = segment;
    await (await SharedPreferences.getInstance()).setString(_segmentKey, segment);
  }

  static final List<void Function()> _clearListeners = [];

  /// Avisa cuando se cierra la sesión (salida, 401 o cuenta borrada), para que
  /// otros contextos suelten lo que tengan abierto a nombre de la cuenta.
  static void addClearListener(void Function() listener) {
    if (!_clearListeners.contains(listener)) _clearListeners.add(listener);
  }

  static Future<void> clear() async {
    _token = null;
    _segment = null;
    for (final listener in List.of(_clearListeners)) {
      listener();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_segmentKey);
  }
}
