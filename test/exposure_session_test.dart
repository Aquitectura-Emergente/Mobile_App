import 'package:flutter_test/flutter_test.dart';
import 'package:emsafe_app/core/http/page.dart';
import 'package:emsafe_app/contexts/personaldosimetry/domain/exposure_session.dart';
import 'package:emsafe_app/contexts/personaldosimetry/domain/operator_alert.dart';
import 'package:emsafe_app/contexts/personaldosimetry/domain/personal_reading.dart';

Map<String, dynamic> sessionJson({
  String id = 's-1',
  num pct = 40,
  bool warning = false,
  bool exceeded = false,
  String state = 'OPEN',
  String startedAt = '2026-11-13T08:00:00Z',
}) =>
    {
      'id': id,
      'state': state,
      'unit': 'uT*s',
      'accumulatedIndex': 400,
      'limitIndex': 1000,
      'percentage': pct,
      'warningRaised': warning,
      'limitExceeded': exceeded,
      'coveragePercentage': 98.5,
      'coverageComplete': false,
      'startedAt': startedAt,
      'outOfRangeReadings': 0,
    };

void main() {
  group('jornada de exposición', () {
    test('lee la vista del backend', () {
      final s = ExposureSession.fromJson(sessionJson());
      expect(s.isOpen, isTrue);
      expect(s.progress, closeTo(0.4, 1e-9));
      expect(s.remainingIndex, 600);
      expect(s.status, ExposureStatus.normal);
    });

    test('la advertencia la marca el backend', () {
      expect(ExposureSession.fromJson(sessionJson(pct: 85, warning: true)).status,
          ExposureStatus.warning);
    });

    test('superar el límite manda sobre la advertencia', () {
      expect(
          ExposureSession.fromJson(sessionJson(pct: 120, warning: true, exceeded: true))
              .status,
          ExposureStatus.exceeded);
      expect(ExposureSession.fromJson(sessionJson(pct: 120)).progress, 1);
    });
  });

  group('avisos del operario', () {
    test('uno por jornada con advertencia o exceso, el más reciente primero', () {
      final sessions = [
        sessionJson(id: 'a', pct: 85, warning: true, startedAt: '2026-11-10T08:00:00Z'),
        sessionJson(id: 'b', pct: 30),
        sessionJson(id: 'c', pct: 110, exceeded: true, startedAt: '2026-11-12T08:00:00Z'),
        sessionJson(id: 'c', pct: 110, exceeded: true, startedAt: '2026-11-12T08:00:00Z'),
      ].map(ExposureSession.fromJson);
      final alerts = OperatorAlert.fromSessions(sessions);
      expect(alerts.map((a) => a.sessionId), ['c', 'a']);
      expect(alerts.first.isExceeded, isTrue);
    });
  });

  test('página de lecturas', () {
    final page = PageOf.fromJson({
      'content': [
        {'id': 'r1', 'fieldMicrotesla': 12.5, 'status': 'LATE'}
      ],
      'page': 0,
      'size': 100,
      'totalElements': 1,
      'totalPages': 1,
      'last': true,
    }, PersonalReading.fromJson);
    expect(page.content.single.isLate, isTrue);
    expect(page.last, isTrue);
  });
}
