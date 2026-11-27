import 'package:flutter/material.dart';

import '../../contexts/alerts/application/alert_facade.dart';
import '../../contexts/alerts/domain/alert_filter.dart';
import '../../contexts/alerts/domain/client_alert.dart';
import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/devicemanagement/domain/plug_status.dart';
import '../../contexts/radiationmonitoring/domain/radiation_level.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'etapa3_components.dart';
import 'plug_screen.dart';
import 'sensor_detail_screen.dart';

class _AlertsData {
  _AlertsData(this.alerts, this.devices, this.plugStatus);
  final List<ClientAlert> alerts;
  final List<ClientDevice> devices;
  final PlugStatus? plugStatus;
}

/// Historial de alertas del hogar: registro de eventos por día, con filtros
/// y detalle de cada alerta.
class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  late Future<_AlertsData> _future = _load();
  AlertFilter _filter = const AlertFilter();

  Future<_AlertsData> _load() async {
    final alerts = await AlertFacade.all();
    // Dispositivos y enchufe son opcionales: si fallan, el historial se muestra igual.
    List<ClientDevice> devices = const [];
    PlugStatus? plug;
    try {
      devices = await DeviceFacade.all();
      final p = homePlugOf(devices);
      if (p != null) plug = await DeviceFacade.plugStatus(p);
    } catch (_) {}
    return _AlertsData(alerts, devices, plug);
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() { _future = f; });
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('al_title'),
      subtitle: tr('al_subtitle'),
      selectedIndex: 3,
      onRefresh: _reload,
      trailing: EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload),
      child: FutureBuilder<_AlertsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Etapa3Loading();
          if (snapshot.hasError && !snapshot.hasData) {
            final msg = snapshot.error is ApiException ? (snapshot.error as ApiException).message : tr('al_errLoad');
            return Etapa3Error(message: msg, onRetry: _reload);
          }
          return _buildList(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, _AlertsData data) {
    final alerts = _filter.apply(data.alerts);
    final tally = AlertFacade.tally(alerts);
    final devices = AlertFilter.devicesIn(data.alerts);
    final groups = <DateTime?, List<ClientAlert>>{};
    for (final a in alerts) {
      final t = etapa3ParseTime(a.recordedAt);
      groups.putIfAbsent(t == null ? null : DateTime(t.year, t.month, t.day), () => []).add(a);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => b == null ? -1 : (a == null ? 1 : b.compareTo(a)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tally(tally: tally),
        if (data.plugStatus?.lastCommand != null) ...[
          const SizedBox(height: EmsSpace.s4),
          _PlugEvent(
            command: data.plugStatus!.lastCommand!,
            onTap: () {
              final plug = homePlugOf(data.devices);
              if (plug != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlugScreen(device: plug)));
            },
          ),
        ],
        const SizedBox(height: EmsSpace.s7),
        EmsSegmented<AlertPeriod>(
          value: _filter.period,
          segments: [
            (AlertPeriod.all, tr('al_periodAll')),
            (AlertPeriod.today, tr('al_periodToday')),
            (AlertPeriod.week, tr('al_periodWeek')),
            (AlertPeriod.month, tr('al_periodMonth')),
          ],
          onChanged: (p) => setState(() => _filter = _filter.copyWith(period: p)),
        ),
        const SizedBox(height: EmsSpace.s4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(label: tr('m_allLevels'), selected: _filter.level == null, onTap: () => setState(() => _filter = _filter.copyWith(level: () => null))),
              for (final l in [RadiationLevel.danger, RadiationLevel.caution, RadiationLevel.safe])
                _Chip(
                  label: levelLabel(l),
                  color: levelSignal(context, l),
                  selected: _filter.level == l,
                  onTap: () => setState(() => _filter = _filter.copyWith(level: () => _filter.level == l ? null : l)),
                ),
              if (devices.length > 1)
                _Chip(
                  label: _filter.deviceId == null ? tr('al_allSensors') : (devices[_filter.deviceId] ?? tr('m_sensor')),
                  icon: PhosphorIconsRegular.caretDown,
                  selected: _filter.deviceId != null,
                  onTap: () => _pickDevice(context, devices),
                ),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s6),
        if (alerts.isEmpty)
          EmsPanel(
            padding: EdgeInsets.zero,
            child: EmsEmptyState(
              icon: PhosphorIconsRegular.checkCircle,
              title: tr(_filter.isActive ? 'al_emptyFiltered' : 'al_empty'),
              action: _filter.isActive
                  ? EmsButton(label: tr('m_clearFilters'), kind: EmsButtonKind.secondary, expand: false, onPressed: () => setState(() => _filter = const AlertFilter()))
                  : null,
            ),
          )
        else
          for (final k in keys) ...[
            EmsGroup(
              title: k == null ? tr('m_noDate') : EmsFormat.dayTitle(k),
              trailing: Text('${groups[k]!.length}', style: context.type.monoSm),
              children: [
                for (final a in groups[k]!) _AlertRow(alert: a, onTap: () => _openAlert(context, a, data.devices)),
              ],
            ),
            const SizedBox(height: EmsSpace.s6),
          ],
      ],
    );
  }

  Future<void> _pickDevice(BuildContext context, Map<int, String> devices) async {
    final picked = await showEmsSheet<int?>(
      context,
      title: tr('m_filterBySensor'),
      builder: (ctx) => EmsGroup(
        children: [
          EmsRow(
            title: tr('al_allSensors'),
            trailing: _filter.deviceId == null ? Icon(PhosphorIconsRegular.check, color: ctx.ems.primary, size: 18) : null,
            onTap: () => Navigator.of(ctx).pop(-1),
          ),
          for (final e in devices.entries)
            EmsRow(
              icon: PhosphorIconsRegular.broadcast,
              title: e.value,
              trailing: _filter.deviceId == e.key ? Icon(PhosphorIconsRegular.check, color: ctx.ems.primary, size: 18) : null,
              onTap: () => Navigator.of(ctx).pop(e.key),
            ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => _filter = _filter.copyWith(deviceId: () => picked == -1 ? null : picked));
  }

  void _openAlert(BuildContext context, ClientAlert a, List<ClientDevice> devices) {
    ClientDevice? device;
    for (final d in devices) {
      if (d.id == a.deviceId) device = d;
    }
    final t = etapa3ParseTime(a.recordedAt);
    showEmsSheet<void>(
      context,
      eyebrow: tr('m_alertDetail'),
      title: a.title,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [EmsTag(levelLabel(a.level), tone: levelTone(a.level), icon: levelIcon(a.level))]),
          const SizedBox(height: EmsSpace.s5),
          if (a.value != null) ...[
            EmsHeroValue(value: EmsFormat.value(a.value, decimals: 2), unit: 'µT', color: emsTone(ctx, levelTone(a.level)).fg, size: 44),
            const SizedBox(height: EmsSpace.s5),
          ],
          if (a.description.isNotEmpty) ...[
            Text(a.description, style: ctx.type.body.copyWith(color: ctx.ems.textSecondary)),
            const SizedBox(height: EmsSpace.s5),
          ],
          EmsGroup(
            children: [
              EmsKeyValue(label: tr('m_date'), value: t == null ? (a.time ?? '—') : EmsFormat.date(t)),
              if (t != null) EmsKeyValue(label: tr('m_time'), value: EmsFormat.timeSec(t), mono: true),
              EmsKeyValue(label: tr('m_source'), value: a.deviceName ?? device?.name ?? '—'),
              if (device?.location != null) EmsKeyValue(label: tr('m_location'), value: device!.location!),
              if (a.type.isNotEmpty) EmsKeyValue(label: tr('m_alertType'), value: a.type, mono: true),
            ],
          ),
          if (device != null && !device.isPlug) ...[
            const SizedBox(height: EmsSpace.s5),
            EmsButton(
              label: tr('m_openSensor'),
              kind: EmsButtonKind.secondary,
              icon: PhosphorIconsRegular.broadcast,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => SensorDetailScreen(device: device!)));
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.tally});

  final AlertTally tally;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    Widget cell(String label, int n, Color? color) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(EmsSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (color != null) ...[Container(width: 7, height: 7, color: color), const SizedBox(width: EmsSpace.s2)],
                    Flexible(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10))),
                  ],
                ),
                const SizedBox(height: EmsSpace.s2),
                Text('$n', style: context.type.metricLg.copyWith(fontSize: 26, color: n > 0 && color != null ? color : null)),
              ],
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(tr('al_total'), tally.total, null),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_lvDanger'), tally.danger, c.dangerSignal),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_lvCaution'), tally.caution, c.warningSignal),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onTap});

  final ClientAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = etapa3ParseTime(alert.recordedAt);
    return EmsRow(
      rail: levelSignal(context, alert.level),
      icon: levelIcon(alert.level),
      iconTone: levelTone(alert.level),
      title: alert.title,
      subtitle: [
        if (alert.deviceName != null) alert.deviceName!,
        if (t != null) EmsFormat.time(t) else if (alert.time != null) alert.time!,
      ].join(' · '),
      value: alert.value == null ? null : '${EmsFormat.value(alert.value)} µT',
      mono: true,
      onTap: onTap,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.color, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Padding(
      padding: const EdgeInsets.only(right: EmsSpace.s3),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? c.primarySubtle : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EmsRadius.sm),
            side: BorderSide(color: selected ? c.primaryBorder : c.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(EmsRadius.sm),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s4),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (color != null) ...[Container(width: 7, height: 7, color: color), const SizedBox(width: EmsSpace.s3)],
                  Text(label, style: context.type.label.copyWith(color: selected ? c.primary : c.text)),
                  if (icon != null) ...[const SizedBox(width: EmsSpace.s2), Icon(icon, size: 14, color: c.textTertiary)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Última orden al enchufe: evento del actuador, no una lectura.
class _PlugEvent extends StatelessWidget {
  const _PlugEvent({required this.command, required this.onTap});

  final PlugCommand command;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final off = command.action == PlugPower.off;
    final (label, tone) = command.isConfirmed
        ? (tr('al_plugConfirmed'), EmsTone.safe)
        : command.hasFailed
            ? (tr('al_plugFailed'), EmsTone.danger)
            : (tr('plug_pendingBadge'), EmsTone.warning);
    return EmsPanel(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: EmsRow(
        icon: PhosphorIconsRegular.plug,
        title: tr(off ? 'al_plugOff' : 'al_plugOn'),
        subtitle: '${tr('m_actuatorEvent')} · ${etapa3TimeAgo(command.requestedAt)}',
        trailing: EmsTag(label, tone: tone),
        onTap: onTap,
      ),
    );
  }
}
