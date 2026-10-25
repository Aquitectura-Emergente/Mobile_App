import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../contexts/iam/infrastructure/session_store.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_navigator.dart';

/// Thrown when a request fails. Carries a user-friendly message and (when known)
/// the HTTP status code.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Low-level HTTP client for the EMSafe backend.
/// Adds the JWT Bearer header automatically and unwraps the standard
/// `{ success, message, data }` envelope used by the Spring Boot API.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 20);
  static bool _signingOut = false;

  /// Clears the session and bounces to login. Called when the backend reports
  /// the token is no longer valid (401 — expired, or the account was
  /// deactivated/deleted from the web). Guarded so concurrent 401s bounce once.
  static Future<void> _forceSignOut() async {
    if (_signingOut) return;
    _signingOut = true;
    await SessionStore.clear();
    appNavigatorKey.currentState
        ?.pushNamedAndRemoveUntil(Etapa2Routes.login, (route) => false);
    _signingOut = false;
  }

  static Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && SessionStore.token != null) {
      headers['Authorization'] = 'Bearer ${SessionStore.token}';
    }
    return headers;
  }

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<dynamic> get(String path) async {
    return _send(() => http.get(_uri(path), headers: _headers()).timeout(_timeout));
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _send(() => http
        .post(_uri(path), headers: _headers(auth: auth), body: jsonEncode(body))
        .timeout(_timeout));
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    return _send(() => http
        .put(_uri(path), headers: _headers(), body: jsonEncode(body))
        .timeout(_timeout));
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    return _send(() => http
        .patch(_uri(path), headers: _headers(), body: jsonEncode(body))
        .timeout(_timeout));
  }

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } catch (e) {
      throw ApiException(
        'Could not reach the server. Check your connection and that the backend is running.',
      );
    }
    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    dynamic decoded;
    if (res.body.isNotEmpty) {
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    if (res.statusCode == 401) {
      // Token invalid/expired or the account was deactivated/deleted → sign out.
      _forceSignOut();
      throw ApiException('Session expired. Please sign in again.',
          statusCode: 401);
    }
    if (res.statusCode == 403) {
      throw ApiException('You are not authorized to perform this action.',
          statusCode: 403);
    }

    final message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Request failed (${res.statusCode}).';
    throw ApiException(message, statusCode: res.statusCode);
  }
}
