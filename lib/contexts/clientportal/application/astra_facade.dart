import '../infrastructure/astra_api.dart';

/// Punto de entrada del contexto clientportal (el BFF movil y Astra).
///
/// Es el unico contexto que no tiene modelos propios: la conversacion vive en
/// el estado de la pantalla y solo se intercambian cadenas.
class AstraFacade {
  static Future<String> ask(
          String message, List<Map<String, String>> history) =>
      AstraApi.chat(message, history);
}
