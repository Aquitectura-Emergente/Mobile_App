import '../../../core/http/api_client.dart';
import '../domain/user_segment.dart';

/// Averigua si la cuenta es de operario.
///
/// El backend no expone la membresía de Personal Dosimetry, así que se infiere
/// de la exposición actual: 200 o 404 (operario con o sin jornada) frente a
/// 403 (sin membresía, cliente del hogar). Cuando exista un endpoint propio,
/// solo cambia esta clase.
class SegmentProbe {
  static const String path = '/v1/personal-dosimetry/workers/me/exposure';

  /// Devuelve null si no se pudo decidir (sin red, error del servidor).
  static Future<UserSegment?> detect() async {
    try {
      await ApiClient.get(path);
      return UserSegment.operator;
    } on ApiException catch (e) {
      return classify(e.statusCode);
    }
  }

  static UserSegment? classify(int? statusCode) => switch (statusCode) {
        404 => UserSegment.operator,
        403 => UserSegment.home,
        _ => null,
      };
}
