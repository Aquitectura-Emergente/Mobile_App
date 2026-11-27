import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/devicemanagement/infrastructure/notification_service.dart';
import '../../contexts/devicemanagement/infrastructure/realtime_service.dart';
import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../contexts/personaldosimetry/domain/personal_reading.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'operator_components.dart';
import 'operator_reading_detail_screen.dart';
import 'operator_session_screen.dart';
import '../../design_system/design_system.dart';

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
    // Las alertas del operario llegan en vivo y se muestran como notificación.
    NotificationService.init();
    RealtimeService.ensureConnected();
    RealtimeService.workerAlertTick.addListener(_reload);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RealtimeService.workerAlertTick.removeListener(_reload);
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
      trailing: EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload),
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
                child: EmsSignal(
                  state: EmsSignalState.stale,
                  label: tr('op_offlineRetrying'),
                ),
              ),
              const SizedBox(height: EmsSpace.s4),
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
    final c = context.ems;
    final points = operatorPoints(readings);
    final first = points.isEmpty ? null : points.map((p) => p.at).reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();
    final normal = status == ExposureStatus.normal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Estado evidente: color + icono + texto
        ExposureStatusBand(status: status),
        const SizedBox(height: EmsSpace.s5),

        // 2. Dosis acumulada: % del límite y barra consumido / margen
        EmsPanel(
          padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s5, EmsSpace.s6, EmsSpace.s6),
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(tr('m_accumulatedDose').toUpperCase(), style: context.type.eyebrow)),
              const SizedBox(height: EmsSpace.s3),
              ExposureGauge(session: session),
              if (!session.isOpen) ...[
                const SizedBox(height: EmsSpace.s3),
                EmsTag(tr('op_shiftClosing'), tone: EmsTone.info, icon: PhosphorIconsRegular.hourglassMedium),
              ],
              const SizedBox(height: EmsSpace.s6),
              EmsSectionHeader(
                title: tr('op_doseBar'),
                trailing: Text(
                  '${exposureIndex(session.accumulatedIndex)} / ${exposureIndex(session.limitIndex)} ${exposureUnit(session.unit)}',
                  style: context.type.monoSm.copyWith(color: c.textSecondary),
                ),
              ),
              EmsDoseBar(
                fraction: session.progress,
                warnAt: null,
                tone: switch (status) {
                  ExposureStatus.normal => EmsTone.safe,
                  ExposureStatus.warning => EmsTone.warning,
                  ExposureStatus.exceeded => EmsTone.danger,
                },
              ),
              const SizedBox(height: EmsSpace.s5),
              Row(
                children: [
                  _Readout(tr('op_accumulated'), exposureIndex(session.accumulatedIndex)),
                  _Readout(tr('op_limit'), exposureIndex(session.limitIndex)),
                  _Readout(tr('op_remaining'), exposureIndex(session.remainingIndex)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s5),

        // 3. Dosímetro: lectura instantánea y comunicación
        _LiveReading(readings: readings),
        if (!normal) ...[
          const SizedBox(height: EmsSpace.s7),
          EmsSectionHeader(index: '01', title: tr('op_recommendations')),
          _Recommendations(exceeded: status == ExposureStatus.exceeded),
        ],
        const SizedBox(height: EmsSpace.s7),

        // 4. Campo instantáneo de la jornada (no es dosis)
        EmsSectionHeader(index: normal ? '01' : '02', title: tr('m_fieldThisShift')),
        if (points.isEmpty)
          EmsPanel(padding: EdgeInsets.zero, child: EmsEmptyState(icon: PhosphorIconsRegular.chartBar, title: tr('op_noReadings')))
        else
          MeasurementOverview(
            points: points,
            byLevel: false,
            flaggedLabel: tr('op_late'),
            interval: first != null && now.isAfter(first) ? (first, now) : null,
            onShowAll: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorSessionScreen(session: session))),
          ),
        const SizedBox(height: EmsSpace.s7),
        EmsSectionHeader(index: normal ? '02' : '03', title: tr('m_shiftInfo')),
        EmsGroup(
          children: [
            EmsKeyValue(label: tr('op_started'), value: etapa3TimeOfDay(session.startedAt), mono: true),
            EmsKeyValue(
              label: tr('op_coverage'),
              value: session.coveragePercentage == null ? '—' : exposurePercent(session.coveragePercentage!),
              note: session.coverageComplete ? tr('m_coverageComplete') : tr('m_coveragePartial'),
              mono: true,
            ),
            EmsKeyValue(
              label: tr('m_outOfRange'),
              value: '${session.outOfRangeReadings}',
              mono: true,
              valueColor: session.outOfRangeReadings > 0 ? c.warning : null,
            ),
            EmsRow(
              icon: PhosphorIconsRegular.listBullets,
              title: tr('m_shiftDetail'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorSessionScreen(session: session))),
            ),
          ],
        ),
        const SizedBox(height: EmsSpace.s7),
        Text(tr('ds_notMetrology'), textAlign: TextAlign.center, style: context.type.caption),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10)),
            const SizedBox(height: EmsSpace.s2),
            Text(value, style: context.type.metricMd.copyWith(fontSize: 18)),
          ],
        ),
      );
}

