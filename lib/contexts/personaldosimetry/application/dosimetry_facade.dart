import '../../../core/http/page.dart';
import '../../iam/infrastructure/session_store.dart';
import '../domain/exposure_session.dart';
import '../domain/operator_alert.dart';
import '../domain/personal_reading.dart';
import '../infrastructure/dosimetry_api.dart';

/// Punto de entrada del contexto personaldosimetry para las pantallas del
/// operario. Solo consulta: abrir, cerrar y configurar jornadas es del SSO.
class DosimetryFacade {
  /// Jornada actual (o la última). Null: sin dosímetro asignado.
  static Future<ExposureSession?> currentShift() =>
      DosimetryApi.currentExposure();

  static Future<PageOf<PersonalReading>> shiftReadings(String sessionId,
          {int page = 0}) =>
      DosimetryApi.sessionReadings(sessionId, page: page);

  static Future<PageOf<ExposureSession>> history({int page = 0}) async {
    final workerId = await SessionStore.userId();
    if (workerId == null) {
      return const PageOf(
          content: [], page: 0, size: 0, totalElements: 0, totalPages: 0, last: true);
    }
    return DosimetryApi.history(workerId, page: page);
  }

  /// Avisos del operario. El backend aún no le expone sus alertas, así que se
  /// derivan de las marcas de advertencia y límite de sus jornadas recientes.
  static Future<List<OperatorAlert>> alerts() async {
    final current = await currentShift();
    final recent = await history();
    return OperatorAlert.fromSessions([?current, ...recent.content]);
  }
}
