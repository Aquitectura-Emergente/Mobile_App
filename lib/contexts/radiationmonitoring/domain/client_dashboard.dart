import '../../../core/http/json.dart';
import '../../iottelemetry/domain/client_device.dart';
import 'client_reading.dart';
import 'radiation_level.dart';

/// Resumen que abre la app: estado de la flota del cliente y su exposicion.
///
/// Referencia `ClientDevice`, de iottelemetry. Es un cruce de contextos
/// deliberado (DDD pragmatico): el backend ya lo devuelve agregado en un solo
/// DTO y partirlo obligaria a dos llamadas para pintar una pantalla.
class ClientDashboard {
  ClientDashboard({
    required this.deviceCount,
    required this.activeDeviceCount,
    required this.currentAverage,
    required this.maxValue,
    required this.level,
    required this.safetyThreshold,
    required this.alertCount,
    required this.devices,
    required this.latestReadings,
  });

  final int deviceCount;
  final int activeDeviceCount;
  final double currentAverage;
  final double maxValue;
  final String level;
  final double safetyThreshold;
  final int alertCount;
  final List<ClientDevice> devices;
  final List<ClientReading> latestReadings;

  factory ClientDashboard.fromJson(Map<String, dynamic> j) => ClientDashboard(
        deviceCount: jsonInt(j['deviceCount']),
        activeDeviceCount: jsonInt(j['activeDeviceCount']),
        currentAverage: jsonDouble(j['currentAverage']) ?? 0,
        maxValue: jsonDouble(j['maxValue']) ?? 0,
        level: (j['level'] ?? RadiationLevel.safe).toString(),
        // Por defecto el umbral de peligro: el backend deberia mandarlo, pero
        // si falta, 200 µT es el valor acordado en los cuatro stacks.
        safetyThreshold: jsonDouble(j['safetyThreshold']) ?? dangerThresholdUT,
        alertCount: jsonInt(j['alertCount']),
        devices: ((j['devices'] as List?) ?? [])
            .map((e) => ClientDevice.fromJson(e as Map<String, dynamic>))
            .toList(),
        latestReadings: ((j['latestReadings'] as List?) ?? [])
            .map((e) => ClientReading.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ─── Comportamiento ───────────────────────────────────────────────────────

  /// Fraccion del umbral de seguridad que ocupa la media actual, acotada a
  /// [0, 1] para poder pintarla como barra de progreso.
  ///
  /// Estaba calculado en linea en `dashboard_overview_screen.dart`, con su
  /// guarda de division por cero incluida.
  double get exposureRatio => safetyThreshold > 0
      ? (currentAverage / safetyThreshold).clamp(0.0, 1.0)
      : 0.0;

  bool get isDangerous => level == RadiationLevel.danger;

  bool get hasDevices => deviceCount > 0;

  /// Sensores instalados pero que no estan reportando.
  int get silentDeviceCount => deviceCount - activeDeviceCount;
}
