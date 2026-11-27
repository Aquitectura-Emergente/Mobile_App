import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../config/api_config.dart';
import '../../../core/http/api_client.dart';
import '../../../services/app_i18n.dart';
import '../../../services/app_navigator.dart';
import '../../../services/app_settings_store.dart';
import '../../iam/infrastructure/session_store.dart';
import '../application/device_facade.dart';
import '../domain/client_device.dart';
import '../domain/plug_status.dart';
import 'notification_service.dart';
import '../../../design_system/design_system.dart';

/// STOMP/WebSocket client for live telemetry.
///
/// The app subscribes only to /topic/clients/{clientId}/readings, so a client
/// never sees (or gets DANGER alerts about) another client's sensors.
///
/// Screens listen to [readingTick] (a counter bumped on every reading) and
/// refresh their data. On DANGER, [dangerReading] is bumped so the app can pop
/// the "cut the power?" modal (see [DangerAlertGate]).
class RealtimeService {
  static StompClient? _client;
  static int? _userId;

  /// Bumped on every reading received; listen + debounce to refresh UI.
  static final ValueNotifier<int> readingTick = ValueNotifier<int>(0);

  /// Sube con cada alerta en vivo del operario, para refrescar sus pantallas.
  static final ValueNotifier<int> workerAlertTick = ValueNotifier<int>(0);

  /// Raw payload of the last reading received (ReadingDto JSON).
  static Map<String, dynamic>? lastReading;

  /// Payload of the last DANGER reading for one of the client's OWN devices,
  /// pushed once per DANGER episode per device (see [_dangerHandled]). The
  /// [DangerAlertGate] listens to this to offer cutting the power.
  static final ValueNotifier<Map<String, dynamic>?> dangerReading =
      ValueNotifier<Map<String, dynamic>?>(null);

  /// Devices currently in a handled DANGER episode — avoids re-popping the
  /// modal on every reading while the level stays DANGER. Cleared when the same
  /// device reports a non-DANGER reading.
  static final Set<int> _dangerHandled = <int>{};

  /// Guards against tearing down a client that is still in its initial
  /// connection handshake (both dashboard + monitor call this on init).
  static bool _activating = false;

  static Future<void> ensureConnected() async {
    SessionStore.addClearListener(disconnect);
    final userId = await SessionStore.userId();
    if (needsNewConnection(connectedUserId: _userId, currentUserId: userId)) {
      disconnect();
    }
    final existing = _client;
    if (existing != null) {
      // Reuse a live connection. If stomp's own auto-reconnect ever gives up
      // (e.g. the backend was restarted), the client reports disconnected —
      // drop it and build a fresh one so we always re-subscribe.
      if (existing.connected || _activating) return;
      existing.deactivate();
      _client = null;
    }
    if (_activating) return;
    _activating = true;
    try {
      _userId = await SessionStore.userId();
      // El backend exige el JWT en el CONNECT de STOMP.
      final token = SessionStore.token;
      final client = StompClient(
        config: StompConfig(
          url: ApiConfig.wsUrl,
          stompConnectHeaders: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          reconnectDelay: const Duration(seconds: 5),
          onConnect: _onConnect,
          onWebSocketError: (dynamic error) =>
              debugPrint('[EMSafe][WS] error: $error'),
        ),
      );
      _client = client;
      client.activate();
    } finally {
      _activating = false;
    }
  }

  /// Una conexión abierta para otra cuenta no se reutiliza.
  static bool needsNewConnection({int? connectedUserId, int? currentUserId}) =>
      connectedUserId != null && connectedUserId != currentUserId;

  static void disconnect() {
    _client?.deactivate();
    _client = null;
    _userId = null;
    lastReading = null;
    dangerReading.value = null;
    _dangerHandled.clear();
  }

  static void _onConnect(StompFrame frame) {
    // Solo el tópico propio: el global trae lecturas de todos los clientes.
    final userId = _userId;
    if (userId == null) return;
    if (SessionStore.isOperator) {
      _subscribeWorkerAlerts(userId);
      return;
    }
    final destination = '/topic/clients/$userId/readings';
    debugPrint('[EMSafe][WS] connected → $destination');
    _client?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['clientId'] != null &&
              (data['clientId'] as num).toInt() != userId) {
            return;
          }
          lastReading = data;
          readingTick.value++;
          _handleLevel(data);
        } catch (_) {
          // Ignore malformed frames — next reading will arrive shortly.
        }
      },
    );
  }

  /// Alertas del operario: el backend las empuja apenas se generan.
  static void _subscribeWorkerAlerts(int userId) {
    final destination = '/topic/workers/$userId/alerts';
    debugPrint('[EMSafe][WS] connected → $destination');
    _client?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          workerAlertTick.value++;
          if (AppSettingsStore.pushAlerts) {
            NotificationService.showAlert(
              (data['title'] ?? tr('notif_dangerTitle')).toString(),
              (data['description'] ?? '').toString(),
            );
          }
        } catch (_) {}
      },
    );
  }

  static void _handleLevel(Map<String, dynamic> data) {
    final level = (data['level'] ?? '').toString().toUpperCase();
    final deviceId = (data['deviceDbId'] as num?)?.toInt();

    if (level != 'DANGER') {
      // Episode ended for this device — allow future DANGER modals again.
      if (deviceId != null) _dangerHandled.remove(deviceId);
      return;
    }

    // Local notification (Settings → Push alerts).
    if (AppSettingsStore.pushAlerts) {
      final name =
          (data['deviceName'] ?? data['serialNumber'] ?? 'Sensor').toString();
      final value = (data['field_uT'] as num?)?.toDouble();
      NotificationService.showDangerAlert(name, value);
    }

    // Una ventana por episodio DANGER y sensor. Si el enchufe ya está apagado
    // lo decide la ventana con el estado real, no esta lectura.
    if (deviceId == null || _dangerHandled.contains(deviceId)) return;
    _dangerHandled.add(deviceId);
    dangerReading.value = data;
  }
}

