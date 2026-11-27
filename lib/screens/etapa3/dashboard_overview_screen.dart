import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/devicemanagement/infrastructure/notification_service.dart';
import '../../contexts/devicemanagement/infrastructure/realtime_service.dart';
import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../contexts/radiationmonitoring/domain/client_dashboard.dart';
import '../../contexts/radiationmonitoring/domain/client_reading.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../routes/etapa3_routes.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'astra_chat_screen.dart';
import 'etapa3_components.dart';
import 'home_presenters.dart';
import 'map_radiation_screen.dart';
import 'plug_screen.dart';
import 'reading_detail_screen.dart';
import 'reports_screen.dart';
import 'sensor_detail_screen.dart';

/// Inicio del hogar: estado general, lecturas clave, sensores, actuador,
/// actividad reciente y accesos.
class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  late Future<ClientDashboard> _future;
  Timer? _liveDebounce;

  @override
  void initState() {
    super.initState();
    _future = MonitoringFacade.dashboard();
    RealtimeService.ensureConnected();
    RealtimeService.readingTick.addListener(_onLiveReading);
    NotificationService.init();
  }

  @override
  void dispose() {
    _liveDebounce?.cancel();
    RealtimeService.readingTick.removeListener(_onLiveReading);
    super.dispose();
  }

  void _onLiveReading() {
    _liveDebounce?.cancel();
    _liveDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _reload();
    });
  }

  Future<void> _reload() async {
    final future = MonitoringFacade.dashboard();
    setState(() { _future = future; });
    try {
      await future;
    } catch (_) {}
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((_) => _reload());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClientDashboard>(
      future: _future,
      builder: (context, snapshot) {
        return Etapa3Shell(
          title: tr('nav_home'),
          subtitle: tr('dash_subtitle'),
          selectedIndex: 0,
          onRefresh: _reload,
          trailing: EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload),
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<ClientDashboard> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
      return const Etapa3Loading();
    }
    if (snapshot.hasError && !snapshot.hasData) {
      final msg = snapshot.error is ApiException ? (snapshot.error as ApiException).message : tr('dash_errLoad');
      return Etapa3Error(message: msg, onRetry: _reload);
    }

    final data = snapshot.data!;
    if (!data.hasDevices) {
      return _NoDevices(onGuide: () => Navigator.of(context).pushNamed(Etapa3Routes.emptyState));
    }
    final sensors = data.devices.where((d) => !d.isPlug).toList();
    final plugs = data.devices.where((d) => d.isPlug).toList();
    final recent = [...data.latestReadings]..sort((a, b) => (b.takenAt ?? DateTime(0)).compareTo(a.takenAt ?? DateTime(0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusHero(data: data),
        const SizedBox(height: EmsSpace.s4),
        _Readouts(data: data, onAlerts: () => Navigator.of(context).pushNamed(Etapa3Routes.alertHistory)),
        const SizedBox(height: EmsSpace.s8),

        EmsSectionHeader(
          index: '01',
          title: tr('m_sources'),
          trailing: Text('${data.activeDeviceCount}/${sensors.length}', style: context.type.monoSm),
        ),
        EmsGroup(
          children: [
            for (final s in sensors)
              _SensorRow(
                device: s,
                onTap: () => _push(SensorDetailScreen(device: s)),
              ),
          ],
        ),
        if (plugs.isNotEmpty) ...[
          const SizedBox(height: EmsSpace.s7),
          EmsSectionHeader(index: '02', title: tr('m_actuators')),
          EmsGroup(
            children: [
              for (final p in plugs)
                EmsRow(
                  icon: PhosphorIconsRegular.plug,
                  iconTone: p.isPlugOn ? EmsTone.safe : EmsTone.neutral,
                  title: p.name,
                  subtitle: p.plugOrderPending ? tr(p.pendingPlug == PlugPower.off ? 'm_pendingOff' : 'm_pendingOn') : tr('m_smartPlugKind'),
                  trailing: p.plugOrderPending
                      ? EmsTag(tr('plug_pendingBadge'), tone: EmsTone.warning)
                      : EmsTag(
                          p.realPlug == null ? tr('m_unknown') : tr(p.isPlugOn ? 'm_on' : 'm_off'),
                          tone: p.isPlugOn ? EmsTone.safe : EmsTone.neutral,
                          icon: PhosphorIconsRegular.power,
                        ),
                  onTap: () => _push(PlugScreen(device: p)),
                ),
            ],
          ),
        ],
        if (recent.isNotEmpty) ...[
          const SizedBox(height: EmsSpace.s7),
          EmsSectionHeader(index: plugs.isEmpty ? '02' : '03', title: tr('m_recentActivity')),
          EmsGroup(
            children: [for (final r in recent.take(5)) _ActivityRow(reading: r, devices: data.devices)],
          ),
        ],
        const SizedBox(height: EmsSpace.s7),
        EmsSectionHeader(title: tr('m_explore')),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ExploreTile(icon: PhosphorIconsRegular.chartBar, label: tr('dash_qaReports'), onTap: () => _push(const ReportsScreen())),
              ),
              const SizedBox(width: EmsSpace.s4),
              Expanded(
                child: _ExploreTile(icon: PhosphorIconsRegular.mapTrifold, label: tr('dash_qaMap'), onTap: () => _push(const MapRadiationScreen())),
              ),
              const SizedBox(width: EmsSpace.s4),
              Expanded(
                child: _ExploreTile(icon: PhosphorIconsRegular.sparkle, label: tr('dash_qaAstra'), ai: true, onTap: () => _push(const AstraChatScreen())),
              ),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s7),
        Text(tr('ds_notMetrology'), textAlign: TextAlign.center, style: context.type.caption),
      ],
    );
  }
}

