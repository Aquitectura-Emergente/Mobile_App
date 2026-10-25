import '../domain/client_alert.dart';
import '../infrastructure/alert_api.dart';

/// Punto de entrada del contexto alerts para las pantallas.
class AlertFacade {
  static Future<List<ClientAlert>> all() => AlertApi.list();

  /// Recuento por nivel. Las pantallas lo contaban a mano con `.where(...)`
  /// y el literal del nivel repartido por la presentacion.
  static AlertTally tally(List<ClientAlert> alerts) => AlertTally.from(alerts);
}
