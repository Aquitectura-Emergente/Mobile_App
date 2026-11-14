import '../../../core/http/api_client.dart';
import '../domain/plug_status.dart';

/// Órdenes y estado del enchufe en Device Management. `plugId` es el serial.
class PlugApi {
  static String _base(String plugId) =>
      '/v1/device-management/plugs/${Uri.encodeComponent(plugId)}';

  /// Emite la orden. El backend responde 202 con la orden en PENDING.
  static Future<PlugCommand> sendCommand(String plugId, String action) async =>
      PlugCommand.fromJson(await ApiClient.post(
        '${_base(plugId)}/commands',
        {'action': action},
      ) as Map<String, dynamic>);

  static Future<PlugCommand> command(String plugId, String commandId) async =>
      PlugCommand.fromJson(await ApiClient.get(
              '${_base(plugId)}/commands/${Uri.encodeComponent(commandId)}')
          as Map<String, dynamic>);

  static Future<PlugStatus> state(String plugId) async => PlugStatus.fromJson(
      await ApiClient.get('${_base(plugId)}/state') as Map<String, dynamic>);
}
