import '../../../core/http/json.dart';
import 'plug_status.dart';

export 'plug_status.dart' show PlugPower;

/// Dispositivo del cliente (espeja el DTO de `/api/client/devices`).
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

  /// Estado real del relé informado por el Edge (ON | OFF | UNKNOWN).
  final String? plug;

  /// Acción de la orden pendiente; sin orden pendiente, coincide con [plug].
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

  /// Solo los enchufes inteligentes aceptan órdenes ON/OFF.
  bool get isPlug => type.toLowerCase() == 'plug';

  /// Estado real del relé, o null si el Edge aún no lo informó.
  String? get realPlug =>
      plug == PlugPower.on || plug == PlugPower.off ? plug : null;

  /// Hay una orden que el Edge todavía no confirmó.
  bool get plugOrderPending =>
      desiredPlug != null && desiredPlug != plug;

  /// Acción pedida mientras la orden siga pendiente.
  String? get pendingPlug => plugOrderPending ? desiredPlug : null;

  bool get isPlugOn => realPlug == PlugPower.on;

  /// "active" aqui significa *sensor instalado y reportando*, no cuenta
  /// habilitada (eso es iam). Son vocabularios distintos.
  bool get isReporting => status == 'active' || status == 'collecting';

  bool get hasReadings => readingsCount > 0;
}

/// Enchufe del hogar entre los dispositivos del cliente (hoy hay uno por hogar).
ClientDevice? homePlugOf(List<ClientDevice> devices) {
  for (final d in devices) {
    if (d.isPlug) return d;
  }
  return null;
}