/// Estado del hogar: nivel decidido por el backend, media actual y escala.
class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.data});

  final ClientDashboard data;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final level = data.level;
    final t = emsTone(context, levelTone(level));
    final msg = switch (level) {
      'danger' => tr('dash_msgDanger'),
      'caution' => tr('dash_msgCaution'),
      _ => tr('dash_msgSafe'),
    };
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(EmsRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: t.bg,
            padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s5, EmsSpace.s4),
            child: Row(
              children: [
                Icon(levelIcon(level), color: t.fg, size: 22),
                const SizedBox(width: EmsSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(levelLabel(level).toUpperCase(), style: context.type.eyebrow.copyWith(color: t.fg)),
                      const SizedBox(height: 2),
                      Text(msg, style: context.type.bodySm.copyWith(color: c.text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 3, color: t.signal),
          Padding(
            padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s6, EmsSpace.s6, EmsSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmsHeroValue(label: tr('dash_currentExposure'), value: EmsFormat.value(data.currentAverage, decimals: 2), unit: 'µT'),
                const SizedBox(height: EmsSpace.s2),
                Text(tr('m_avgOfSensors'), style: context.type.caption),
                const SizedBox(height: EmsSpace.s5),
                HomeLevelScale(value: data.currentAverage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Readouts extends StatelessWidget {
  const _Readouts({required this.data, required this.onAlerts});

  final ClientDashboard data;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    Widget cell(String label, String value, {String? unit, Color? color, VoidCallback? onTap}) => Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(EmsSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10)),
              const SizedBox(height: EmsSpace.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value, style: context.type.metricMd.copyWith(color: color)),
                    ),
                  ),
                  if (unit != null) ...[const SizedBox(width: 3), Text(unit, style: context.type.monoSm)],
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(EmsRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(tr('dash_peak'), EmsFormat.value(data.maxValue), unit: 'µT', color: emsTone(context, levelTone(levelForPeak(data.maxValue))).fg),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_reporting'), '${data.activeDeviceCount}/${data.deviceCount}', color: data.silentDeviceCount > 0 ? c.warning : null),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('dash_alerts'), '${data.alertCount}', color: data.alertCount > 0 ? c.warning : null, onTap: onAlerts),
          ],
        ),
      ),
    );
  }
}

String levelForPeak(double v) => MonitoringFacade.levelFor(v);

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.device, required this.onTap});

  final ClientDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final signal = sensorSignal(device);
    final level = device.latestLevel;
    return EmsRow(
      rail: level == null ? null : levelSignal(context, level),
      title: device.name,
      subtitle: device.location?.isNotEmpty == true ? device.location : signal.$2,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            EmsFormat.value(device.latestValue),
            style: context.type.mono.copyWith(fontSize: 16, color: level == null ? context.ems.text : emsTone(context, levelTone(level)).fg),
          ),
          const SizedBox(width: 3),
          Text('µT', style: context.type.monoSm),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.reading, required this.devices});

  final ClientReading reading;
  final List<ClientDevice> devices;

  @override
  Widget build(BuildContext context) {
    final at = reading.takenAt;
    ClientDevice? device;
    for (final d in devices) {
      if (d.id == reading.deviceId) device = d;
    }
    final level = reading.effectiveLevel;
    return EmsRow(
      rail: levelSignal(context, level),
      title: '${EmsFormat.value(reading.value, decimals: 2)} µT',
      subtitle:
          '${reading.deviceName ?? device?.name ?? tr('m_sensor')} · ${at == null ? '—' : (reading.hasExactTime ? '${EmsFormat.dayTitle(at)} ${EmsFormat.time(at)}' : EmsFormat.dayTitle(at))}',
      trailing: EmsTag(levelLabel(level), tone: levelTone(level)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HomeReadingDetailScreen(reading: reading, device: device),
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.icon, required this.label, required this.onTap, this.ai = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final color = ai ? c.accent : c.primary;
    return EmsPanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(EmsSpace.s4, EmsSpace.s5, EmsSpace.s4, EmsSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: EmsSpace.s5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.label.copyWith(color: c.text, fontWeight: FontWeight.w600),
          ),
          if (ai) ...[const SizedBox(height: EmsSpace.s2), const EmsAiBadge('IA')],
        ],
      ),
    );
  }
}

class _NoDevices extends StatelessWidget {
  const _NoDevices({required this.onGuide});

  final VoidCallback onGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmsPanel(
          padding: EdgeInsets.zero,
          child: EmsEmptyState(
            icon: PhosphorIconsRegular.broadcast,
            title: tr('dash_noSensors'),
            message: tr('m_noDevicesMsg'),
            action: EmsButton(label: tr('m_howInstall'), kind: EmsButtonKind.secondary, expand: false, onPressed: onGuide),
          ),
        ),
      ],
    );
  }
}
