import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../contexts/personaldosimetry/domain/personal_reading.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';

class _ShiftReadings {
  const _ShiftReadings(this.session, this.readings);

  final ExposureSession? session;
  final List<PersonalReading> readings;
}

/// Lecturas del dosímetro en la jornada en curso (o la última).
class OperatorReadingsScreen extends StatefulWidget {
  const OperatorReadingsScreen({super.key});

  @override
  State<OperatorReadingsScreen> createState() => _OperatorReadingsScreenState();
}

class _OperatorReadingsScreenState extends State<OperatorReadingsScreen> {
  late Future<_ShiftReadings> _future = _load();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _reload());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<_ShiftReadings> _load() async {
    final session = await DosimetryFacade.currentShift();
    if (session == null) return const _ShiftReadings(null, []);
    return _ShiftReadings(
        session, await DosimetryFacade.latestShiftReadings(session.id));
  }

  void _reload() {
    if (!mounted) return;
    final future = _load();
    setState(() { _future = future; });
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('op_readingsTitle'),
      subtitle: tr('op_exposureSubtitle'),
      selectedIndex: 1,
      trailing: IconButton(
        icon: const Icon(Icons.refresh, color: Etapa3Palette.muted),
        onPressed: _reload,
      ),
      child: FutureBuilder<_ShiftReadings>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Etapa3Loading();
          }
          if (snap.hasError) {
            return Etapa3Error(message: snap.error.toString(), onRetry: _reload);
          }
          final data = snap.data!;
          if (data.session == null) {
            return OperatorEmpty(
              icon: Icons.sensors_off_outlined,
              title: tr('op_noDosimeter'),
              subtitle: tr('op_noDosimeterHint'),
            );
          }
          if (data.readings.isEmpty) {
            return OperatorEmpty(
              icon: Icons.show_chart,
              title: tr('op_noReadings'),
            );
          }
          return _ReadingsView(readings: data.readings);
        },
      ),
    );
  }
}

class _ReadingsView extends StatelessWidget {
  const _ReadingsView({required this.readings});

  final List<PersonalReading> readings;

  @override
  Widget build(BuildContext context) {
    final window = readings.length > 40
        ? readings.sublist(readings.length - 40)
        : readings;
    final peak = window
        .map((r) => r.fieldMicrotesla)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final scale = peak <= 0 ? 1.0 : peak;
    final recent = readings.reversed.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tr('op_peak')}: ${etapa3Num(peak)} $etapa3Unit',
                style: const TextStyle(
                  color: Etapa3Palette.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final r in window)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: FractionallySizedBox(
                            heightFactor:
                                (r.fieldMicrotesla / scale).clamp(0.03, 1.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Etapa3Palette.cyan.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('mon_recentReadings')),
        const SizedBox(height: 10),
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              for (final r in recent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Text(
                        etapa3TimeOfDay(r.capturedTo ?? r.capturedFrom),
                        style: const TextStyle(color: Etapa3Palette.muted, fontSize: 13),
                      ),
                      const SizedBox(width: 10),
                      if (r.isLate)
                        StatusPill(label: tr('op_late'), color: Etapa3Palette.blue),
                      const Spacer(),
                      Text(
                        '${etapa3Num(r.fieldMicrotesla)} $etapa3Unit',
                        style: const TextStyle(
                          color: Etapa3Palette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
