import 'package:emsafe_app/contexts/radiationmonitoring/domain/reading_series.dart';
import 'package:emsafe_app/design_system/design_system.dart';
import 'package:emsafe_app/screens/shared/form_validators.dart';
import 'package:emsafe_app/screens/shared/measurement_overview.dart';
import 'package:emsafe_app/screens/shared/reading_history_screen.dart';
import 'package:emsafe_app/services/app_i18n_m.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(theme: EmsThemeData.dark(), home: child);

List<SeriesPoint> _points() {
  final now = DateTime.now();
  return [
    for (var h = 0; h < 20; h += 3) SeriesPoint(at: now.subtract(Duration(hours: h, minutes: 5)), value: 40.0 + h * 9, level: h > 12 ? 'caution' : 'safe'),
  ];
}

void main() {
  test('las validaciones siguen al backend: solo nombre, correo y contraseña son obligatorios', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('a@b'), isNotNull);
    expect(Validators.email('ana@ejemplo.pe'), isNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
    expect(Validators.requiredName('  '), isNotNull);
    expect(Validators.optionalPhone(''), isNull, reason: 'el teléfono es opcional');
    expect(Validators.optionalPhone('+51 987 654 321'), isNull);
    expect(Validators.optionalPhone('12'), isNotNull);
    expect(Validators.optionalPhone('abc'), isNotNull);
  });

  test('la fortaleza de la contraseña es orientativa', () {
    expect(PasswordStrength.score(''), 0);
    expect(PasswordStrength.score('abc'), 1);
    expect(PasswordStrength.score('Abcdef12!xyz'), 4);
  });

  test('los textos nuevos existen en inglés y en español', () {
    expect(mEn.keys.toSet(), mEs.keys.toSet());
    expect(mEs.values.where((v) => v.trim().isEmpty), isEmpty);
  });

  testWidgets('la vista resumida cabe en 320 px y marca los huecos', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MeasurementOverview(points: _points(), onShowAll: () {}),
      ),
    )));
    expect(tester.takeException(), isNull);
    expect(find.byType(EmsRangeChart), findsOneWidget);
    // Hay horas sin lecturas: la leyenda lo indica.
    expect(find.text('No readings'), findsWidgets);
    expect(find.text('Show all data'), findsOneWidget);
  });

  testWidgets('tocar una barra muestra el tramo seleccionado', (tester) async {
    await tester.pumpWidget(_app(Scaffold(
      body: SingleChildScrollView(child: MeasurementOverview(points: _points())),
    )));
    final chart = find.byType(EmsRangeChart);
    final box = tester.getRect(chart);
    await tester.tapAt(Offset(box.left + (box.width - 38) * 0.98, box.center.dy));
    await tester.pumpAndSettle();
    expect(tester.widget<EmsRangeChart>(chart).selected, isNotNull);
  });

  testWidgets('el histórico agrupa por día y abre el detalle', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SeriesPoint? opened;
    await tester.pumpWidget(_app(ReadingHistoryScreen(title: 'Sala', points: _points(), onOpen: (_, p) => opened = p)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining(RegExp('by day', caseSensitive: false)), findsOneWidget);
    await tester.tap(find.textContaining('µT').at(3));
    await tester.pumpAndSettle();
    expect(opened, isNotNull);
  });
}
