import '../../../core/http/json.dart';

/// Estado de exposición de la jornada frente al límite del puesto.
enum ExposureStatus { normal, warning, exceeded }

/// Jornada de exposición del operario (espeja `DosimetryResources.Session`).
///
/// La dosis es un índice tiempo-campo (`uT*s`); el backend la acumula y
/// compara contra el límite vigente del puesto.
class ExposureSession {
  const ExposureSession({
    required this.id,
    required this.state,
    required this.unit,
    required this.accumulatedIndex,
    required this.limitIndex,
    required this.percentage,
    required this.warningRaised,
    required this.limitExceeded,
    this.coveragePercentage,
    required this.coverageComplete,
    this.startedAt,
    this.endedAt,
    this.finalizedAt,
    required this.outOfRangeReadings,
    this.deviceId,
    this.jobPositionId,
  });

  final String id;

  /// OPEN | CLOSING | CLOSED.
  final String state;
  final String unit;
  final double accumulatedIndex;
  final double limitIndex;

  /// Porcentaje del límite consumido (0–100, puede pasar de 100).
  final double percentage;
  final bool warningRaised;
  final bool limitExceeded;
  final double? coveragePercentage;
  final bool coverageComplete;
  final String? startedAt;
  final String? endedAt;
  final String? finalizedAt;
  final int outOfRangeReadings;
  final int? deviceId;
  final int? jobPositionId;

  factory ExposureSession.fromJson(Map<String, dynamic> j) => ExposureSession(
        id: jsonString(j['id']),
        state: jsonString(j['state']).toUpperCase(),
        unit: jsonString(j['unit']),
        accumulatedIndex: jsonDouble(j['accumulatedIndex']) ?? 0,
        limitIndex: jsonDouble(j['limitIndex']) ?? 0,
        percentage: jsonDouble(j['percentage']) ?? 0,
        warningRaised: j['warningRaised'] == true,
        limitExceeded: j['limitExceeded'] == true,
        coveragePercentage: jsonDouble(j['coveragePercentage']),
        coverageComplete: j['coverageComplete'] == true,
        startedAt: jsonStringOrNull(j['startedAt']),
        endedAt: jsonStringOrNull(j['endedAt']),
        finalizedAt: jsonStringOrNull(j['finalizedAt']),
        outOfRangeReadings: jsonInt(j['outOfRangeReadings']),
        deviceId: j['deviceId'] == null ? null : jsonInt(j['deviceId']),
        jobPositionId:
            j['jobPositionId'] == null ? null : jsonInt(j['jobPositionId']),
      );

  bool get isOpen => state == 'OPEN';
  bool get isClosed => state == 'CLOSED';

  /// Lo decide el backend con el umbral de advertencia del puesto.
  ExposureStatus get status => limitExceeded || percentage >= 100
      ? ExposureStatus.exceeded
      : (warningRaised ? ExposureStatus.warning : ExposureStatus.normal);

  /// Fracción para el indicador, acotada a 0–1.
  double get progress => (percentage / 100).clamp(0, 1).toDouble();

  /// Margen hasta el límite (0 si ya se superó).
  double get remainingIndex =>
      (limitIndex - accumulatedIndex).clamp(0, double.infinity).toDouble();
}
