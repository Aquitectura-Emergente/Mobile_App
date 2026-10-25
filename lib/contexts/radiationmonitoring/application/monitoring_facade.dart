import '../domain/client_dashboard.dart';
import '../domain/client_reading.dart';
import '../domain/client_report.dart';
import '../domain/radiation_level.dart';
import '../infrastructure/monitoring_api.dart';

/// Punto de entrada del contexto radiationmonitoring para las pantallas.
class MonitoringFacade {
  static Future<ClientDashboard> dashboard() => MonitoringApi.dashboard();

  static Future<List<ClientReading>> deviceReadings(int deviceId) =>
      MonitoringApi.deviceReadings(deviceId);

  static Future<List<ClientReading>> allReadings() => MonitoringApi.readings();

  static Future<ClientReport> report(String period) =>
      MonitoringApi.report(period);

  /// Fallback de clasificacion por valor en µT.
  ///
  /// Solo para agregados que llegan sin nivel (el pico de un informe). Si una
  /// lectura trae `level`, se respeta: el edge es la autoridad.
  static String levelFor(double microTesla) => levelForValue(microTesla);
}
