import 'package:flutter_test/flutter_test.dart';
import 'package:emsafe_app/contexts/alerts/domain/alert_filter.dart';
import 'package:emsafe_app/contexts/alerts/domain/client_alert.dart';

ClientAlert alert(int id, String level, int device, String? at) => ClientAlert(
      id: id,
      type: 'reading',
      level: level,
      title: 't',
      description: 'd',
      deviceId: device,
      deviceName: 'Sensor $device',
      recordedAt: at,
    );

void main() {
  final now = DateTime.parse('2026-11-13T12:00:00');
  final alerts = [
    alert(1, 'danger', 1, '2026-11-13T09:00:00'),
    alert(2, 'caution', 2, '2026-11-10T09:00:00'),
    alert(3, 'danger', 2, '2026-10-01T09:00:00'),
    alert(4, 'caution', 1, null),
  ];

  test('sin filtro devuelve todo', () {
    expect(const AlertFilter().apply(alerts, now: now).length, 4);
    expect(const AlertFilter().isActive, isFalse);
  });

  test('filtra por nivel y sensor', () {
    final f = const AlertFilter(level: 'danger', deviceId: 2);
    expect(f.apply(alerts, now: now).map((a) => a.id), [3]);
  });

  test('la ventana de fechas excluye lo antiguo y lo que no tiene marca', () {
    expect(const AlertFilter(period: AlertPeriod.today).apply(alerts, now: now).map((a) => a.id), [1]);
    expect(const AlertFilter(period: AlertPeriod.week).apply(alerts, now: now).map((a) => a.id), [1, 2]);
  });

  test('copyWith puede quitar un criterio', () {
    final f = const AlertFilter(level: 'danger').copyWith(level: () => null);
    expect(f.level, isNull);
  });

  test('lista los sensores del historial', () {
    expect(AlertFilter.devicesIn(alerts), {1: 'Sensor 1', 2: 'Sensor 2'});
  });
}
