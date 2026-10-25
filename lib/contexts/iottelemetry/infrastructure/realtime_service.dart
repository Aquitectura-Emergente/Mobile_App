import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../config/api_config.dart';
import '../../../core/http/api_client.dart';
import '../../../screens/etapa3/etapa3_components.dart';
import '../../../services/app_i18n.dart';
import '../../../services/app_navigator.dart';
import '../../../services/app_settings_store.dart';
import '../../iam/infrastructure/session_store.dart';
import 'device_api.dart';
import 'notification_service.dart';

/// STOMP/WebSocket client for live telemetry.
///
/// The backend broadcasts every ingested reading globally to /topic/readings
/// (for admin/technician web) AND, when the sensor belongs to a client, to
/// /topic/clients/{clientId}/readings. The mobile app subscribes ONLY to its
/// own per-client topic, so a client never sees — or gets DANGER alerts about —
/// another client's sensors.
///
/// Screens listen to [readingTick] (a counter bumped on every reading) and
/// refresh their data. On DANGER, [dangerReading] is bumped so the app can pop
/// the "cut the power?" modal (see [DangerAlertGate]).
class RealtimeService {
  static StompClient? _client;
  static int? _userId;

  /// Bumped on every reading received; listen + debounce to refresh UI.
  static final ValueNotifier<int> readingTick = ValueNotifier<int>(0);

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
      final client = StompClient(
        config: StompConfig(
          url: ApiConfig.wsUrl,
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

  static void disconnect() {
    _client?.deactivate();
    _client = null;
    _dangerHandled.clear();
  }

  static void _onConnect(StompFrame frame) {
    // Own readings only. Fall back to the global topic if the user id is
    // unknown (shouldn't happen for a logged-in client), filtering by clientId.
    final destination = _userId != null
        ? '/topic/clients/$_userId/readings'
        : '/topic/readings';
    debugPrint('[EMSafe][WS] connected → $destination');
    _client?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          // Defensive filter (only relevant on the global fallback topic).
          if (_userId != null && data['clientId'] != null &&
              (data['clientId'] as num).toInt() != _userId) {
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

    // Offer to cut the power — once per DANGER episode per device, and only
    // while the power is still ON. If the plug already reports OFF (the user
    // or the device's local fail-safe already cut it) there is nothing to cut,
    // so we skip the modal. We do NOT mark the episode handled in that case, so
    // if the power comes back ON while still in DANGER we prompt again.
    final plugOff = (data['plug'] ?? '').toString().toUpperCase() == 'OFF';
    if (deviceId == null || plugOff || _dangerHandled.contains(deviceId)) return;
    _dangerHandled.add(deviceId);
    dangerReading.value = data;
  }
}

/// Mounts an app-wide listener that, on a DANGER reading for one of the
/// client's own sensors, asks whether to cut the power and — if confirmed —
/// sends the relay-OFF order (backend → edge → device). Uses [appNavigatorKey]
/// so the dialog appears regardless of the current screen.
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

    final deviceId = (data['deviceDbId'] as num?)?.toInt();
    if (deviceId == null) return;
    final name =
        (data['deviceName'] ?? data['serialNumber'] ?? 'Sensor').toString();
    final value = (data['field_uT'] as num?)?.toDouble();

    _dialogOpen = true;
    final cut = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogCtx) => _DangerDialog(name: name, value: value),
    );
    _dialogOpen = false;

    if (cut == true) {
      try {
        await DeviceApi.setPlug(deviceId, 'OFF');
        RealtimeService.readingTick.value++; // nudge screens to refresh
      } on ApiException catch (e) {
        final messenger = appNavigatorKey.currentContext;
        if (messenger != null && messenger.mounted) {
          ScaffoldMessenger.of(messenger)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Styled DANGER dialog (dark theme, red accent) offering to cut the power.
/// Pops `true` (cut) or `false` (keep on).
class _DangerDialog extends StatelessWidget {
  const _DangerDialog({required this.name, this.value});

  final String name;
  final double? value;

  @override
  Widget build(BuildContext context) {
    const red = Etapa3Palette.red;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: Etapa3Palette.panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: red.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: red.withValues(alpha: 0.22),
              blurRadius: 40,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: red.withValues(alpha: 0.14),
                border: Border.all(color: red.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: red, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              tr('danger_modalTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Etapa3Palette.text,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Etapa3Palette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${value?.toStringAsFixed(1) ?? '--'} µT',
                    style: const TextStyle(
                      color: red,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('danger_modalBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Etapa3Palette.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Etapa3Palette.muted,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Etapa3Palette.stroke),
                      ),
                    ),
                    child: Text(
                      tr('danger_keepOn'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(tr('danger_cutPower')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
