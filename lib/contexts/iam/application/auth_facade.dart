import '../../../core/http/api_client.dart';
import '../domain/client_profile.dart';
import '../infrastructure/iam_api.dart';
import '../infrastructure/session_store.dart';

/// Punto de entrada del contexto iam para las pantallas.
///
/// Las pantallas hablan con esta fachada, nunca con `IamApi` ni con
/// `ApiClient` directamente.
class AuthFacade {
  /// Entra y guarda la sesion.
  ///
  /// La regla de que solo CLIENT (y ADMIN, para pruebas) pueden usar el movil
  /// vive en `MobileRole`, no suelta aqui.
  static Future<void> login(String email, String password) async {
    final data = await IamApi.login(email, password);
    final role = (data['role'] ?? '').toString().toLowerCase();

    if (!MobileRole.isAllowed(role)) {
      throw ApiException(
        'This account is not a client account. Use the EMSafe web portal instead.',
      );
    }

    await SessionStore.save(
      token: (data['token'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: role,
      userId: (data['userId'] as num).toInt(),
    );
  }

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
  }) =>
      IamApi.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        clientType: clientType,
        contactName: contactName,
        taxId: taxId,
        industry: industry,
      );

  static Future<ClientProfile> profile() => IamApi.profile();

  static Future<ClientProfile> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? address,
  }) =>
      IamApi.updateProfile(
          name: name, phone: phone, location: location, address: address);

  static Future<void> changePassword(String current, String nuevo) =>
      IamApi.changePassword(current, nuevo);

  /// Borra la cuenta y limpia la sesion local.
  static Future<void> deleteAccount(String password) async {
    await IamApi.deleteAccount(password);
    await SessionStore.clear();
  }

  static Future<void> logout() => SessionStore.clear();
}
