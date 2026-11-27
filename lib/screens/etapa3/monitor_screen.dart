import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/devicemanagement/infrastructure/realtime_service.dart';
import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../contexts/radiationmonitoring/domain/client_reading.dart';
import '../../contexts/radiationmonitoring/domain/reading_series.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'etapa3_components.dart';
import 'home_presenters.dart';
import 'plug_screen.dart';
import 'sensor_detail_screen.dart';

class _MonitorData {
  _MonitorData(this.sensors, this.plugs, this.readings);
  final List<ClientDevice> sensors;
  final List<ClientDevice> plugs;

  /// Lecturas por sensor (vacío si no se pudieron cargar).
  final Map<int, List<ClientReading>> readings;
}

/// Pestaña Monitor: separa las fuentes de medición (sensores fijos) de los
/// actuadores (enchufe), porque producen cosas distintas.
class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late Future<_MonitorData> _future;
  Timer? _liveDebounce;

  @override
  void initState() {
    super.initState();
    _future = _load();
    RealtimeService.ensureConnected();
    RealtimeService.readingTick.addListener(_onLiveReading);
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

  Future<_MonitorData> _load() async {
    final devices = await DeviceFacade.all();
    final sensors = devices.where((d) => !d.isPlug).toList();
    final plugs = devices.where((d) => d.isPlug).toList();
    final lists = await Future.wait(sensors.map((s) async {
      try {
        return await MonitoringFacade.deviceReadings(s.id);
      } catch (_) {
        return const <ClientReading>[];
      }
    }));
    return _MonitorData(sensors, plugs, {for (var i = 0; i < sensors.length; i++) sensors[i].id: lists[i]});
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() { _future = future; });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('mon_title'),
      subtitle: tr('mon_subtitle'),
      selectedIndex: 1,
      onRefresh: _reload,
      trailing: EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload),
      child: FutureBuilder<_MonitorData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Etapa3Loading();
          }
          if (snapshot.hasError && !snapshot.hasData) {
            final msg = snapshot.error is ApiException ? (snapshot.error as ApiException).message : tr('mon_errLoad');
            return Etapa3Error(message: msg, onRetry: _reload);
          }
          return _body(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _body(BuildContext context, _MonitorData data) {
    if (data.sensors.isEmpty && data.plugs.isEmpty) {
      return EmsPanel(
        padding: EdgeInsets.zero,
        child: EmsEmptyState(
          icon: PhosphorIconsRegular.cellSignalSlash,
          title: tr('mon_noSensors'),
          message: tr('m_noDevicesMsg'),
        ),
      );
    }
    final reporting = data.sensors.where((s) => s.isReporting).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FleetStrip(sensors: data.sensors.length, reporting: reporting, plugs: data.plugs.length),
        const SizedBox(height: EmsSpace.s7),
        EmsSectionHeader(
          index: '01',
          title: tr('m_sources'),
          trailing: Text(tr('m_last24hShort'), style: context.type.monoSm),
        ),
        if (data.sensors.isEmpty)
          EmsPanel(padding: EdgeInsets.zero, child: EmsEmptyState(icon: PhosphorIconsRegular.broadcast, title: tr('m_noSensorsOnly')))
        else
          for (final s in data.sensors) ...[
            _SensorCard(
              device: s,
              readings: data.readings[s.id] ?? const [],
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => SensorDetailScreen(device: s)))
                  .then((_) => _reload()),
            ),
            const SizedBox(height: EmsSpace.s4),
          ],
        if (data.plugs.isNotEmpty) ...[
          const SizedBox(height: EmsSpace.s5),
          EmsSectionHeader(index: '02', title: tr('m_actuators')),
          for (final p in data.plugs) ...[
            _PlugRow(
              device: p,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => PlugScreen(device: p)))
                  .then((_) => _reload()),
            ),
            const SizedBox(height: EmsSpace.s4),
          ],
        ],
        const SizedBox(height: EmsSpace.s4),
        Text(tr('ds_notMetrology'), textAlign: TextAlign.center, style: context.type.caption),
      ],
    );
  }
}

class _FleetStrip extends StatelessWidget {
  const _FleetStrip({required this.sensors, required this.reporting, required this.plugs});

  final int sensors;
  final int reporting;
  final int plugs;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    Widget cell(String label, String value, {Color? color}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(EmsSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10)),
                const SizedBox(height: EmsSpace.s2),
                Text(value, style: context.type.metricMd.copyWith(color: color)),
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
            cell(tr('m_sensors'), '$sensors'),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_reporting'), '$reporting/$sensors', color: reporting < sensors ? c.warning : null),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_actuators'), '$plugs'),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de sensor: último valor, nivel, comunicación y 24 h en barras.
class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.device, required this.readings, required this.onTap});

  final ClientDevice device;
  final List<ClientReading> readings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final points = homePoints(readings);
    final buckets = ReadingSeries.forRange(points, SeriesRange.day);
    final latest = points.isEmpty ? null : points.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
    final level = latest?.level ?? device.latestLevel;
    final signal = sensorSignal(device);
    return EmsPanel(
      onTap: onTap,
      railColor: level == null ? null : levelSignal(context, level),
      padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s5, EmsSpace.s4, EmsSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.h4),
                    const SizedBox(height: 2),
                    Text(device.location?.isNotEmpty == true ? device.location! : tr('m_fixedSensorKind'), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.caption),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.textTertiary),
            ],
          ),
          const SizedBox(height: EmsSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          EmsFormat.value(latest?.value ?? device.latestValue, decimals: 1),
                          style: context.type.metricLg.copyWith(color: level == null ? c.text : emsTone(context, levelTone(level)).fg),
                        ),
                        const SizedBox(width: 4),
                        Text('µT', style: context.type.mono.copyWith(color: c.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: EmsSpace.s2),
                    Wrap(
                      spacing: EmsSpace.s3,
                      runSpacing: EmsSpace.s2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (level != null) EmsTag(levelLabel(level), tone: levelTone(level)),
                        EmsSignal(state: signal.$1, label: latest == null ? signal.$2 : EmsFormat.time(latest.at)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EmsSpace.s4),
              EmsSparkBars(bars: barsFor(context, buckets), width: 112, height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila del enchufe: estado del relé y orden pendiente; sin lecturas.
class _PlugRow extends StatelessWidget {
  const _PlugRow({required this.device, required this.onTap});

  final ClientDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = device.realPlug;
    final pending = device.plugOrderPending;
    return EmsPanel(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: EmsRow(
        icon: PhosphorIconsRegular.plug,
        iconTone: state == PlugPower.on ? EmsTone.safe : EmsTone.neutral,
        title: device.name,
        subtitle: pending
            ? tr(device.pendingPlug == PlugPower.off ? 'm_pendingOff' : 'm_pendingOn')
            : tr('m_smartPlugKind'),
        trailing: pending
            ? EmsTag(tr('plug_pendingBadge'), tone: EmsTone.warning, icon: PhosphorIconsRegular.hourglassMedium)
            : EmsTag(
                state == null ? tr('m_unknown') : tr(state == PlugPower.on ? 'm_on' : 'm_off'),
                tone: state == PlugPower.on ? EmsTone.safe : EmsTone.neutral,
                icon: PhosphorIconsRegular.power,
              ),
        onTap: onTap,
      ),
    );
  }
}
