import '../../../core/http/json.dart';

/// Lectura del dosímetro dentro de una jornada.
class PersonalReading {
  const PersonalReading({
    required this.id,
    required this.fieldMicrotesla,
    this.capturedFrom,
    this.capturedTo,
    required this.status,
  });

  final String id;
  final double fieldMicrotesla;
  final String? capturedFrom;
  final String? capturedTo;

  /// ACCEPTED | LATE (llegó tras sincronizar sin cobertura).
  final String status;

  factory PersonalReading.fromJson(Map<String, dynamic> j) => PersonalReading(
        id: jsonString(j['id']),
        fieldMicrotesla: jsonDouble(j['fieldMicrotesla']) ?? 0,
        capturedFrom: jsonStringOrNull(j['capturedFrom']),
        capturedTo: jsonStringOrNull(j['capturedTo']),
        status: jsonString(j['status']).toUpperCase(),
      );

  bool get isLate => status == 'LATE';
}
