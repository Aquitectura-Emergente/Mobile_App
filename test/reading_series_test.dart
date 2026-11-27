import 'package:emsafe_app/contexts/personaldosimetry/domain/personal_reading.dart';
import 'package:emsafe_app/contexts/radiationmonitoring/domain/client_reading.dart';
import 'package:emsafe_app/contexts/radiationmonitoring/domain/reading_series.dart';
import 'package:flutter_test/flutter_test.dart';

SeriesPoint p(DateTime at, double v, [String? level]) => SeriesPoint(at: at, value: v, level: level);

void main() {
  final day = DateTime(2026, 11, 20);

  test('los tramos sin lecturas quedan vacíos, no en cero', () {
    final buckets = ReadingSeries.bucket(
      [p(day.add(const Duration(minutes: 10)), 12), p(day.add(const Duration(minutes: 50)), 30), p(day.add(const Duration(hours: 3)), 5)],
      from: day,
      to: day.add(const Duration(hours: 4)),
      span: const Duration(hours: 1),
    );
    expect(buckets, hasLength(4));
    expect(buckets[0].count, 2);
    expect(buckets[0].min, 12);
    expect(buckets[0].max, 30);
    expect(buckets[0].average, 21);
    expect(buckets[1].isEmpty, isTrue);
    expect(buckets[1].min, isNull);
    expect(buckets[2].max, isNull);
    expect(buckets[3].count, 1);
  });

  test('las lecturas fuera del intervalo no se cuentan', () {
    final buckets = ReadingSeries.bucket(
      [p(day.subtract(const Duration(minutes: 1)), 99), p(day.add(const Duration(hours: 2)), 99)],
      from: day,
      to: day.add(const Duration(hours: 2)),
      span: const Duration(hours: 1),
    );
    expect(buckets.every((b) => b.isEmpty), isTrue);
  });

  test('el nivel del tramo es el más severo', () {
    expect(worstLevelOf(['safe', 'caution', 'safe']), 'caution');
    expect(worstLevelOf(['safe', 'danger', 'caution']), 'danger');
    expect(worstLevelOf([null, 'safe']), 'safe');
    expect(worstLevelOf(const []), isNull);
  });

  test('resumen con mínimo, máximo, promedio y última lectura', () {
    final s = SeriesSummary.of([p(day.add(const Duration(hours: 2)), 40), p(day, 10), p(day.add(const Duration(hours: 1)), 25)]);
    expect(s.count, 3);
    expect(s.min, 10);
    expect(s.max, 40);
    expect(s.average, 25);
    expect(s.latest!.value, 40);
    expect(SeriesSummary.of(const []).isEmpty, isTrue);
  });

  test('agrupa por día del más reciente al más antiguo', () {
    final groups = ReadingSeries.byDay([p(day, 1), p(day.add(const Duration(days: 1, hours: 5)), 2), p(day.add(const Duration(hours: 8)), 3)]);
    expect(groups.map((g) => g.day), [DateTime(2026, 11, 21), DateTime(2026, 11, 20)]);
    expect(groups.last.points.first.value, 3, reason: 'dentro del día, la más reciente primero');
    expect(groups.last.hourly, hasLength(24));
    expect(groups.last.hourly.where((b) => !b.isEmpty), hasLength(2));
  });

  test('la ventana de 24 h termina en el tramo actual', () {
    final now = DateTime(2026, 11, 20, 14, 25);
    final buckets = ReadingSeries.forRange([p(DateTime(2026, 11, 20, 14, 5), 7)], SeriesRange.day, now: now);
    expect(buckets, hasLength(24));
    expect(buckets.last.end, DateTime(2026, 11, 20, 15));
    expect(buckets.last.count, 1);
  });

  test('una jornada se divide en tramos legibles', () {
    final from = DateTime(2026, 11, 20, 8, 3);
    final buckets = ReadingSeries.forInterval(const [], from, DateTime(2026, 11, 20, 16, 0));
    expect(buckets.first.start, DateTime(2026, 11, 20, 8));
    expect(buckets.first.span, const Duration(minutes: 30));
    expect(buckets.length, lessThanOrEqualTo(24));
  });

  test('una lectura del hogar sin hora exacta solo conoce el día', () {
    final r = ClientReading.fromJson({'id': 1, 'value': 10, 'readingDate': '2026-11-20'});
    expect(r.hasExactTime, isFalse);
    expect(r.takenAt, DateTime(2026, 11, 20));
    final exact = ClientReading.fromJson({'id': 2, 'value': 10, 'recordedAt': '2026-11-20T10:15:00'});
    expect(exact.hasExactTime, isTrue);
  });

  test('la lectura del dosímetro separa captura y recepción', () {
    final r = PersonalReading.fromJson({
      'id': 'r-1',
      'sessionId': 's-1',
      'deviceId': 7,
      'bootId': 'b',
      'sequence': 42,
      'fieldMicrotesla': 12.5,
      'unit': 'uT',
      'capturedFrom': '2026-11-20T10:00:00Z',
      'capturedTo': '2026-11-20T10:00:10Z',
      'receivedAt': '2026-11-20T10:30:10Z',
      'status': 'late',
    });
    expect(r.isLate, isTrue);
    expect(r.sequence, 42);
    expect(r.deviceId, 7);
    expect(r.deliveryDelay, const Duration(minutes: 30));
    expect(r.takenAt, DateTime.parse('2026-11-20T10:00:00Z').toLocal());
  });
}
