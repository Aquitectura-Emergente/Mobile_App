import '../../../core/http/json.dart';

/// Sensor del cliente (espeja el DTO de `/api/client/devices`).
class ClientDevice {
  ClientDevice({
    required this.id,
    required this.name,
    required this.type,
    this.location,
    required this.status,
    this.serialNumber,
    this.installDate,
    this.latestValue,
    this.latestLevel,
    this.latestReadingDate,
    required this.readingsCount,
    this.plug,
    this.desiredPlug,
  });

  final int id;
  final String name;
  final String type;
  final String? location;
  final String status;
  final String? serialNumber;
  final String? installDate;
  final double? latestValue;
  final String? latestLevel;
  final String? latestReadingDate;
  final int readingsCount;

  /// Estado del rele que el dispositivo reporto en su ultima lectura.
  final String? plug;

  /// Estado del rele que el usuario ordeno desde la app (null = sin orden).
  final String? desiredPlug;

  factory ClientDevice.fromJson(Map<String, dynamic> j) => ClientDevice(
        id: jsonInt(j['id']),
        name: jsonString(j['name']),
        type: jsonString(j['type']),
        location: jsonStringOrNull(j['location']),
        status: jsonString(j['status']),
        serialNumber: jsonStringOrNull(j['serialNumber']),
        installDate: jsonStringOrNull(j['installDate']),
        latestValue: jsonDouble(j['latestValue']),
        latestLevel: jsonStringOrNull(j['latestLevel']),
        latestReadingDate: jsonStringOrNull(j['latestReadingDate']),
        readingsCount: jsonInt(j['readingsCount']),
        plug: jsonStringOrNull(j['plug']),
        desiredPlug: jsonStringOrNull(j['desiredPlug']),
      );

  // ─── Comportamiento del agregado ──────────────────────────────────────────

  /// Hay una orden del usuario que el dispositivo todavia no ha aplicado.
  ///
  /// El rele se gobierna de forma asincrona: la app escribe `desiredPlug` y el
  /// edge lo recoge en el siguiente ciclo de POST. Hasta entonces, los dos
  /// valores difieren y la interfaz debe mostrar que esta en transito.
  bool get plugOrderPending =>
      desiredPlug != null && plug != null && desiredPlug != plug;

  /// Estado efectivo del rele: lo que el usuario pidio si hay orden, y si no,
  /// lo ultimo que reporto el dispositivo.
  String? get effectivePlug => desiredPlug ?? plug;

  bool get isPlugOn => effectivePlug == PlugState.on;

  /// "active" aqui significa *sensor instalado y reportando*, no cuenta
  /// habilitada (eso es iam). Son vocabularios distintos.
  bool get isReporting => status == 'active' || status == 'collecting';

  bool get hasReadings => readingsCount > 0;
}

abstract final class PlugState {
  static const String on = 'ON';
  static const String off = 'OFF';

  static String toggle(String? current) => current == on ? off : on;
}
