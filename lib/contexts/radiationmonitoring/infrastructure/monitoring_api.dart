import '../../../core/http/api_client.dart';
import '../domain/client_dashboard.dart';
import '../domain/client_reading.dart';
import '../domain/client_report.dart';

/// Acceso HTTP al resumen, las lecturas y los informes del cliente.
class MonitoringApi {
  static Future<ClientDashboard> dashboard() async => ClientDashboard.fromJson(
      await ApiClient.get('/client/dashboard') as Map<String, dynamic>);

  static Future<List<ClientReading>> deviceReadings(int deviceId) async =>
      ((await ApiClient.get('/client/devices/$deviceId/readings')) as List)
          .map((e) => ClientReading.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Todas las lecturas del cliente. La usa la exportacion a CSV.
  static Future<List<ClientReading>> readings() async =>
      ((await ApiClient.get('/client/readings')) as List)
          .map((e) => ClientReading.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Informe agregado. `period` = "month" | "year".
  static Future<ClientReport> report(String period) async =>
      ClientReport.fromJson(
          await ApiClient.get('/client/reports?period=$period')
              as Map<String, dynamic>);
}
