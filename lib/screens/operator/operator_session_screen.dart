import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../contexts/personaldosimetry/domain/personal_reading.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'operator_components.dart';
import 'operator_reading_detail_screen.dart';

/// Lecturas de una jornada: gráfico compacto del campo instantáneo, últimas
/// lecturas y acceso al histórico completo. No mezcla la dosis acumulada.
class ShiftReadingsSection extends StatelessWidget {
  const ShiftReadingsSection({super.key, required this.session, required this.readings, this.recent = 6});

  final ExposureSession session;
  final List<PersonalReading> readings;
  final int recent;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    if (readings.isEmpty) {
      return EmsPanel(padding: EdgeInsets.zero, child: EmsEmptyState(icon: PhosphorIconsRegular.chartBar, title: tr('op_noReadings')));
    }
    final start = DateTime.tryParse(session.startedAt ?? '')?.toLocal();
    final end = DateTime.tryParse(session.endedAt ?? '')?.toLocal() ?? DateTime.now();
    final points = operatorPoints(readings);
    final latest = [...readings]..sort((a, b) => (b.takenAt ?? DateTime(0)).compareTo(a.takenAt ?? DateTime(0)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeasurementOverview(
          title: tr('m_instantField'),
          points: points,
          byLevel: false,
          flaggedLabel: tr('op_late'),
          interval: start == null || !end.isAfter(start) ? null : (start, end),
          onShowAll: () => openShiftHistory(context, session, readings),
        ),
        const SizedBox(height: EmsSpace.s5),
        EmsGroup(
          title: tr('m_recentReadings'),
          children: [
            for (final r in latest.take(recent))
              EmsRow(
                rail: r.isLate ? c.warningSignal : c.primary,
                title: '${EmsFormat.value(r.fieldMicrotesla, decimals: 2)} µT',
                subtitle: r.takenAt == null ? '—' : '${EmsFormat.dayTitle(r.takenAt!)} · ${EmsFormat.timeSec(r.takenAt!)}',
                trailing: r.isLate ? EmsTag(tr('op_late'), tone: EmsTone.warning) : null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorReadingDetailScreen(reading: r, session: session))),
              ),
          ],
        ),
      ],
    );
  }
}

/// Detalle de una jornada (actual o pasada).
class OperatorSessionScreen extends StatefulWidget {
  const OperatorSessionScreen({super.key, required this.session});

  final ExposureSession session;

  @override
  State<OperatorSessionScreen> createState() => _OperatorSessionScreenState();
}

class _OperatorSessionScreenState extends State<OperatorSessionScreen> {
  late Future<List<PersonalReading>> _readings = DosimetryFacade.allShiftReadings(widget.session.id);

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final start = DateTime.tryParse(s.startedAt ?? '')?.toLocal();
    return EmsPage(
      eyebrow: tr('m_shift'),
      title: start == null ? tr('m_shift') : EmsFormat.dayTitle(start),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShiftSummaryCard(session: s),
          const SizedBox(height: EmsSpace.s7),
          ShiftInfoGroup(session: s),
          const SizedBox(height: EmsSpace.s8),
          EmsSectionHeader(index: '01', title: tr('m_dosimeterReadings')),
          FutureBuilder<List<PersonalReading>>(
            future: _readings,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const EmsSkeleton(height: 220, radius: EmsRadius.md);
              if (snap.hasError) {
                return EmsPanel(
                  child: EmsEmptyState(
                    kind: EmsEmptyKind.offline,
                    title: snap.error is ApiException ? (snap.error as ApiException).message : tr('m_readingsErr'),
                    action: EmsButton(
                      label: tr('common_retry'),
                      kind: EmsButtonKind.secondary,
                      expand: false,
                      onPressed: () => setState(() => _readings = DosimetryFacade.allShiftReadings(s.id)),
                    ),
                  ),
                );
              }
              return ShiftReadingsSection(session: s, readings: snap.data!);
            },
          ),
          const SizedBox(height: EmsSpace.s7),
          Text(tr('ds_notMetrology'), textAlign: TextAlign.center, style: context.type.caption),
        ],
      ),
    );
  }
}

