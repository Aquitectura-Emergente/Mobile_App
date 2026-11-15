import 'dart:convert';

import 'package:emsafe_app/contexts/iam/infrastructure/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(Map<String, dynamic> payload) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS384'})}.${part(payload)}.firma';
}

void main() {
  final now = DateTime.utc(2026, 11, 15, 22);
  int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  test('token con exp pasado está vencido', () {
    final token = _jwt({'exp': epoch(now.subtract(const Duration(hours: 1)))});
    expect(SessionStore.isExpired(token, now: now), isTrue);
  });

  test('token con exp futuro sigue vigente', () {
    final token = _jwt({'exp': epoch(now.add(const Duration(hours: 1)))});
    expect(SessionStore.isExpired(token, now: now), isFalse);
  });

  test('sin token, sin exp o ilegible no se da por vencido', () {
    expect(SessionStore.isExpired(null, now: now), isFalse);
    expect(SessionStore.isExpired('', now: now), isFalse);
    expect(SessionStore.isExpired(_jwt({'sub': 'x'}), now: now), isFalse);
    expect(SessionStore.isExpired('a.%%%.c', now: now), isFalse);
  });
}
