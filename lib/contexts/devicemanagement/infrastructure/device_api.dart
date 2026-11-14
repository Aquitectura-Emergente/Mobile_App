import '../../../core/http/api_client.dart';
import '../domain/client_device.dart';

/// Acceso HTTP a los dispositivos del cliente. Las órdenes al enchufe van por
/// [PlugApi]; `PATCH /client/devices/{id}/plug` no devuelve el `commandId`.
class DeviceApi {
  static Future<List<ClientDevice>> list() async =>
      ((await ApiClient.get('/client/devices')) as List)
          .map((e) => ClientDevice.fromJson(e as Map<String, dynamic>))
          .toList();
}
