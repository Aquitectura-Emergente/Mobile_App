import '../../../core/http/json.dart';
import 'radiation_level.dart';

/// Un tramo del informe agregado (un mes, o un dia segun el periodo).
class ClientReportBucket {
  ClientReportBucket({
    required this.label,
    required this.average,
    required this.peak,
    required this.readings,
    required this.alerts,
  });

  final String label;
  final double average;
  final double peak;
  final int readings;
  final int alerts;

  factory ClientReportBucket.fromJson(Map<String, dynamic> j) =>
      ClientReportBucket(
        label: jsonString(j['label']),
        average: jsonDouble(j['average']) ?? 0,
        peak: jsonDouble(j['peak']) ?? 0,
        readings: jsonInt(j['readings']),
        alerts: jsonInt(j['alerts']),
      );

  /// Nivel del tramo segun su pico. Los agregados llegan sin `level`, asi que
  /// aqui si toca clasificar (antes se hacia en linea en reports_screen).
  String get peakLevel => levelForValue(peak);
}

/// Informe agregado de radiacion. `period` = "month" | "year".
class ClientReport {
  ClientReport({
    required this.period,
    required this.average,
    required this.peak,
    required this.totalReadings,
    required this.totalAlerts,
    required this.buckets,
  });

  final String period;
  final double average;
  final double peak;
  final int totalReadings;
  final int totalAlerts;
  final List<ClientReportBucket> buckets;

  factory ClientReport.fromJson(Map<String, dynamic> j) => ClientReport(
        period: (j['period'] ?? 'month').toString(),
        average: jsonDouble(j['average']) ?? 0,
        peak: jsonDouble(j['peak']) ?? 0,
        totalReadings: jsonInt(j['totalReadings']),
        totalAlerts: jsonInt(j['totalAlerts']),
        buckets: ((j['buckets'] as List?) ?? [])
            .map((e) => ClientReportBucket.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Nivel del informe segun su pico.
  String get peakLevel => levelForValue(peak);

  bool get isEmpty => totalReadings == 0;
}

abstract final class ReportPeriod {
  static const String month = 'month';
  static const String year = 'year';
}
