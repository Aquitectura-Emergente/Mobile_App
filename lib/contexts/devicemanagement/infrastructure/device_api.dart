import '../../../core/http/api_client.dart';
import '../domain/client_device.dart';

/// Acceso HTTP a los sensores del cliente y al control del rele.
class DeviceApi {
  static Future<List<ClientDevice>> list() async =>
      ((await ApiClient.get('/client/devices')) as List)
          .map((e) => ClientDevice.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Ordena abrir o cerrar el rele ("ON" | "OFF").
  ///
  /// Es asincrono por diseno: el backend guarda `desiredPlug` y el edge lo
  /// recoge en su siguiente POST para accionar el rele fisico.
  static Future<ClientDevice> setPlug(int deviceId, String plug) async =>
      ClientDevice.fromJson(await ApiClient.patch(
        '/client/devices/$deviceId/plug',
        {'plug': plug},
      ) as Map<String, dynamic>);
}
