import '../domain/client_device.dart';
import '../infrastructure/device_api.dart';

/// Punto de entrada del contexto iottelemetry para las pantallas.
///
/// Los flujos en vivo (STOMP) y las notificaciones locales viven en
/// `infrastructure/realtime_service.dart` y `notification_service.dart`, que
/// exponen `ValueNotifier` estaticos y los consumen las pantallas
/// directamente: son widgets escuchando, no un caso de uso.
class DeviceFacade {
  static Future<List<ClientDevice>> all() => DeviceApi.list();

  static Future<ClientDevice> setPlug(int deviceId, String plug) =>
      DeviceApi.setPlug(deviceId, plug);

  /// Invierte el estado del rele a partir del estado efectivo actual.
  static Future<ClientDevice> togglePlug(ClientDevice device) =>
      DeviceApi.setPlug(device.id, PlugState.toggle(device.effectivePlug));
}
