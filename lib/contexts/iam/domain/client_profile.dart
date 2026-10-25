import '../../../core/http/json.dart';

/// Perfil del cliente autenticado (espeja el DTO de `/api/client/profile`).
class ClientProfile {
  ClientProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.email,
    required this.role,
    this.phone,
    this.location,
    this.address,
    this.latitude,
    this.longitude,
    this.joinDate,
  });

  final int id;
  final String name;
  final String? initials;
  final String email;
  final String role;
  final String? phone;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? joinDate;

  factory ClientProfile.fromJson(Map<String, dynamic> j) => ClientProfile(
        id: jsonInt(j['id']),
        name: jsonString(j['name']),
        initials: jsonStringOrNull(j['initials']),
        email: jsonString(j['email']),
        role: jsonString(j['role']),
        phone: jsonStringOrNull(j['phone']),
        location: jsonStringOrNull(j['location']),
        address: jsonStringOrNull(j['address']),
        latitude: jsonDouble(j['latitude']),
        longitude: jsonDouble(j['longitude']),
        joinDate: jsonStringOrNull(j['joinDate']),
      );

  /// Un cliente con coordenadas aparece en el mapa; sin ellas, no.
  bool get hasCoordinates => latitude != null && longitude != null;
}

/// Roles que la app movil admite.
///
/// El login rechaza cualquier otro: el portal web es para admin y tecnico, y
/// aqui solo entran clientes (se acepta `admin` para poder probar la app).
abstract final class MobileRole {
  static const String client = 'client';
  static const String admin = 'admin';

  static bool isAllowed(String role) => role == client || role == admin;
}
