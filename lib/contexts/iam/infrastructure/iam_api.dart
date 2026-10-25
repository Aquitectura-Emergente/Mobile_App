import '../../../core/http/api_client.dart';
import '../domain/client_profile.dart';

/// Acceso HTTP a identidad y cuenta del cliente.
class IamApi {
  static Future<Map<String, dynamic>> login(String email, String password) async =>
      await ApiClient.post(
        '/auth/login',
        {'email': email.trim(), 'password': password},
        auth: false,
      ) as Map<String, dynamic>;

  /// Alta publica: crea la cuenta CLIENT en estado "pending". El usuario no
  /// puede entrar hasta que un admin la activa.
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? clientType,
    String? contactName,
    String? taxId,
    String? industry,
  }) async {
    await ApiClient.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (clientType != null && clientType.isNotEmpty) 'clientType': clientType,
        if (contactName != null && contactName.isNotEmpty) 'contactName': contactName,
        if (taxId != null && taxId.isNotEmpty) 'taxId': taxId,
        if (industry != null && industry.isNotEmpty) 'industry': industry,
      },
      auth: false,
    );
  }

  static Future<ClientProfile> profile() async => ClientProfile.fromJson(
      await ApiClient.get('/client/profile') as Map<String, dynamic>);

  static Future<ClientProfile> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? address,
  }) async =>
      ClientProfile.fromJson(await ApiClient.put('/client/profile', {
        // Elementos null-aware: la clave se omite si el valor es null, asi el
        // PUT solo manda los campos que el usuario toco.
        'name': ?name,
        'phone': ?phone,
        'location': ?location,
        'address': ?address,
      }) as Map<String, dynamic>);

  static Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await ApiClient.patch('/client/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Borrado definitivo de la cuenta. Exige la contrasena como confirmacion.
  static Future<void> deleteAccount(String password) async {
    await ApiClient.post('/client/account/delete', {'password': password});
  }
}