/// Dosímetro: última lectura instantánea, si llega en vivo y cuándo se
/// sincronizó. Las lecturas personales no traen nivel: color neutro.
class _LiveReading extends StatelessWidget {
  const _LiveReading({required this.readings});

  /// Pasado este tiempo sin lecturas nuevas, deja de mostrarse "en línea".
  static const _staleAfter = Duration(seconds: 10);

  final List<PersonalReading> readings;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final latest = readings.isEmpty ? null : readings.last;
    final at = latest?.capturedEnd ?? latest?.capturedStart;
    final recent = at != null && DateTime.now().difference(at) <= _staleAfter;
    final lateCount = readings.where((r) => r.isLate).length;
    final received = latest?.received;
    return EmsPanel(
      padding: const EdgeInsets.all(EmsSpace.s5),
      onTap: latest == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorReadingDetailScreen(reading: latest))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(tr('m_dosimeter').toUpperCase(), style: context.type.eyebrow),
              const Spacer(),
              EmsSignal(
                state: latest == null ? EmsSignalState.offline : (recent ? EmsSignalState.live : EmsSignalState.stale),
                label: latest == null ? tr('mon_noData') : (recent ? tr('ds_live') : tr('ds_stale')),
              ),
            ],
          ),
          const SizedBox(height: EmsSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: EmsHeroValue(
                  label: tr('m_instantField'),
                  value: EmsFormat.value(latest?.fieldMicrotesla, decimals: 2),
                  unit: 'µT',
                  size: 40,
                  color: recent ? c.text : c.textSecondary,
                ),
              ),
              if (latest != null) Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.textTertiary),
            ],
          ),
          const SizedBox(height: EmsSpace.s3),
          Text(
            latest == null
                ? tr('m_noDosimeterData')
                : '${tr('m_capturedAt')} ${at == null ? '—' : EmsFormat.timeSec(at)}'
                    '${received == null ? '' : ' · ${tr('m_receivedShort')} ${EmsFormat.timeSec(received)}'}',
            style: context.type.monoSm,
          ),
          if (lateCount > 0) ...[
            const SizedBox(height: EmsSpace.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: EmsTag('$lateCount ${tr('m_lateCount')}', tone: EmsTone.warning, icon: PhosphorIconsRegular.cloudArrowUp),
            ),
          ],
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
    final t = emsTone(context, exceeded ? EmsTone.danger : EmsTone.warning);
    return EmsPanel(
      padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s5, vertical: EmsSpace.s3),
      railColor: t.signal,
      child: Column(
        children: [
          for (var i = 0; i < tips.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: EmsSpace.s4),
              decoration: BoxDecoration(
                border: i == tips.length - 1 ? null : Border(bottom: BorderSide(color: context.ems.borderSubtle)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((i + 1).toString().padLeft(2, '0'), style: context.type.monoSm.copyWith(color: t.fg)),
                  const SizedBox(width: EmsSpace.s4),
                  Expanded(child: Text(tips[i], style: context.type.body)),
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
          icon: PhosphorIconsRegular.cellSignalSlash,
          title: tr('op_noDosimeter'),
          subtitle: tr('op_noDosimeterHint'),
        ),
        if (last != null) ...[
          const SizedBox(height: EmsSpace.s7),
          EmsSectionHeader(title: tr('op_lastShift')),
          EmsPanel(
            padding: const EdgeInsets.all(EmsSpace.s5),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorSessionScreen(session: last))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${exposureDateTime(last.startedAt)} → ${exposureDateTime(last.endedAt)}',
                    style: context.type.mono,
                  ),
                ),
                EmsTag(exposurePercent(last.percentage), tone: exposureTone(last.status)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
