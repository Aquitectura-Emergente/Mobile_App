import '../domain/plug_status.dart';

/// Sigue una orden hasta que el Edge la confirme o se agote la espera.
///
/// El backend no cierra las órdenes sin respuesta ni avisa del estado del
/// enchufe por WebSocket, así que se consulta cada [interval] y, pasado
/// [timeout], la orden se da por no confirmada (puede seguir PENDING).
class PlugCommandTracker {
  PlugCommandTracker({
    required this.fetch,
    this.interval = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 15),
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? ((d) => Future<void>.delayed(d));

  final Future<PlugCommand> Function(PlugCommand) fetch;
  final Duration interval;
  final Duration timeout;
  final Future<void> Function(Duration) _wait;

  Future<PlugOrderOutcome> track(PlugCommand command) async {
    var current = command;
    var waited = Duration.zero;
    while (current.isPending) {
      if (waited >= timeout) return PlugOrderOutcome.unconfirmed;
      await _wait(interval);
      waited += interval;
      try {
        current = await fetch(current);
      } catch (_) {
        // Un fallo de red no resuelve la orden; se reintenta en la siguiente vuelta.
      }
    }
    return current.isConfirmed
        ? PlugOrderOutcome.confirmed
        : PlugOrderOutcome.failed;
  }
}
