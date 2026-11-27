import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/devicemanagement/domain/plug_status.dart';
import '../../contexts/devicemanagement/infrastructure/realtime_service.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';

class _PlugView {
  _PlugView(this.device, this.status);
  final ClientDevice device;

  /// Null si el servicio del enchufe no respondió.
  final PlugStatus? status;
}

/// El enchufe inteligente es un actuador: recibe órdenes y confirma su estado.
/// No mide campo, así que aquí no hay lecturas ni recuentos.
class PlugScreen extends StatefulWidget {
  const PlugScreen({super.key, required this.device});

  final ClientDevice device;

  @override
  State<PlugScreen> createState() => _PlugScreenState();
}

class _PlugScreenState extends State<PlugScreen> {
  late Future<_PlugView> _future = _load();
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    RealtimeService.readingTick.addListener(_onTick);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    RealtimeService.readingTick.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _reload();
    });
  }

  Future<_PlugView> _load() async {
    final devices = await DeviceFacade.all();
    final device = devices.firstWhere((d) => d.id == widget.device.id, orElse: () => widget.device);
    PlugStatus? status;
    try {
      status = await DeviceFacade.plugStatus(device);
    } catch (_) {
      status = null;
    }
    return _PlugView(device, status);
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() { _future = f; });
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _order(ClientDevice device, String action) async {
    if (action == PlugPower.off) {
      final ok = await showEmsConfirm(
        context,
        title: tr('m_plugOffTitle'),
        message: tr('m_plugOffMsg'),
        confirmLabel: tr('m_plugTurnOff'),
        cancelLabel: tr('common_cancel'),
        tone: EmsTone.danger,
        icon: PhosphorIconsRegular.power,
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await sendPlugOrder(device, action);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PlugView>(
      future: _future,
      builder: (context, snap) {
        final device = snap.data?.device ?? widget.device;
        final status = snap.data?.status;
        final state = status?.state ?? device.realPlug;
        final pending = status?.pendingCommand != null || device.plugOrderPending;
        final isOn = state == PlugPower.on;
        final known = state == PlugPower.on || state == PlugPower.off;
        return EmsPage(
          eyebrow: tr('m_actuator'),
          title: device.name,
          onRefresh: _reload,
          actions: [EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload)],
          bottom: snap.hasData
              ? EmsButton(
                  label: pending ? tr('m_plugWaiting') : tr(isOn ? 'm_plugTurnOff' : 'm_plugTurnOn'),
                  icon: PhosphorIconsRegular.power,
                  kind: isOn ? EmsButtonKind.danger : EmsButtonKind.primary,
                  loading: _busy,
                  onPressed: pending || _busy ? null : () => _order(device, PlugPower.toggle(state)),
                )
              : null,
          child: snap.connectionState == ConnectionState.waiting && !snap.hasData
              ? const EmsLoadingBlock(lines: 2)
              : snap.hasError && !snap.hasData
                  ? EmsPanel(
                      child: EmsEmptyState(
                        kind: EmsEmptyKind.offline,
                        title: tr('m_plugErr'),
                        action: EmsButton(label: tr('common_retry'), kind: EmsButtonKind.secondary, expand: false, onPressed: _reload),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PowerState(isOn: isOn, known: known, pending: pending, pendingAction: status?.pendingCommand?.action ?? device.pendingPlug),
                        const SizedBox(height: EmsSpace.s5),
                        if (status == null)
                          EmsBanner(tone: EmsTone.warning, icon: PhosphorIconsRegular.cloudSlash, message: tr('m_plugStatusUnavailable'))
                        else if (!known)
                          EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.info, message: tr('m_plugUnknownMsg')),
                        if (status == null || !known) const SizedBox(height: EmsSpace.s5),
                        EmsGroup(
                          title: tr('m_plugConfirmed'),
                          footer: tr('m_plugConfirmedNote'),
                          children: [
                            EmsKeyValue(label: tr('m_plugState'), value: known ? tr(isOn ? 'm_on' : 'm_off') : tr('m_unknown')),
                            EmsKeyValue(
                              label: tr('m_lastConfirmation'),
                              value: _when(status?.changedAt),
                              mono: true,
                            ),
                            if (status?.source != null)
                              EmsKeyValue(label: tr('m_changedBy'), value: status!.source == 'AUTO' ? tr('m_byEdge') : tr('m_byUser')),
                          ],
                        ),
                        const SizedBox(height: EmsSpace.s7),
                        _LastOrder(command: status?.lastCommand),
                        const SizedBox(height: EmsSpace.s7),
                        EmsGroup(
                          title: tr('m_aboutPlug'),
                          children: [
                            EmsRow(icon: PhosphorIconsRegular.plug, title: tr('m_plugIsActuator'), subtitle: tr('m_plugIsActuatorMsg')),
                            EmsRow(icon: PhosphorIconsRegular.lightning, title: tr('m_plugDanger'), subtitle: tr('m_plugDangerMsg')),
                          ],
                        ),
                        const SizedBox(height: EmsSpace.s4),
                        EmsExpandable(
                          title: tr('m_technical'),
                          icon: PhosphorIconsRegular.hash,
                          child: Column(
                            children: [
                              EmsKeyValue(label: tr('m_deviceId'), value: '#${device.id}', mono: true),
                              if (device.serialNumber != null) EmsKeyValue(label: tr('m_serial'), value: device.serialNumber!, mono: true),
                              if (device.location != null) EmsKeyValue(label: tr('m_location'), value: device.location!),
                              if (status?.lastCommand != null) EmsKeyValue(label: tr('m_commandId'), value: status!.lastCommand!.commandId, mono: true),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

String _when(String? iso) {
  final t = DateTime.tryParse(iso ?? '')?.toLocal();
  return t == null ? '—' : EmsFormat.dateTime(t);
}

/// Visual del relé: interruptor grande con estado confirmado.
class _PowerState extends StatelessWidget {
  const _PowerState({required this.isOn, required this.known, required this.pending, this.pendingAction});

  final bool isOn;
  final bool known;
  final bool pending;
  final String? pendingAction;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final tone = !known ? EmsTone.neutral : (isOn ? EmsTone.safe : EmsTone.neutral);
    final t = emsTone(context, tone);
    return Container(
      padding: const EdgeInsets.all(EmsSpace.s6),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
      child: Row(
        children: [
          // Relé dibujado: carril con posición.
          Semantics(
            label: known ? tr(isOn ? 'm_on' : 'm_off') : tr('m_unknown'),
            child: Container(
              width: 64,
              height: 108,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: c.bgSunken,
                borderRadius: BorderRadius.circular(EmsRadius.lg),
                border: Border.all(color: isOn ? t.border : c.borderStrong),
              ),
              child: AnimatedAlign(
                duration: EmsDuration.slow,
                curve: Curves.easeOutCubic,
                alignment: !known ? Alignment.center : (isOn ? Alignment.topCenter : Alignment.bottomCenter),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isOn ? c.safeSignal : (known ? c.surfaceRaised : c.bgSunken),
                    borderRadius: BorderRadius.circular(EmsRadius.md),
                    border: Border.all(color: isOn ? c.safeSignal : c.borderStrong),
                  ),
                  child: Icon(PhosphorIconsRegular.power, size: 20, color: isOn ? c.textInverse : c.textTertiary),
                ),
              ),
            ),
          ),
          const SizedBox(width: EmsSpace.s6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('m_plugState').toUpperCase(), style: context.type.eyebrow),
                const SizedBox(height: EmsSpace.s2),
                Text(
                  known ? tr(isOn ? 'm_onLong' : 'm_offLong') : tr('m_unknown'),
                  style: context.type.h2.copyWith(color: isOn ? c.safe : c.text),
                ),
                const SizedBox(height: EmsSpace.s3),
                if (pending)
                  EmsSignal(
                    state: EmsSignalState.pending,
                    label: tr(pendingAction == PlugPower.off ? 'm_pendingOff' : 'm_pendingOn'),
                  )
                else
                  Text(tr('m_confirmedByEdge'), style: context.type.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Última orden enviada y su estado de ejecución.
class _LastOrder extends StatelessWidget {
  const _LastOrder({required this.command});

  final PlugCommand? command;

  @override
  Widget build(BuildContext context) {
    final cmd = command;
    if (cmd == null) {
      return EmsGroup(
        title: tr('m_lastOrder'),
        children: [EmsRow(icon: PhosphorIconsRegular.paperPlaneRight, title: tr('m_noOrders'), subtitle: tr('m_noOrdersMsg'))],
      );
    }
    final (label, tone, icon) = cmd.isConfirmed
        ? (tr('m_cmdConfirmed'), EmsTone.safe, PhosphorIconsRegular.checkCircle)
        : cmd.status == PlugCommandStatus.notApplied
            ? (tr('m_cmdNotApplied'), EmsTone.danger, PhosphorIconsRegular.xCircle)
            : cmd.status == PlugCommandStatus.sendFailed
                ? (tr('m_cmdSendFailed'), EmsTone.danger, PhosphorIconsRegular.cloudSlash)
                : (tr('m_cmdPending'), EmsTone.warning, PhosphorIconsRegular.hourglassMedium);
    final steps = [
      (tr('m_stepSent'), cmd.requestedAt, true),
      (tr('m_stepEdge'), cmd.resolvedAt, !cmd.isPending),
    ];
    return EmsGroup(
      title: tr('m_lastOrder'),
      footer: tr('m_historyLimited'),
      children: [
        EmsRow(
          icon: PhosphorIconsRegular.power,
          iconTone: cmd.action == PlugPower.off ? EmsTone.neutral : EmsTone.safe,
          title: tr(cmd.action == PlugPower.off ? 'm_orderOff' : 'm_orderOn'),
          subtitle: _when(cmd.requestedAt),
          trailing: EmsTag(label, tone: tone, icon: icon),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s5, EmsSpace.s5),
          child: Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                _Step(label: steps[i].$1, at: steps[i].$2, done: steps[i].$3, last: i == steps.length - 1, tone: i == steps.length - 1 ? tone : EmsTone.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.at, required this.done, required this.last, required this.tone});

  final String label;
  final String? at;
  final bool done;
  final bool last;
  final EmsTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final t = emsTone(context, tone);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: done ? t.signal : null,
                  border: Border.all(color: done ? t.signal : c.borderStrong, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (!last) Expanded(child: Container(width: 1, color: c.borderStrong)),
            ],
          ),
          const SizedBox(width: EmsSpace.s4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : EmsSpace.s5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label, style: context.type.bodySm.copyWith(color: done ? c.text : c.textTertiary))),
                  Text(done ? _when(at) : '—', style: context.type.monoSm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
