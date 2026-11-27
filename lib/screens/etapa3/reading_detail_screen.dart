import 'package:flutter/material.dart';

import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/radiationmonitoring/domain/client_reading.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'home_presenters.dart';

/// Nivel 3: una lectura de un sensor fijo del hogar.
class HomeReadingDetailScreen extends StatelessWidget {
  const HomeReadingDetailScreen({super.key, required this.reading, this.device});

  final ClientReading reading;
  final ClientDevice? device;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final level = reading.effectiveLevel;
    final tone = emsTone(context, levelTone(level));
    final at = reading.takenAt;
    final d = device;
    final signal = d == null ? null : sensorSignal(d);

    return EmsPage(
      eyebrow: tr('m_readingDetail'),
      title: d?.name ?? reading.deviceName ?? tr('m_sensor'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsRailBox(
            color: c.surface,
            borderColor: c.border,
            railColor: tone.signal,
            radius: EmsRadius.md,
            padding: const EdgeInsets.all(EmsSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EmsTag(levelLabel(level), tone: levelTone(level), icon: levelIcon(level)),
                    const Spacer(),
                    if (at != null) Text(EmsFormat.time(at), style: context.type.mono),
                  ],
                ),
                const SizedBox(height: EmsSpace.s5),
                EmsHeroValue(value: EmsFormat.value(reading.value, decimals: 2), unit: 'µT', color: tone.fg),
                const SizedBox(height: EmsSpace.s6),
                HomeLevelScale(value: reading.value),
                const SizedBox(height: EmsSpace.s4),
                Text(tr('m_levelExplain_$level'), style: context.type.bodySm),
              ],
            ),
          ),
          const SizedBox(height: EmsSpace.s7),
          EmsGroup(
            title: tr('m_capture'),
            children: [
              EmsKeyValue(label: tr('m_date'), value: at == null ? '—' : EmsFormat.date(at)),
              EmsKeyValue(
                label: tr('m_captureTime'),
                value: at == null || !reading.hasExactTime ? '—' : EmsFormat.timeSec(at),
                mono: true,
              ),
              EmsKeyValue(label: tr('m_source'), value: d?.name ?? reading.deviceName ?? '—'),
              if (d?.location != null && d!.location!.isNotEmpty) EmsKeyValue(label: tr('m_location'), value: d.location!),
            ],
          ),
          if (d != null && signal != null) ...[
            const SizedBox(height: EmsSpace.s7),
            EmsGroup(
              title: tr('m_sensorState'),
              footer: tr('m_sensorStateNote'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s5, vertical: EmsSpace.s4),
                  child: Row(
                    children: [
                      Expanded(child: Text(tr('m_connectivity'), style: context.type.bodySm)),
                      EmsSignal(state: signal.$1, label: signal.$2),
                    ],
                  ),
                ),
                if (d.latestReadingDate != null) EmsKeyValue(label: tr('m_lastReadingDay'), value: d.latestReadingDate!, mono: true),
              ],
            ),
          ],
          const SizedBox(height: EmsSpace.s7),
          EmsExpandable(
            title: tr('m_technical'),
            icon: PhosphorIconsRegular.hash,
            child: Column(
              children: [
                EmsKeyValue(label: tr('m_readingId'), value: '#${reading.id}', mono: true),
                if (reading.deviceId != null) EmsKeyValue(label: tr('m_deviceId'), value: '#${reading.deviceId}', mono: true),
                if (d?.serialNumber != null) EmsKeyValue(label: tr('m_serial'), value: d!.serialNumber!, mono: true),
                if (reading.recordedAt != null) EmsKeyValue(label: 'recordedAt', value: reading.recordedAt!, mono: true),
                EmsKeyValue(
                  label: tr('m_levelSource'),
                  value: reading.level != null ? tr('m_levelFromEdge') : tr('m_levelFromValue'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(EmsSpace.s5, 0, EmsSpace.s5, EmsSpace.s4),
                  child: Text(tr('m_noReceivedAtHome'), style: context.type.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

