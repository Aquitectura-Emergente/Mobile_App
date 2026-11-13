import '../domain/client_device.dart';
import '../domain/plug_status.dart';
import '../infrastructure/device_api.dart';
import '../infrastructure/plug_api.dart';
import 'plug_command_tracker.dart';

/// Punto de entrada del contexto devicemanagement para las pantallas.
///
/// Los flujos en vivo (STOMP) y las notificaciones locales viven en
/// `infrastructure/realtime_service.dart` y `notification_service.dart`, que
/// exponen `ValueNotifier` estaticos y los consumen las pantallas
/// directamente: son widgets escuchando, no un caso de uso.
class DeviceFacade {
  static Future<List<ClientDevice>> all() => DeviceApi.list();

  /// Enchufe del hogar del cliente, o null si no tiene.
  static Future<ClientDevice?> homePlug() async => homePlugOf(await all());

  /// Pide encender o apagar el enchufe. La orden queda PENDING hasta que el
  /// Edge publique el estado real.
  static Future<PlugCommand> requestPlug(ClientDevice plug, String action) {
    final serial = plug.serialNumber;
    if (!plug.isPlug || serial == null || serial.isEmpty) {
      throw ArgumentError('El dispositivo ${plug.id} no es un enchufe');
    }
    return PlugApi.sendCommand(serial, action);
  }

  /// Espera la confirmación de una orden (o se rinde pasado el plazo).
  static Future<PlugOrderOutcome> awaitConfirmation(PlugCommand command) =>
      PlugCommandTracker(
        fetch: (c) => PlugApi.command(c.plugId, c.commandId),
      ).track(command);

  /// Estado y última orden del enchufe del hogar; null si no hay enchufe.
  static Future<PlugStatus?> homePlugStatus() async {
    final plug = await homePlug();
    return plug == null ? null : plugStatus(plug);
  }

  /// Estado real del enchufe y su última orden.
  static Future<PlugStatus> plugStatus(ClientDevice plug) =>
      PlugApi.state(plug.serialNumber ?? '');
}
