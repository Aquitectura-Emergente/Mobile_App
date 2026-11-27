import 'radiation_level.dart';

/// Una medición instantánea ubicada en el tiempo.
///
/// Sirve igual para las lecturas de un sensor fijo del hogar y para las del
/// dosímetro del operario: en ambos casos es un valor de campo en µT. Nunca se
/// usa para la exposición acumulada ni para porcentajes del límite.
class SeriesPoint {
  const SeriesPoint({
    required this.at,
    required this.value,
    this.level,
    this.flagged = false,
    this.source,
  });

  final DateTime at;
  final double value;

  /// safe | caution | danger, tal como lo decide el backend; null si no aplica.
  final String? level;

  /// Marca libre (p. ej. lectura sincronizada tarde).
  final bool flagged;

  /// Objeto de origen, para abrir su detalle.
  final Object? source;
}

/// Un tramo de tiempo con sus lecturas. Un tramo sin lecturas es un hueco,
/// no un cero.
class SeriesBucket {
  SeriesBucket({required this.start, required this.span, required List<SeriesPoint> points})
      : points = List.unmodifiable(points);

  final DateTime start;
  final Duration span;
  final List<SeriesPoint> points;

  DateTime get end => start.add(span);
  int get count => points.length;
  bool get isEmpty => points.isEmpty;

  double? get min => isEmpty ? null : points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  double? get max => isEmpty ? null : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  double? get average => isEmpty ? null : points.fold<double>(0, (s, p) => s + p.value) / count;

  /// El nivel más severo del tramo.
  String? get worstLevel => worstLevelOf(points.map((p) => p.level));

  bool get hasFlagged => points.any((p) => p.flagged);
}

/// Resumen de un conjunto de lecturas reales.
class SeriesSummary {
  const SeriesSummary({
    required this.count,
    this.min,
    this.max,
    this.average,
    this.latest,
    this.first,
  });

  final int count;
  final double? min;
  final double? max;
  final double? average;
  final SeriesPoint? latest;
  final SeriesPoint? first;

  bool get isEmpty => count == 0;

  factory SeriesSummary.of(Iterable<SeriesPoint> points) {
    final list = points.toList()..sort((a, b) => a.at.compareTo(b.at));
    if (list.isEmpty) return const SeriesSummary(count: 0);
    var mn = list.first.value, mx = list.first.value, sum = 0.0;
    for (final p in list) {
      if (p.value < mn) mn = p.value;
      if (p.value > mx) mx = p.value;
      sum += p.value;
    }
    return SeriesSummary(
      count: list.length,
      min: mn,
      max: mx,
      average: sum / list.length,
      latest: list.last,
      first: list.first,
    );
  }
}

/// Ventanas de consulta del gráfico compacto.
enum SeriesRange {
  /// Últimas 24 h en tramos de 1 h.
  day(Duration(hours: 24), Duration(hours: 1)),

  /// Últimos 7 días en tramos de 6 h.
  week(Duration(days: 7), Duration(hours: 6)),

  /// Últimos 30 días en tramos diarios.
  month(Duration(days: 30), Duration(days: 1));

  const SeriesRange(this.window, this.span);

  final Duration window;
  final Duration span;
}

/// Agrupa lecturas en tramos regulares.
abstract final class ReadingSeries {
  /// Tramos de [span] que cubren [from, to). Los puntos fuera quedan fuera.
  static List<SeriesBucket> bucket(
    Iterable<SeriesPoint> points, {
    required DateTime from,
    required DateTime to,
    required Duration span,
  }) {
    final spanMs = span.inMilliseconds;
    if (spanMs <= 0 || !to.isAfter(from)) return const [];
    final n = ((to.millisecondsSinceEpoch - from.millisecondsSinceEpoch) / spanMs).ceil();
    final groups = List.generate(n, (_) => <SeriesPoint>[]);
    for (final p in points) {
      final offset = p.at.millisecondsSinceEpoch - from.millisecondsSinceEpoch;
      if (offset < 0) continue;
      final i = offset ~/ spanMs;
      if (i >= n) continue;
      groups[i].add(p);
    }
    return [
      for (var i = 0; i < n; i++)
        SeriesBucket(start: from.add(span * i), span: span, points: groups[i]),
    ];
  }

  /// Tramos de la ventana [range] que termina ahora, alineados al tramo.
  static List<SeriesBucket> forRange(Iterable<SeriesPoint> points, SeriesRange range, {DateTime? now}) {
    final end = alignUp(now ?? DateTime.now(), range.span);
    return bucket(points, from: end.subtract(range.window), to: end, span: range.span);
  }

  /// Tramos que cubren el intervalo de una jornada, con un tamaño legible.
  static List<SeriesBucket> forInterval(Iterable<SeriesPoint> points, DateTime from, DateTime to, {int target = 24}) {
    final total = to.difference(from);
    var minutes = (total.inMinutes / target).ceil();
    const steps = [5, 10, 15, 30, 60, 120, 240, 360, 720, 1440];
    minutes = steps.firstWhere((s) => s >= minutes, orElse: () => 1440);
    final span = Duration(minutes: minutes);
    final start = alignDown(from, span);
    return bucket(points, from: start, to: alignUp(to, span), span: span);
  }

  /// Agrupa por día local, del más reciente al más antiguo.
  static List<DayGroup> byDay(Iterable<SeriesPoint> points) {
    final map = <DateTime, List<SeriesPoint>>{};
    for (final p in points) {
      final d = DateTime(p.at.year, p.at.month, p.at.day);
      map.putIfAbsent(d, () => []).add(p);
    }
    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final d in days)
        DayGroup(day: d, points: map[d]!..sort((a, b) => b.at.compareTo(a.at))),
    ];
  }

  static DateTime alignDown(DateTime t, Duration span) {
    if (span >= const Duration(days: 1)) return DateTime(t.year, t.month, t.day);
    final base = DateTime(t.year, t.month, t.day);
    final ms = t.difference(base).inMilliseconds;
    return base.add(Duration(milliseconds: ms - ms % span.inMilliseconds));
  }

  static DateTime alignUp(DateTime t, Duration span) {
    final down = alignDown(t, span);
    return down == t ? t : (span >= const Duration(days: 1) ? DateTime(down.year, down.month, down.day + 1) : down.add(span));
  }
}

/// Lecturas de un día.
class DayGroup {
  DayGroup({required this.day, required this.points}) : summary = SeriesSummary.of(points);

  final DateTime day;

  /// De la más reciente a la más antigua.
  final List<SeriesPoint> points;
  final SeriesSummary summary;

  /// 24 tramos horarios del día, con huecos donde no hubo lecturas.
  List<SeriesBucket> get hourly => ReadingSeries.bucket(
        points,
        from: day,
        to: DateTime(day.year, day.month, day.day + 1),
        span: const Duration(hours: 1),
      );

  String? get worstLevel => worstLevelOf(points.map((p) => p.level));
}

/// El nivel más severo de una lista (danger > caution > safe).
String? worstLevelOf(Iterable<String?> levels) {
  String? worst;
  for (final l in levels) {
    if (l == RadiationLevel.danger) return l;
    if (l == RadiationLevel.caution) {
      worst = l;
    } else if (l == RadiationLevel.safe && worst == null) {
      worst = l;
    }
  }
  return worst;
}
