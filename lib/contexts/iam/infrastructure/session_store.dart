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

  static String? _token;
  static String? get token => _token;

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
  }

  static Future<bool> isLoggedIn() async {
    await load();
    return _token != null && _token!.isNotEmpty;
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

  static Future<void> clear() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
  }
}
