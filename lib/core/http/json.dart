/// Conversiones defensivas para el JSON del backend.
///
/// Estaban privadas en `models/client_models.dart`, asi que cada contexto que
/// necesitara parsear tenia que redefinirlas. Al vivir aqui, los cinco las
/// comparten.
///
/// Son tolerantes a proposito: el backend devuelve `int` donde el movil espera
/// `double` segun el valor concreto (42 frente a 42.5), y un cast directo a
/// `double` reventaria con el primero.
library;

double? jsonDouble(dynamic value) =>
    value == null ? null : (value as num).toDouble();

int jsonInt(dynamic value) => value == null ? 0 : (value as num).toInt();

String jsonString(dynamic value) => (value ?? '').toString();

String? jsonStringOrNull(dynamic value) => value?.toString();
