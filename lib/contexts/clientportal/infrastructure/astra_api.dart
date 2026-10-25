import '../../../core/http/api_client.dart';

/// Acceso HTTP al asistente "Astra".
///
/// El backend hace de proxy a Gemini: la clave de la API **nunca** viaja en la
/// app. Si `GEMINI_API_KEY` esta vacia en el backend, el chat se desactiva y
/// el resto de la app sigue funcionando.
class AstraApi {
  static Future<String> chat(
      String message, List<Map<String, String>> history) async {
    final data = await ApiClient.post('/client/chat', {
      'message': message,
      'history': history,
    }) as Map<String, dynamic>;
    return (data['reply'] ?? '').toString();
  }
}
