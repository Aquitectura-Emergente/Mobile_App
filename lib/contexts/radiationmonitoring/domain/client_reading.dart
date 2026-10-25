import '../../../core/http/json.dart';
import 'radiation_level.dart';

/// Una lectura de campo del cliente. El valor viaja en microtesla (µT).
class ClientReading {
  ClientReading({
    required this.id,
    this.value,
    this.level,
    this.readingDate,
    this.recordedAt,
    this.deviceId,
    this.deviceName,
  });

  final int id;
  final double? value;
  final String? level;
  final String? readingDate;

  /// Marca de tiempo ISO exacta de la medicion.
  final String? recordedAt;
  final int? deviceId;
  final String? deviceName;

  factory ClientReading.fromJson(Map<String, dynamic> j) => ClientReading(
        id: jsonInt(j['id']),
        value: jsonDouble(j['value']),
        level: jsonStringOrNull(j['level']),
        readingDate: jsonStringOrNull(j['readingDate']),
        recordedAt: jsonStringOrNull(j['recordedAt']),
        deviceId: j['deviceId'] == null ? null : jsonInt(j['deviceId']),
        deviceName: jsonStringOrNull(j['deviceName']),
      );

  /// Nivel de la lectura, clasificando por valor solo si llega sin `level`.
  /// Se respeta siempre el del backend cuando existe: el edge es la autoridad.
  String get effectiveLevel =>
      level ?? (value == null ? RadiationLevel.safe : levelForValue(value!));

  bool get isDangerous => effectiveLevel == RadiationLevel.danger;
}