/// Resumen de dosis: estado, porcentaje del límite y barra consumido / margen.
class ShiftSummaryCard extends StatelessWidget {
  const ShiftSummaryCard({super.key, required this.session});

  final ExposureSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final status = session.status;
    final tone = exposureTone(status);
    final t = emsTone(context, status == ExposureStatus.exceeded ? EmsTone.danger : tone);
    return EmsRailBox(
      color: c.surface,
      borderColor: c.border,
      railColor: t.signal,
      radius: EmsRadius.md,
      padding: const EdgeInsets.all(EmsSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EmsTag(exposureLabel(status), tone: tone),
              const Spacer(),
              EmsTag(tr(session.isOpen ? 'm_shiftOpen' : (session.isClosed ? 'm_shiftClosed' : 'm_shiftClosing')), tone: session.isOpen ? EmsTone.live : EmsTone.neutral),
            ],
          ),
          const SizedBox(height: EmsSpace.s5),
          EmsHeroValue(label: tr('m_doseOfLimit'), value: '${session.percentage.round()}', unit: '%', color: t.fg),
          const SizedBox(height: EmsSpace.s5),
          EmsDoseBar(fraction: session.progress, warnAt: null, tone: status == ExposureStatus.exceeded ? EmsTone.danger : tone),
          const SizedBox(height: EmsSpace.s5),
          Row(
            children: [
              _Cell(tr('op_accumulated'), exposureIndex(session.accumulatedIndex)),
              _Cell(tr('op_limit'), exposureIndex(session.limitIndex)),
              _Cell(tr('op_remaining'), exposureIndex(session.remainingIndex)),
            ],
          ),
          const SizedBox(height: EmsSpace.s3),
          Text('${tr('m_doseUnit')} ${exposureUnit(session.unit)}', style: context.type.caption),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value);
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

/// Información de la jornada tal como la entrega el backend.
class ShiftInfoGroup extends StatelessWidget {
  const ShiftInfoGroup({super.key, required this.session});

  final ExposureSession session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    String when(String? iso) {
      final t = DateTime.tryParse(iso ?? '')?.toLocal();
      return t == null ? '—' : EmsFormat.dateTime(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmsGroup(
          title: tr('m_shiftInfo'),
          children: [
            EmsKeyValue(label: tr('op_started'), value: when(s.startedAt), mono: true),
            EmsKeyValue(label: tr('m_ended'), value: s.endedAt == null ? tr('m_inProgress') : when(s.endedAt), mono: true),
            if (s.finalizedAt != null) EmsKeyValue(label: tr('m_finalized'), value: when(s.finalizedAt), mono: true),
            EmsKeyValue(
              label: tr('op_coverage'),
              value: s.coveragePercentage == null ? '—' : exposurePercent(s.coveragePercentage!),
              note: s.coverageComplete ? tr('m_coverageComplete') : tr('m_coveragePartial'),
              mono: true,
            ),
            EmsKeyValue(
              label: tr('m_outOfRange'),
              value: '${s.outOfRangeReadings}',
              mono: true,
              valueColor: s.outOfRangeReadings > 0 ? context.ems.warning : null,
            ),
          ],
        ),
        const SizedBox(height: EmsSpace.s4),
        EmsExpandable(
          title: tr('m_technical'),
          icon: PhosphorIconsRegular.hash,
          child: Column(
            children: [
              EmsKeyValue(label: tr('m_shiftId'), value: s.id, mono: true),
              if (s.deviceId != null) EmsKeyValue(label: tr('m_dosimeterId'), value: '#${s.deviceId}', mono: true),
              if (s.jobPositionId != null) EmsKeyValue(label: tr('m_jobPosition'), value: '#${s.jobPositionId}', mono: true),
              EmsKeyValue(label: tr('m_shiftState'), value: s.state, mono: true),
            ],
          ),
        ),
      ],
    );
  }
}
