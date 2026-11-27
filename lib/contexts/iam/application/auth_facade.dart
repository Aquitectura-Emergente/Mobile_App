import '../../../core/http/api_client.dart';
import '../domain/client_profile.dart';
import '../domain/user_segment.dart';
import '../infrastructure/iam_api.dart';
import '../infrastructure/segment_probe.dart';
import '../infrastructure/session_store.dart';

/// Punto de entrada del contexto iam para las pantallas.
///
/// Las pantallas hablan con esta fachada, nunca con `IamApi` ni con
/// `ApiClient` directamente.
class AuthFacade {
  /// Entra y guarda la sesion.
  ///
  /// La regla de quién puede usar el móvil (cliente, operario y, para pruebas,
  /// admin) vive en `MobileRole`, no suelta aquí.
  static Future<void> login(String email, String password) async {
    final data = await IamApi.login(email, password);
    final role = (data['role'] ?? '').toString().toLowerCase();

    if (!MobileRole.isAllowed(role)) {
      throw ApiException(
        'This account is not a client or operator account. Use the EMSafe web portal instead.',
      );
    }

    await SessionStore.save(
      token: (data['token'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: role,
      userId: (data['userId'] as num).toInt(),
    );
    await refreshSegment();
  }

  /// Hogar u operario. Si aún no se sabe, lo detecta; ante la duda, hogar.
  static Future<UserSegment> segment() async =>
      UserSegment.fromName(await SessionStore.segment()) ??
      await refreshSegment();

  /// Segmento guardado, sin ir a la red (para el arranque).
  static Future<UserSegment> storedSegment() async =>
      UserSegment.fromName(await SessionStore.segment()) ?? UserSegment.home;

  /// Vuelve a detectar el segmento y lo guarda si se pudo decidir.
  static Future<UserSegment> refreshSegment() async {
    final role = await SessionStore.role();
    // El admin entra para probar la app del hogar.
    if (role == MobileRole.admin) return UserSegment.home;
    // Una cuenta WORKER siempre es operario, aunque aún no tenga membership.
    if (role == MobileRole.worker) {
      await SessionStore.saveSegment(UserSegment.operator.name);
      return UserSegment.operator;
    }
    final detected = await SegmentProbe.detect();
    if (detected != null) await SessionStore.saveSegment(detected.name);
    return detected ?? UserSegment.home;
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
