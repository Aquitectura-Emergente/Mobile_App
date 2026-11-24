import '../../../core/http/json.dart';

/// Estados de una orden al enchufe (espeja `PlugCommandStatus` del backend).
abstract final class PlugCommandStatus {
  static const String pending = 'PENDING';
  static const String confirmed = 'CONFIRMED';
  static const String notApplied = 'NOT_APPLIED';
  static const String sendFailed = 'SEND_FAILED';
}

/// Orden del usuario al enchufe. Nace PENDING y se resuelve cuando el Edge
/// publica el estado real con el mismo `commandId`.
class PlugCommand {
  const PlugCommand({
    required this.commandId,
    required this.plugId,
    required this.action,
    required this.status,
    this.requestedAt,
    this.resolvedAt,
  });

  final String commandId;

  /// Serial del enchufe (p. ej. `EMSafe-PLUG-01`).
  final String plugId;
  final String action;
  final String status;
  final String? requestedAt;
  final String? resolvedAt;

  factory PlugCommand.fromJson(Map<String, dynamic> j) => PlugCommand(
        commandId: jsonString(j['commandId']),
        plugId: jsonString(j['plugId']),
        action: jsonString(j['action']).toUpperCase(),
        status: jsonString(j['status']).toUpperCase(),
        requestedAt: jsonStringOrNull(j['requestedAt']),
        resolvedAt: jsonStringOrNull(j['resolvedAt']),
      );

  bool get isPending => status == PlugCommandStatus.pending;
  bool get isConfirmed => status == PlugCommandStatus.confirmed;
  bool get hasFailed =>
      status == PlugCommandStatus.notApplied ||
      status == PlugCommandStatus.sendFailed;
}

/// Estado real del enchufe según el Edge, con la última orden emitida.
class PlugStatus {
  const PlugStatus({
    required this.plugId,
    this.state,
    this.source,
    this.changedAt,
    this.lastCommand,
  });

  final String plugId;

  /// ON | OFF | UNKNOWN.
  final String? state;

  /// USER (orden desde la app) | AUTO (corte automático del Edge).
  final String? source;
  final String? changedAt;
  final PlugCommand? lastCommand;

  factory PlugStatus.fromJson(Map<String, dynamic> j) => PlugStatus(
        plugId: jsonString(j['plugId']),
        state: jsonStringOrNull(j['state'])?.toUpperCase(),
        source: jsonStringOrNull(j['source'])?.toUpperCase(),
        changedAt: jsonStringOrNull(j['changedAt']),
        lastCommand: j['lastCommand'] is Map<String, dynamic>
            ? PlugCommand.fromJson(j['lastCommand'] as Map<String, dynamic>)
            : null,
      );

  bool get isOn => state == PlugPower.on;
  bool get isOff => state == PlugPower.off;
  bool get isKnown => isOn || isOff;

  /// Orden que el Edge aún no confirmó, si la hay.
  PlugCommand? get pendingCommand =>
      lastCommand != null && lastCommand!.isPending ? lastCommand : null;
}

/// Valores del relé.
abstract final class PlugPower {
  static const String on = 'ON';
  static const String off = 'OFF';
  static const String unknown = 'UNKNOWN';

  static String toggle(String? current) => current == on ? off : on;
}

/// Cómo terminó el seguimiento de una orden desde la app.
enum PlugOrderOutcome {
  /// El Edge aplicó la orden.
  confirmed,

  /// El Edge respondió sin aplicarla, o el envío falló.
  failed,

  /// No llegó confirmación a tiempo; la orden puede seguir pendiente.
  unconfirmed,
}
