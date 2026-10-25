import '../../../core/http/json.dart';
import '../../radiationmonitoring/domain/radiation_level.dart';

/// Alerta que el cliente ve en su historial.
class ClientAlert {
  ClientAlert({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.description,
    this.value,
    this.deviceId,
    this.deviceName,
    this.time,
    this.recordedAt,
  });

  final int id;
  final String type;
  final String level;
  final String title;
  final String description;
  final double? value;
  final int? deviceId;
  final String? deviceName;
  final String? time;

  /// Marca ISO exacta, para calcular el "hace 36 min" en pantalla.
  final String? recordedAt;

  factory ClientAlert.fromJson(Map<String, dynamic> j) => ClientAlert(
        id: jsonInt(j['id']),
        type: jsonString(j['type']),
        level: jsonString(j['level']),
        title: jsonString(j['title']),
        description: jsonString(j['description']),
        value: jsonDouble(j['value']),
        deviceId: j['deviceId'] == null ? null : jsonInt(j['deviceId']),
        deviceName: jsonStringOrNull(j['deviceName']),
        time: jsonStringOrNull(j['time']),
        recordedAt: jsonStringOrNull(j['recordedAt']),
      );

  bool get isDangerous => level == RadiationLevel.danger;
  bool get isCaution => level == RadiationLevel.caution;
}

/// Recuento de alertas por nivel.
///
/// Las pantallas contaban a mano con `.where((a) => a.level == 'caution')`,
/// repartiendo el literal del nivel por la capa de presentacion.
class AlertTally {
  const AlertTally({required this.safe, required this.caution, required this.danger});

  final int safe;
  final int caution;
  final int danger;

  factory AlertTally.from(List<ClientAlert> alerts) => AlertTally(
        safe: alerts.where((a) => a.level == RadiationLevel.safe).length,
        caution: alerts.where((a) => a.level == RadiationLevel.caution).length,
        danger: alerts.where((a) => a.level == RadiationLevel.danger).length,
      );

  int get total => safe + caution + danger;
}
