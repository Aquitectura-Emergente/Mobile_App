// Genera lib/design_system/ems_tokens.g.dart a partir de design-tokens/emsafe.tokens.json.
// Uso: dart run tool/generate_tokens.dart
// El test test/design_tokens_test.dart falla si el archivo generado no coincide con el JSON.
import 'dart:convert';
import 'dart:io';

String _camel(String key) {
  final parts = key.split('-');
  return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

String _color(String hex) => 'Color(0xFF${hex.substring(1).toUpperCase()})';

void main() {
  final json = jsonDecode(File('design-tokens/emsafe.tokens.json').readAsStringSync()) as Map<String, dynamic>;
  final colors = json['color'] as Map<String, dynamic>;
  final light = colors['light'] as Map<String, dynamic>;
  final dark = colors['dark'] as Map<String, dynamic>;
  final keys = light.keys.toList();

  final b = StringBuffer()
    ..writeln('// Archivo generado por tool/generate_tokens.dart (tokens v${json[r'$version']}). No editar a mano.')
    ..writeln('// ignore_for_file: constant_identifier_names')
    ..writeln("import 'package:flutter/painting.dart';")
    ..writeln()
    ..writeln("const String emsTokensVersion = '${json[r'$version']}';")
    ..writeln()
    ..writeln('/// Paleta semántica de un tema (claro u oscuro).')
    ..writeln('class EmsColorSet {')
    ..writeln('  const EmsColorSet({');
  for (final k in keys) {
    b.writeln('    required this.${_camel(k)},');
  }
  b.writeln('  });');
  for (final k in keys) {
    b.writeln('  final Color ${_camel(k)};');
  }
  b
    ..writeln()
    ..writeln('  /// Mapa con las claves del JSON (para verificación).')
    ..writeln('  Map<String, Color> toMap() => {');
  for (final k in keys) {
    b.writeln("        '$k': ${_camel(k)},");
  }
  b
    ..writeln('      };')
    ..writeln('}')
    ..writeln();

  void writeSet(String name, Map<String, dynamic> set) {
    b.writeln('const EmsColorSet $name = EmsColorSet(');
    for (final k in keys) {
      b.writeln('  ${_camel(k)}: ${_color(set[k] as String)},');
    }
    b
      ..writeln(');')
      ..writeln();
  }

  writeSet('emsLight', light);
  writeSet('emsDark', dark);

  // Constantes estáticas para contextos const (p. ej. `const TextStyle(color: EmsDarkColors.text)`).
  void writeStatic(String name, Map<String, dynamic> set) {
    b.writeln('abstract final class $name {');
    for (final k in keys) {
      b.writeln('  static const Color ${_camel(k)} = ${_color(set[k] as String)};');
    }
    b
      ..writeln('}')
      ..writeln();
  }

  writeStatic('EmsLightColors', light);
  writeStatic('EmsDarkColors', dark);

  void numClass(String cls, String doc, Map<String, dynamic> m, {String prefix = ''}) {
    b
      ..writeln('/// $doc')
      ..writeln('abstract final class $cls {');
    m.forEach((k, v) {
      final id = RegExp(r'^\d').hasMatch(k) ? '$prefix$k' : _camel(k);
      b.writeln('  static const double $id = ${(v as num).toDouble()};');
    });
    b
      ..writeln('}')
      ..writeln();
  }

  numClass('EmsSpace', 'Escala de espaciado (px lógicos).', json['space'] as Map<String, dynamic>, prefix: 's');
  numClass('EmsRadius', 'Radios de borde.', json['radius'] as Map<String, dynamic>);
  numClass('EmsBorder', 'Grosores de borde.', json['border'] as Map<String, dynamic>);
  numClass('EmsSize', 'Dimensiones de controles y navegación.', json['size'] as Map<String, dynamic>);
  numClass('EmsBreakpoint', 'Puntos de quiebre.', json['breakpoint'] as Map<String, dynamic>);

  final fonts = json['font'] as Map<String, dynamic>;
  b.writeln('/// Familias tipográficas.');
  b.writeln('abstract final class EmsFont {');
  fonts.forEach((k, v) => b.writeln("  static const String $k = '$v';"));
  b
    ..writeln('}')
    ..writeln();

  final motion = json['motion'] as Map<String, dynamic>;
  b.writeln('/// Duraciones de animación.');
  b.writeln('abstract final class EmsDuration {');
  (motion['duration'] as Map<String, dynamic>)
      .forEach((k, v) => b.writeln('  static const Duration $k = Duration(milliseconds: $v);'));
  b
    ..writeln('}')
    ..writeln();

  b.writeln('/// Especificación de un estilo tipográfico de la escala.');
  b.writeln('class EmsTypeSpec {');
  b.writeln('  const EmsTypeSpec(this.font, this.size, this.line, this.weight, this.tracking);');
  b.writeln('  final String font;');
  b.writeln('  final double size;');
  b.writeln('  final double line;');
  b.writeln('  final int weight;');
  b.writeln('  final double tracking;');
  b.writeln('}');
  b.writeln();
  b.writeln('/// Escala tipográfica compartida con la web.');
  b.writeln('abstract final class EmsTypeScale {');
  (json['type'] as Map<String, dynamic>).forEach((k, v) {
    final t = v as Map<String, dynamic>;
    b.writeln(
        "  static const EmsTypeSpec ${_camel(k)} = EmsTypeSpec(EmsFont.${t['font']}, ${(t['size'] as num).toDouble()}, ${(t['line'] as num).toDouble()}, ${t['weight']}, ${(t['tracking'] as num).toDouble()});");
  });
  b.writeln();
  b.writeln('  static const Map<String, EmsTypeSpec> all = {');
  for (final k in (json['type'] as Map<String, dynamic>).keys) {
    b.writeln("    '$k': ${_camel(k)},");
  }
  b
    ..writeln('  };')
    ..writeln('}');

  File('lib/design_system/ems_tokens.g.dart').writeAsStringSync(b.toString());
  stdout.writeln('Escrito lib/design_system/ems_tokens.g.dart');
}
