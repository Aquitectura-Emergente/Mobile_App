import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../contexts/personaldosimetry/domain/personal_reading.dart';
import '../../contexts/radiationmonitoring/domain/reading_series.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/reading_history_screen.dart';

/// Puntos de la serie del dosímetro (campo instantáneo en µT). Las lecturas
/// sincronizadas tarde quedan marcadas.
List<SeriesPoint> operatorPoints(Iterable<PersonalReading> readings) => [
      for (final r in readings)
        if (r.takenAt != null) SeriesPoint(at: r.takenAt!, value: r.fieldMicrotesla, flagged: r.isLate, source: r),
    ];

/// Abre el histórico completo de las lecturas de una jornada.
void openShiftHistory(BuildContext context, ExposureSession? session, List<PersonalReading> readings, {String? title}) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ReadingHistoryScreen(
      title: title ?? tr('op_readingsTitle'),
      eyebrow: tr('m_dosimeterReadings'),
      points: operatorPoints(readings),
      byLevel: false,
      flaggedLabel: tr('op_late'),
      note: tr('m_dosimeterNote'),
      onOpen: (ctx, p) => Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => OperatorReadingDetailScreen(reading: p.source! as PersonalReading, session: session),
      )),
    ),
  ));
}

/// Nivel 3: una lectura del dosímetro personal, con captura y recepción por
/// separado (una lectura sin cobertura llega más tarde de lo que se midió).
class OperatorReadingDetailScreen extends StatelessWidget {
  const OperatorReadingDetailScreen({super.key, required this.reading, this.session});

  final PersonalReading reading;
  final ExposureSession? session;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final from = reading.capturedStart;
    final to = reading.capturedEnd;
    final rec = reading.received;
    final delay = reading.deliveryDelay;
    final late = reading.isLate;
    return EmsPage(
      eyebrow: tr('m_readingDetail'),
      title: tr('m_dosimeterReading'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsRailBox(
            color: c.surface,
            borderColor: c.border,
            railColor: late ? c.warningSignal : c.primary,
            radius: EmsRadius.md,
            padding: const EdgeInsets.all(EmsSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    late
                        ? EmsTag(tr('op_late'), tone: EmsTone.warning, icon: PhosphorIconsRegular.cloudArrowUp)
                        : EmsTag(tr('m_accepted'), tone: EmsTone.safe, icon: PhosphorIconsRegular.cloudCheck),
                    const Spacer(),
                    if (from != null) Text(EmsFormat.time(from), style: context.type.mono),
                  ],
                ),
                const SizedBox(height: EmsSpace.s5),
                EmsHeroValue(label: tr('m_instantField'), value: EmsFormat.value(reading.fieldMicrotesla, decimals: 2), unit: 'µT'),
                const SizedBox(height: EmsSpace.s4),
                Text(tr('m_instantFieldNote'), style: context.type.bodySm),
              ],
            ),
          ),
          if (late) ...[
            const SizedBox(height: EmsSpace.s5),
            EmsBanner(tone: EmsTone.warning, icon: PhosphorIconsRegular.cloudArrowUp, title: tr('m_lateTitle'), message: tr('m_lateMsg')),
          ],
          const SizedBox(height: EmsSpace.s7),
          EmsGroup(
            title: tr('m_capture'),
            children: [
              EmsKeyValue(label: tr('m_date'), value: from == null ? '—' : EmsFormat.date(from)),
              EmsKeyValue(label: tr('m_captureFrom'), value: from == null ? '—' : EmsFormat.timeSec(from), mono: true),
              EmsKeyValue(label: tr('m_captureTo'), value: to == null ? '—' : EmsFormat.timeSec(to), mono: true),
              if (from != null && to != null) EmsKeyValue(label: tr('m_captureSpan'), value: EmsFormat.duration(to.difference(from)), mono: true),
            ],
          ),
          const SizedBox(height: EmsSpace.s7),
          EmsGroup(
            title: tr('m_sync'),
            footer: tr('m_syncNote'),
            children: [
              EmsKeyValue(
                label: tr('m_receivedAt'),
                value: rec == null ? '—' : (from != null && rec.day != from.day ? EmsFormat.dateTime(rec) : EmsFormat.timeSec(rec)),
                mono: true,
              ),
              EmsKeyValue(
                label: tr('m_delay'),
                value: delay == null ? '—' : EmsFormat.duration(delay),
                mono: true,
                valueColor: late ? c.warning : null,
              ),
              EmsKeyValue(label: tr('m_ingestState'), value: late ? tr('m_ingestLate') : tr('m_ingestAccepted')),
            ],
          ),
          if (session != null) ...[
            const SizedBox(height: EmsSpace.s7),
            EmsGroup(
              title: tr('m_shift'),
              children: [
                EmsKeyValue(label: tr('op_started'), value: _when(session!.startedAt), mono: true),
                EmsKeyValue(label: tr('m_shiftState'), value: tr(session!.isOpen ? 'm_shiftOpen' : (session!.isClosed ? 'm_shiftClosed' : 'm_shiftClosing'))),
              ],
            ),
          ],
          const SizedBox(height: EmsSpace.s7),
          EmsExpandable(
            title: tr('m_technical'),
            icon: PhosphorIconsRegular.hash,
            child: Column(
              children: [
                EmsKeyValue(label: tr('m_readingId'), value: reading.id, mono: true),
                if (reading.sequence != null) EmsKeyValue(label: tr('m_sequence'), value: '#${reading.sequence}', mono: true),
                if (reading.deviceId != null) EmsKeyValue(label: tr('m_dosimeterId'), value: '#${reading.deviceId}', mono: true),
                if (reading.bootId != null) EmsKeyValue(label: 'bootId', value: reading.bootId!, mono: true),
                if (reading.sessionId != null) EmsKeyValue(label: tr('m_shiftId'), value: reading.sessionId!, mono: true),
                EmsKeyValue(label: tr('m_unit'), value: reading.unit ?? 'uT', mono: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _when(String? iso) {
  final t = DateTime.tryParse(iso ?? '')?.toLocal();
  return t == null ? '—' : EmsFormat.dateTime(t);
}
