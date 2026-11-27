import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/devicemanagement/infrastructure/realtime_service.dart';
import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../contexts/radiationmonitoring/domain/client_reading.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'home_presenters.dart';
import 'reading_detail_screen.dart';

class _SensorView {
  _SensorView(this.device, this.readings);
  final ClientDevice device;
  final List<ClientReading> readings;
}

/// Un sensor fijo del hogar: lectura actual, gráfico compacto, últimas
/// lecturas y ficha del equipo.
class SensorDetailScreen extends StatefulWidget {
  const SensorDetailScreen({super.key, required this.device});

  final ClientDevice device;

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  late Future<_SensorView> _future = _load();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    RealtimeService.ensureConnected();
    RealtimeService.readingTick.addListener(_onLive);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    RealtimeService.readingTick.removeListener(_onLive);
    super.dispose();
  }

  void _onLive() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _reload();
    });
  }

  Future<_SensorView> _load() async {
    final results = await Future.wait([
      DeviceFacade.all(),
      MonitoringFacade.deviceReadings(widget.device.id),
    ]);
    final devices = results[0] as List<ClientDevice>;
    final device = devices.firstWhere((d) => d.id == widget.device.id, orElse: () => widget.device);
    return _SensorView(device, results[1] as List<ClientReading>);
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() { _future = f; });
    await f.catchError((_) => _SensorView(widget.device, const []));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SensorView>(
      future: _future,
      builder: (context, snap) {
        final device = snap.data?.device ?? widget.device;
        return EmsPage(
          eyebrow: tr('m_fixedSensor'),
          title: device.name,
          onRefresh: _reload,
          actions: [EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload)],
          child: _body(context, snap),
        );
      },
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<_SensorView> snap) {
    if (snap.connectionState == ConnectionState.waiting && !snap.hasData) return const EmsLoadingBlock();
    if (snap.hasError && !snap.hasData) {
      return EmsPanel(
        child: EmsEmptyState(
          kind: EmsEmptyKind.offline,
          title: snap.error is ApiException ? (snap.error as ApiException).message : tr('mon_errLoad'),
          action: EmsButton(label: tr('common_retry'), kind: EmsButtonKind.secondary, expand: false, onPressed: _reload),
        ),
      );
    }
    final c = context.ems;
    final device = snap.data!.device;
    final readings = snap.data!.readings;
    final points = homePoints(readings);
    final latest = points.isEmpty ? null : points.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
    final level = latest?.level ?? device.latestLevel;
    final signal = sensorSignal(device);
    final recent = [...points]..sort((a, b) => b.at.compareTo(a.at));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lectura actual.
        EmsRailBox(
          color: c.surface,
          borderColor: c.border,
          railColor: levelSignal(context, level),
          radius: EmsRadius.md,
          padding: const EdgeInsets.all(EmsSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EmsSignal(state: signal.$1, label: signal.$2),
                  const Spacer(),
                  if (level != null) EmsTag(levelLabel(level), tone: levelTone(level), icon: levelIcon(level)),
                ],
              ),
              const SizedBox(height: EmsSpace.s5),
              EmsHeroValue(
                label: tr('m_latestReading'),
                value: EmsFormat.value(latest?.value ?? device.latestValue, decimals: 2),
                unit: 'µT',
                color: level == null ? null : emsTone(context, levelTone(level)).fg,
              ),
              const SizedBox(height: EmsSpace.s3),
              Text(
                latest == null
                    ? (device.latestReadingDate ?? tr('m_noReadingsYet'))
                    : '${EmsFormat.dayTitle(latest.at)} · ${EmsFormat.time(latest.at)}',
                style: context.type.monoSm,
              ),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s5),
        if (readings.isEmpty)
          EmsPanel(
            padding: EdgeInsets.zero,
            child: EmsEmptyState(icon: PhosphorIconsRegular.chartBar, title: tr('m_noReadingsYet'), message: tr('m_noReadingsYetMsg')),
          )
        else
          MeasurementOverview(
            title: tr('m_fieldStrength'),
            points: points,
            guides: homeGuides(context),
            onShowAll: () => openSensorHistory(context, device, readings),
          ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: EmsSpace.s7),
          EmsGroup(
            title: tr('m_recentReadings'),
            children: [
              for (final p in recent.take(5))
                EmsRow(
                  rail: levelSignal(context, p.level),
                  title: '${EmsFormat.value(p.value, decimals: 2)} µT',
                  subtitle: '${EmsFormat.dayTitle(p.at)} · ${EmsFormat.time(p.at)}',
                  trailing: EmsTag(levelLabel(p.level), tone: levelTone(p.level)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HomeReadingDetailScreen(reading: p.source! as ClientReading, device: device),
                  )),
                ),
            ],
          ),
        ],
        const SizedBox(height: EmsSpace.s7),
        EmsGroup(
          title: tr('m_sensorSheet'),
          children: [
            if (device.location != null && device.location!.isNotEmpty) EmsKeyValue(label: tr('m_location'), value: device.location!),
            EmsKeyValue(label: tr('m_kind'), value: tr('m_fixedSensorKind')),
            EmsKeyValue(label: tr('m_totalReadings'), value: '${device.readingsCount}', mono: true),
            if (device.installDate != null) EmsKeyValue(label: tr('m_installed'), value: device.installDate!, mono: true),
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
              EmsKeyValue(label: tr('m_catalogStatus'), value: device.status, mono: true),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s6),
        Text(tr('ds_notMetrology'), textAlign: TextAlign.center, style: context.type.caption),
      ],
    );
  }
}
