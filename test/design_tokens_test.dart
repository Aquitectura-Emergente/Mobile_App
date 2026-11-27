import 'dart:convert';
import 'dart:io';

import 'package:emsafe_app/design_system/ems_tokens.g.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

void main() {
  final json = jsonDecode(File('design-tokens/emsafe.tokens.json').readAsStringSync()) as Map<String, dynamic>;
  final colors = json['color'] as Map<String, dynamic>;

  test('la versión de los tokens coincide con el JSON compartido', () {
    expect(emsTokensVersion, json[r'$version']);
  });

  for (final entry in {'light': emsLight, 'dark': emsDark}.entries) {
    test('los colores ${entry.key} coinciden con el JSON compartido', () {
      final expected = (colors[entry.key] as Map<String, dynamic>).map((k, v) => MapEntry(k, _hex(v as String)));
      expect(entry.value.toMap(), expected);
    });
  }

  test('las constantes estáticas coinciden con los conjuntos de color', () {
    expect(EmsDarkColors.bg, emsDark.bg);
    expect(EmsDarkColors.primary, emsDark.primary);
    expect(EmsDarkColors.dangerSignal, emsDark.dangerSignal);
    expect(EmsLightColors.text, emsLight.text);
  });

  test('la escala tipográfica coincide con el JSON compartido', () {
    final type = json['type'] as Map<String, dynamic>;
    expect(EmsTypeScale.all.keys.toSet(), type.keys.toSet());
    type.forEach((k, v) {
      final s = EmsTypeScale.all[k]!;
      expect(s.size, (v['size'] as num).toDouble(), reason: k);
      expect(s.line, (v['line'] as num).toDouble(), reason: k);
      expect(s.weight, v['weight'], reason: k);
    });
  });

  test('los estados de exposición conservan su semántica de color', () {
    // Verde seguro, amarillo advertencia, rojo crítico: tono dominante de cada señal.
    for (final set in [emsLight, emsDark]) {
      expect((set.safeSignal.g * 255) > (set.safeSignal.r * 255), isTrue);
      expect((set.dangerSignal.r * 255) > (set.dangerSignal.g * 255), isTrue);
      expect((set.warningSignal.r * 255) > (set.warningSignal.b * 255), isTrue);
    }
  });
}
