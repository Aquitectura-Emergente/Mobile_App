import 'package:flutter_test/flutter_test.dart';

import 'package:emsafe_app/contexts/radiationmonitoring/domain/client_dashboard.dart';

ClientDashboard fromJson(Map<String, dynamic> extra) =>
    ClientDashboard.fromJson({
      'deviceCount': 3,
      'activeDeviceCount': 2,
      'currentAverage': 50.0,
      'maxValue': 120.0,
      'alertCount': 1,
      ...extra,
    });

void main() {
  group('exposureRatio', () {
    test('es la fraccion del umbral que ocupa la media', () {
      final d = fromJson({'currentAverage': 100.0, 'safetyThreshold': 200.0});
      expect(d.exposureRatio, 0.5);
    });

    test('se acota a 1 cuando la media supera el umbral', () {
      final d = fromJson({'currentAverage': 500.0, 'safetyThreshold': 200.0});
      expect(d.exposureRatio, 1.0);
    });

    test('no divide por cero si el umbral llega en 0', () {
      final d = fromJson({'currentAverage': 50.0, 'safetyThreshold': 0.0});
      expect(d.exposureRatio, 0.0);
    });
  });

  group('parseo', () {
    test('si falta el umbral usa los 200 µT acordados', () {
      expect(fromJson({}).safetyThreshold, 200.0);
    });

    test('si falta el nivel asume seguro', () {
      expect(fromJson({}).level, 'safe');
    });

    test('acepta enteros donde espera decimales', () {
      // El backend manda 42 en vez de 42.0 segun el valor: un cast directo
      // a double reventaria.
      final d = fromJson({'currentAverage': 42, 'maxValue': 7});
      expect(d.currentAverage, 42.0);
      expect(d.maxValue, 7.0);
    });

    test('sin dispositivos ni lecturas no se rompe', () {
      final d = fromJson({});
      expect(d.devices, isEmpty);
      expect(d.latestReadings, isEmpty);
    });
  });

  test('cuenta los sensores instalados que no reportan', () {
    expect(fromJson({}).silentDeviceCount, 1); // 3 instalados, 2 activos
  });
}
