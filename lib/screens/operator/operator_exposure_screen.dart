import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';

/// Exposición acumulada de la jornada frente al límite del puesto.
class OperatorExposureScreen extends StatefulWidget {
  const OperatorExposureScreen({super.key});

  @override
  State<OperatorExposureScreen> createState() => _OperatorExposureScreenState();
}

class _OperatorExposureScreenState extends State<OperatorExposureScreen> {
  // Sin canal en vivo para el operario: se consulta cada cierto tiempo.
  static const _refreshEvery = Duration(seconds: 20);

  late Future<ExposureSession?> _future = DosimetryFacade.currentShift();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_refreshEvery, (_) => _reload());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    final future = DosimetryFacade.currentShift();
    setState(() { _future = future; });
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('op_exposureTitle'),
      subtitle: tr('op_exposureSubtitle'),
      selectedIndex: 0,
      trailing: IconButton(
        icon: const Icon(Icons.refresh, color: Etapa3Palette.muted),
        onPressed: _reload,
      ),
      child: FutureBuilder<ExposureSession?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Etapa3Loading();
          }
          if (snap.hasError) {
            return Etapa3Error(message: snap.error.toString(), onRetry: _reload);
          }
          final session = snap.data;
          if (session == null || session.isClosed) {
            return _NoDosimeter(lastShift: session);
          }
          return _ShiftView(session: session);
        },
      ),
    );
  }
}

class _ShiftView extends StatelessWidget {
  const _ShiftView({required this.session});

  final ExposureSession session;

  @override
  Widget build(BuildContext context) {
    final status = session.status;
    final color = exposureColor(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          child: Column(
            children: [
              ExposureGauge(session: session),
              const SizedBox(height: 12),
              StatusPill(
                label: exposureLabel(status),
                color: color,
                icon: status == ExposureStatus.normal
                    ? Icons.verified_user_outlined
                    : Icons.warning_amber_rounded,
              ),
              if (!session.isOpen) ...[
                const SizedBox(height: 8),
                Text(
                  tr('op_shiftClosing'),
                  style: const TextStyle(color: Etapa3Palette.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TileRow(
          children: [
            MetricTile(
              icon: Icons.stacked_line_chart,
              label: tr('op_accumulated'),
              value: exposureIndex(session.accumulatedIndex),
              caption: session.unit,
              accent: color,
            ),
            MetricTile(
              icon: Icons.flag_outlined,
              label: tr('op_limit'),
              value: exposureIndex(session.limitIndex),
              caption: session.unit,
              accent: Etapa3Palette.blue,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TileRow(
          children: [
            MetricTile(
              icon: Icons.hourglass_bottom,
              label: tr('op_remaining'),
              value: exposureIndex(session.remainingIndex),
              caption: session.unit,
              accent: Etapa3Palette.cyan,
            ),
            MetricTile(
              icon: Icons.schedule,
              label: tr('op_started'),
              value: etapa3TimeOfDay(session.startedAt),
              caption: session.coveragePercentage == null
                  ? null
                  : '${tr('op_coverage')} ${exposurePercent(session.coveragePercentage!)}',
              accent: Etapa3Palette.muted,
            ),
          ],
        ),
        if (status != ExposureStatus.normal) ...[
          const SizedBox(height: 20),
          SectionLabel(tr('op_recommendations')),
          const SizedBox(height: 10),
          _Recommendations(exceeded: status == ExposureStatus.exceeded),
        ],
      ],
    );
  }
}

/// Fila de dos tarjetas con la altura de la más alta: sin altura fija, el
/// contenido nunca se desborda aunque la pantalla sea estrecha o el texto grande.
class _TileRow extends StatelessWidget {
  const _TileRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 12),
          Expanded(child: children[1]),
        ],
      ),
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({required this.exceeded});

  final bool exceeded;

  @override
  Widget build(BuildContext context) {
    final tips = [
      if (exceeded) tr('op_recExceeded'),
      tr('op_rec1'),
      tr('op_rec2'),
      tr('op_rec3'),
    ];
    final color = exceeded ? Etapa3Palette.red : Etapa3Palette.amber;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chevron_right, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: Etapa3Palette.text,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NoDosimeter extends StatelessWidget {
  const _NoDosimeter({this.lastShift});

  final ExposureSession? lastShift;

  @override
  Widget build(BuildContext context) {
    final last = lastShift;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OperatorEmpty(
          icon: Icons.sensors_off_outlined,
          title: tr('op_noDosimeter'),
          subtitle: tr('op_noDosimeterHint'),
        ),
        if (last != null) ...[
          const SizedBox(height: 20),
          SectionLabel(tr('op_lastShift')),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${exposureDateTime(last.startedAt)} → ${exposureDateTime(last.endedAt)}',
                    style: const TextStyle(color: Etapa3Palette.muted, fontSize: 13),
                  ),
                ),
                StatusPill(
                  label: exposurePercent(last.percentage),
                  color: exposureColor(last.status),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
