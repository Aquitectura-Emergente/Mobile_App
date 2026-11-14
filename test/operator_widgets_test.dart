import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emsafe_app/contexts/personaldosimetry/domain/exposure_session.dart';
import 'package:emsafe_app/screens/operator/operator_components.dart';

void main() {
  testWidgets('el indicador muestra el porcentaje consumido', (tester) async {
    final session = ExposureSession.fromJson({
      'id': 's-1',
      'state': 'OPEN',
      'unit': 'uT*s',
      'accumulatedIndex': 840,
      'limitIndex': 1000,
      'percentage': 84.2,
      'warningRaised': true,
      'limitExceeded': false,
      'coverageComplete': false,
      'outOfRangeReadings': 0,
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: ExposureGauge(session: session))),
    ));
    expect(find.text('84 %'), findsOneWidget);
    expect(exposureColor(session.status), isNot(exposureColor(ExposureStatus.normal)));
  });

  test('los índices grandes se abrevian de forma coherente', () {
    expect(exposureIndex(950), '950');
    expect(exposureIndex(1000), '1k');
    expect(exposureIndex(1250), '1.3k');
    expect(exposureIndex(12400), '12.4k');
    expect(exposureIndex(999960), '1M');
    expect(exposureIndex(3450000), '3.5M');
  });
}