/// Ante una lectura DANGER de un sensor del cliente, pregunta si apagar el
/// enchufe del hogar y sigue la orden hasta que el Edge la confirme. Usa
/// [appNavigatorKey] para que la ventana salga en cualquier pantalla.
class DangerAlertGate extends StatefulWidget {
  const DangerAlertGate({super.key, required this.child});

  final Widget child;

  @override
  State<DangerAlertGate> createState() => _DangerAlertGateState();
}

class _DangerAlertGateState extends State<DangerAlertGate> {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    RealtimeService.dangerReading.addListener(_onDanger);
  }

  @override
  void dispose() {
    RealtimeService.dangerReading.removeListener(_onDanger);
    super.dispose();
  }

  Future<void> _onDanger() async {
    final data = RealtimeService.dangerReading.value;
    if (data == null || _dialogOpen) return;
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    final name =
        (data['deviceName'] ?? data['serialNumber'] ?? 'Sensor').toString();
    final value = (data['field_uT'] as num?)?.toDouble();

    _dialogOpen = true;
    try {
      // La lectura viene del sensor; la orden va al enchufe del hogar.
      final plug = await DeviceFacade.homePlug();
      if (plug == null || plug.plugOrderPending) return;
      if (plug.realPlug == PlugPower.off) return;
      if (!ctx.mounted) return;

      final cut = await showDialog<bool>(
        context: ctx,
        barrierDismissible: false,
        barrierColor: ctx.ems.scrim,
        builder: (dialogCtx) => _DangerDialog(name: name, value: value),
      );
      if (cut == true) await sendPlugOrder(plug, PlugPower.off);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Styled DANGER dialog (dark theme, red accent) offering to cut the power.
/// Pops `true` (cut) or `false` (keep on).
/// Envía la orden al enchufe, avisa que quedó pendiente y luego el resultado.
/// Las pantallas se refrescan con [RealtimeService.readingTick].
Future<PlugOrderOutcome?> sendPlugOrder(ClientDevice plug, String action) async {
  try {
    final command = await DeviceFacade.requestPlug(plug, action);
    RealtimeService.readingTick.value++;
    _snack(tr('plug_pending'));
    final outcome = await DeviceFacade.awaitConfirmation(command);
    RealtimeService.readingTick.value++;
    _snack(switch (outcome) {
      PlugOrderOutcome.confirmed =>
        tr(action == PlugPower.off ? 'plug_confirmedOff' : 'plug_confirmedOn'),
      PlugOrderOutcome.failed => tr('plug_failed'),
      PlugOrderOutcome.unconfirmed => tr('plug_unconfirmed'),
    });
    return outcome;
  } on ApiException catch (e) {
    _snack(e.message);
    return null;
  }
}

void _snack(String message) {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  ScaffoldMessenger.of(ctx)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _DangerDialog extends StatelessWidget {
  const _DangerDialog({required this.name, this.value});

  final String name;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: EmsSpace.s7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.lg), side: BorderSide(color: c.dangerBorder)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banda crítica: el único relleno sólido rojo de la app.
          Container(
            color: c.dangerSignal,
            padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s4, EmsSpace.s6, EmsSpace.s4),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.warningOctagon, color: Colors.white, size: 22),
                const SizedBox(width: EmsSpace.s3),
                Expanded(child: Text(tr('m_lvDanger').toUpperCase(), style: context.type.eyebrow.copyWith(color: Colors.white))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s6, EmsSpace.s6, EmsSpace.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('danger_modalTitle'), style: context.type.h3),
                const SizedBox(height: EmsSpace.s5),
                EmsRailBox(
                  color: c.dangerSubtle,
                  borderColor: c.dangerBorder,
                  railColor: c.dangerSignal,
                  padding: const EdgeInsets.all(EmsSpace.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.type.body.copyWith(fontWeight: FontWeight.w600))),
                      const SizedBox(width: EmsSpace.s3),
                      Text(value?.toStringAsFixed(1) ?? '—', style: context.type.metricMd.copyWith(color: c.danger)),
                      const SizedBox(width: 3),
                      Text('µT', style: context.type.monoSm),
                    ],
                  ),
                ),
                const SizedBox(height: EmsSpace.s4),
                Text(tr('danger_modalBody'), style: context.type.body.copyWith(color: c.textSecondary)),
                const SizedBox(height: EmsSpace.s7),
                EmsButton(
                  label: tr('danger_cutPower'),
                  icon: PhosphorIconsRegular.power,
                  kind: EmsButtonKind.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: EmsSpace.s3),
                EmsButton(label: tr('danger_keepOn'), kind: EmsButtonKind.secondary, onPressed: () => Navigator.of(context).pop(false)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
