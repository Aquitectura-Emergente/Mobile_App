import 'exposure_session.dart';

/// Aviso de exposición para el operario.
class OperatorAlert {
  const OperatorAlert({
    required this.sessionId,
    required this.status,
    required this.percentage,
    this.at,
  });

  final String sessionId;

  /// warning (pasó el umbral de advertencia) o exceeded (superó el límite).
  final ExposureStatus status;
  final double percentage;
  final String? at;

  bool get isExceeded => status == ExposureStatus.exceeded;

  /// Un aviso por jornada que pasó la advertencia, la más reciente primero.
  static List<OperatorAlert> fromSessions(Iterable<ExposureSession> sessions) {
    final seen = <String>{};
    final alerts = <OperatorAlert>[];
    for (final s in sessions) {
      if (s.status == ExposureStatus.normal || !seen.add(s.id)) continue;
      alerts.add(OperatorAlert(
        sessionId: s.id,
        status: s.status,
        percentage: s.percentage,
        at: s.endedAt ?? s.startedAt,
      ));
    }
    alerts.sort((a, b) => (b.at ?? '').compareTo(a.at ?? ''));
    return alerts;
  }
}
