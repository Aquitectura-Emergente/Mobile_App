import '../../../core/http/api_client.dart';
import '../domain/client_alert.dart';

/// Acceso HTTP a las alertas del cliente.
class AlertApi {
  static Future<List<ClientAlert>> list() async =>
      ((await ApiClient.get('/client/alerts')) as List)
          .map((e) => ClientAlert.fromJson(e as Map<String, dynamic>))
          .toList();
}
