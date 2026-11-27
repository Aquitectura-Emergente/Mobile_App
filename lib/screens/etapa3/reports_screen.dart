import 'package:flutter/material.dart';

import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../contexts/radiationmonitoring/domain/client_report.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'home_presenters.dart';

/// Informes agregados del hogar (mes: últimos 30 días; año: 12 meses).
/// Cada tramo trae promedio y pico ya calculados por el backend.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = ReportPeriod.month;
  late Future<ClientReport> _future = MonitoringFacade.report(_period);
  int? _selected;

  void _setPeriod(String period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _selected = null;
      _future = MonitoringFacade.report(period);
    });
  }

  Future<void> _reload() async {
    final future = MonitoringFacade.report(_period);
    setState(() { _future = future; });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return EmsPage(
      eyebrow: tr('m_reportsEyebrow'),
      title: tr('rep_title'),
      onRefresh: _reload,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsSegmented<String>(
            value: _period,
            segments: [(ReportPeriod.month, tr('rep_month')), (ReportPeriod.year, tr('rep_year'))],
            onChanged: _setPeriod,
          ),
          const SizedBox(height: EmsSpace.s5),
          FutureBuilder<ClientReport>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const EmsLoadingBlock(lines: 2);
              if (snapshot.hasError) {
                final msg = snapshot.error is ApiException ? (snapshot.error as ApiException).message : tr('rep_errLoad');
                return EmsPanel(
                  child: EmsEmptyState(
                    kind: EmsEmptyKind.offline,
                    title: msg,
                    action: EmsButton(label: tr('common_retry'), kind: EmsButtonKind.secondary, expand: false, onPressed: _reload),
                  ),
                );
              }
              return _content(context, snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ClientReport report) {
    final c = context.ems;
    if (report.isEmpty) {
      return EmsPanel(padding: EdgeInsets.zero, child: EmsEmptyState(icon: PhosphorIconsRegular.chartBar, title: tr('rep_empty')));
    }
    final buckets = report.buckets;
    final sel = _selected != null && _selected! < buckets.length ? buckets[_selected!] : null;
    final step = (buckets.length / 4).ceil().clamp(1, buckets.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmsPanel(
          padding: const EdgeInsets.all(EmsSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text((sel == null ? tr('m_periodPeak') : sel.label).toUpperCase(), style: context.type.eyebrow),
              const SizedBox(height: EmsSpace.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    sel == null
                        ? EmsFormat.value(report.peak)
                        : (sel.readings == 0 ? '—' : '${EmsFormat.value(sel.average)} → ${EmsFormat.value(sel.peak)}'),
                    style: context.type.metricLg.copyWith(color: emsTone(context, levelTone(sel?.peakLevel ?? report.peakLevel)).fg),
                  ),
                  const SizedBox(width: EmsSpace.s2),
                  Text('µT', style: context.type.mono.copyWith(color: c.textTertiary)),
                ],
              ),
              Text(
                sel == null
                    ? tr(_period == ReportPeriod.month ? 'm_last30d' : 'm_last12m')
                    : (sel.readings == 0 ? tr('m_noReadings') : '${tr('rep_avg')} → ${tr('rep_peak')} · ${sel.readings} ${tr('m_readings')} · ${sel.alerts} ${tr('m_alertsLc')}'),
                style: context.type.caption,
              ),
              const SizedBox(height: EmsSpace.s5),
              EmsRangeChart(
                bars: [
                  for (final b in buckets)
                    b.readings == 0
                        ? const EmsRangeBar()
                        : EmsRangeBar(low: b.average, high: b.peak, color: levelSignal(context, b.peakLevel)),
                ],
                guides: homeGuides(context),
                selected: _selected,
                onSelect: (i) => setState(() => _selected = i == _selected ? null : i),
                xLabels: {for (var i = 0; i < buckets.length; i += step) i: buckets[i].label},
                yUnit: 'µT',
                semanticSummary: '${tr('rep_peak')} ${EmsFormat.value(report.peak)} µT',
              ),
              const SizedBox(height: EmsSpace.s3),
              EmsChartLegend(items: [
                (c.primary, tr('m_barAvgPeak'), false),
                (c.textDisabled, tr('m_noReadings'), true),
              ]),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s4),
        Container(
          decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cell(tr('rep_avg'), EmsFormat.value(report.average), 'µT'),
                VerticalDivider(width: 1, color: c.borderSubtle),
                _Cell(tr('rep_readings'), '${report.totalReadings}', null),
                VerticalDivider(width: 1, color: c.borderSubtle),
                _Cell(tr('rep_alerts'), '${report.totalAlerts}', null),
              ],
            ),
          ),
        ),
        const SizedBox(height: EmsSpace.s7),
        EmsGroup(
          footer: tr('m_avgPeakFooter'),
          title: tr('rep_detail'),
          children: [
            for (var i = buckets.length - 1; i >= 0; i--)
              EmsRow(
                rail: buckets[i].readings == 0 ? null : levelSignal(context, buckets[i].peakLevel),
                title: buckets[i].label,
                subtitle: buckets[i].readings == 0
                    ? tr('m_noReadings')
                    : '${buckets[i].readings} ${tr('m_readings')} · ${buckets[i].alerts} ${tr('m_alertsLc')}',
                value: buckets[i].readings == 0 ? null : '${EmsFormat.value(buckets[i].average)} / ${EmsFormat.value(buckets[i].peak)}',
                mono: true,
                onTap: () => setState(() => _selected = i),
              ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, this.unit);
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(EmsSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: context.type.eyebrow.copyWith(fontSize: 10)),
              const SizedBox(height: EmsSpace.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: context.type.metricMd),
                  if (unit != null) ...[const SizedBox(width: 3), Text(unit!, style: context.type.monoSm)],
                ],
              ),
            ],
          ),
        ),
      );
}
