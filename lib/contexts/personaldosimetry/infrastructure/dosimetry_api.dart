import '../../../core/http/api_client.dart';
import '../../../core/http/page.dart';
import '../domain/exposure_session.dart';
import '../domain/personal_reading.dart';

/// Acceso HTTP a Personal Dosimetry con alcance de operario.
class DosimetryApi {
  static const String _base = '/v1/personal-dosimetry';

  /// Jornada más reciente del operario; null si nunca tuvo una (404).
  static Future<ExposureSession?> currentExposure() async {
    try {
      return ExposureSession.fromJson(
          await ApiClient.get('$_base/workers/me/exposure')
              as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<PageOf<PersonalReading>> sessionReadings(String sessionId,
          {int page = 0, int size = 100}) async =>
      PageOf.fromJson(
        await ApiClient.get(
                '$_base/sessions/${Uri.encodeComponent(sessionId)}/readings?page=$page&size=$size')
            as Map<String, dynamic>,
        PersonalReading.fromJson,
      );

  static Future<PageOf<ExposureSession>> history(int workerId,
          {int page = 0, int size = 20}) async =>
      PageOf.fromJson(
        await ApiClient.get(
                '$_base/workers/$workerId/sessions?page=$page&size=$size')
            as Map<String, dynamic>,
        ExposureSession.fromJson,
      );
}
