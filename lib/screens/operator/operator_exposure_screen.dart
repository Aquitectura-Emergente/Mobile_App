import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../contexts/personaldosimetry/domain/personal_reading.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';

/// Jornada y sus lecturas más recientes (de la más antigua a la más reciente).
class _ExposureData {
  const _ExposureData(this.session, this.readings);

  final ExposureSession? session;
  final List<PersonalReading> readings;
}

/// Exposición acumulada de la jornada frente al límite del puesto.
class OperatorExposureScreen extends StatefulWidget {
  const OperatorExposureScreen({super.key});

  @override
  State<OperatorExposureScreen> createState() => _OperatorExposureScreenState();
}

class _OperatorExposureScreenState extends State<OperatorExposureScreen>
    with WidgetsBindingObserver {
  // Sin canal en vivo para el operario: se consulta cada cierto tiempo.
  // Cambiar (o quitar) cuando exista un WebSocket de dosimetría.
  static const _refreshEvery = Duration(seconds: 3);

  late Future<_ExposureData> _future = _fetch();
  Timer? _timer;
  bool _inFlight = false;
  _ExposureData? _last;
  bool _hasLast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
      _startPolling();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshEvery, (_) {
      // Con otra pantalla encima no se consulta.
      if (ModalRoute.of(context)?.isCurrent ?? true) _reload();
    });
  }

  /// Consulta la jornada marcando la petición en curso, para no solapar
  /// consultas si el backend tarda más que el intervalo.
  Future<_ExposureData> _fetch() {
    _inFlight = true;
    final future = _load();
    future.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
      _inFlight = false;
    });
    return future;
  }

  Future<_ExposureData> _load() async {
    final session = await DosimetryFacade.currentShift();
    if (session == null || session.isClosed) return _ExposureData(session, const []);
    return _ExposureData(
        session, await DosimetryFacade.latestShiftReadings(session.id));
  }

  void _reload() {
    if (!mounted || _inFlight) return;
    final future = _fetch();
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
      child: FutureBuilder<_ExposureData>(
        future: _future,
        builder: (context, snap) {
          // Se guarda la última respuesta buena: si una consulta periódica
          // falla, se siguen mostrando esos datos con un aviso discreto.
          if (snap.connectionState == ConnectionState.done && !snap.hasError) {
            _last = snap.data;
            _hasLast = true;
          }
          if (!_hasLast) {
            // Primera carga: indicador mientras espera, error completo si falla.
            if (snap.connectionState != ConnectionState.done) {
              return const Etapa3Loading();
            }
            return Etapa3Error(message: snap.error.toString(), onRetry: _reload);
          }
          final session = _last!.session;
          final content = session == null || session.isClosed
              ? _NoDosimeter(lastShift: session)
              : _ShiftView(session: session, readings: _last!.readings);
          if (!snap.hasError) return content;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  label: tr('op_offlineRetrying'),
                  color: Etapa3Palette.amber,
                  icon: Icons.cloud_off_outlined,
                ),
              ),
              const SizedBox(height: 12),
              content,
            ],
          );
        },
      ),
    );
  }
}

class _ShiftView extends StatelessWidget {
  const _ShiftView({required this.session, required this.readings});

  final ExposureSession session;
  final List<PersonalReading> readings;

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
              caption: exposureUnit(session.unit),
              accent: color,
            ),
            MetricTile(
              icon: Icons.flag_outlined,
              label: tr('op_limit'),
              value: exposureIndex(session.limitIndex),
              caption: exposureUnit(session.unit),
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
              caption: exposureUnit(session.unit),
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
        const SizedBox(height: 20),
        SectionLabel(tr('op_liveReading')),
        const SizedBox(height: 10),
        _LiveReading(readings: readings),
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

/// Última medición del dosímetro y su tendencia, con los componentes del
/// monitor del hogar. Las lecturas personales no traen nivel: color neutro.
class _LiveReading extends StatelessWidget {
  const _LiveReading({required this.readings});

  /// Pasado este tiempo sin lecturas nuevas, deja de mostrarse "en línea".
  static const _staleAfter = Duration(seconds: 10);

  final List<PersonalReading> readings;

  @override
  Widget build(BuildContext context) {
    final latest = readings.isEmpty ? null : readings.last;
    final at = etapa3ParseTime(latest?.capturedTo ?? latest?.capturedFrom);
    final recent =
        at != null && DateTime.now().difference(at) <= _staleAfter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiveReadingHero(
          value: latest?.fieldMicrotesla,
          color: Etapa3Palette.cyan,
          statusLabel: latest == null
              ? tr('mon_noData')
              : (recent ? tr('mon_online') : tr('op_noRecentData')),
          statusColor: recent ? Etapa3Palette.green : Etapa3Palette.amber,
          updatedText: latest == null
              ? tr('mon_noData')
              : '${tr('mon_updated')} ${etapa3TimeOfDay(latest.capturedTo ?? latest.capturedFrom)}',
        ),
        const SizedBox(height: 16),
        TrendCard(
          points: [
            for (final r in readings.reversed)
              TrendPoint(r.fieldMicrotesla, Etapa3Palette.cyan),
          ],
        ),
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
