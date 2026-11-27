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

  /// Lecturas más recientes de la jornada (su última página), de la más
  /// antigua a la más reciente, como las ordena la API.
  static Future<List<PersonalReading>> latestShiftReadings(
      String sessionId) async {
    final first = await shiftReadings(sessionId);
    final page = first.totalPages > 1
        ? await shiftReadings(sessionId, page: first.totalPages - 1)
        : first;
    return page.content;
  }

  /// Todas las lecturas de una jornada (hasta [maxPages] páginas), de la más
  /// antigua a la más reciente.
  static Future<List<PersonalReading>> allShiftReadings(String sessionId,
      {int maxPages = 10}) async {
    final first = await shiftReadings(sessionId);
    final all = [...first.content];
    final pages = first.totalPages.clamp(1, maxPages);
    for (var p = 1; p < pages; p++) {
      all.addAll((await shiftReadings(sessionId, page: p)).content);
    }
    return all;
  }

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
