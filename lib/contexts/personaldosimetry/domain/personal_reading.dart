import '../../../core/http/json.dart';

/// Lectura del dosímetro dentro de una jornada (espeja `DosimetryResources.Reading`).
///
/// Es un valor de campo instantáneo en µT promediado sobre su intervalo de
/// captura; no es dosis acumulada.
class PersonalReading {
  const PersonalReading({
    required this.id,
    required this.fieldMicrotesla,
    this.capturedFrom,
    this.capturedTo,
    required this.status,
    this.receivedAt,
    this.sessionId,
    this.deviceId,
    this.bootId,
    this.sequence,
    this.unit,
  });

  final String id;
  final double fieldMicrotesla;
  final String? capturedFrom;
  final String? capturedTo;

  /// ACCEPTED | LATE (llegó tras sincronizar sin cobertura).
  final String status;

  /// Cuándo la recibió el backend; con cobertura coincide casi con la captura.
  final String? receivedAt;
  final String? sessionId;
  final int? deviceId;
  final String? bootId;
  final int? sequence;
  final String? unit;

  factory PersonalReading.fromJson(Map<String, dynamic> j) => PersonalReading(
        id: jsonString(j['id']),
        fieldMicrotesla: jsonDouble(j['fieldMicrotesla']) ?? 0,
        capturedFrom: jsonStringOrNull(j['capturedFrom']),
        capturedTo: jsonStringOrNull(j['capturedTo']),
        status: jsonString(j['status']).toUpperCase(),
        receivedAt: jsonStringOrNull(j['receivedAt']),
        sessionId: jsonStringOrNull(j['sessionId']),
        deviceId: j['deviceId'] == null ? null : jsonInt(j['deviceId']),
        bootId: jsonStringOrNull(j['bootId']),
        sequence: j['sequence'] == null ? null : jsonInt(j['sequence']),
        unit: jsonStringOrNull(j['unit']),
      );

  bool get isLate => status == 'LATE';

  DateTime? get capturedStart => DateTime.tryParse(capturedFrom ?? '')?.toLocal();
  DateTime? get capturedEnd => DateTime.tryParse(capturedTo ?? '')?.toLocal();
  DateTime? get received => DateTime.tryParse(receivedAt ?? '')?.toLocal();

  /// Momento representativo de la lectura (inicio de su captura).
  DateTime? get takenAt => capturedStart ?? capturedEnd;

  /// Retraso entre el fin de la captura y la recepción.
  Duration? get deliveryDelay {
    final end = capturedEnd ?? capturedStart;
    final rec = received;
    if (end == null || rec == null) return null;
    final d = rec.difference(end);
    return d.isNegative ? Duration.zero : d;
  }
}
