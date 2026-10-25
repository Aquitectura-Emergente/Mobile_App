import 'package:flutter/material.dart';

import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../contexts/radiationmonitoring/domain/client_report.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'etapa3_components.dart';
import 'subpage_scaffold.dart';

/// Monthly / yearly radiation reports with trend chart (US19, US20, US22).
/// Backed by GET /api/client/reports?period=month|year.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'month';
  late Future<ClientReport> _future;

  @override
  void initState() {
    super.initState();
    _future = MonitoringFacade.report(_period);
  }

  void _setPeriod(String period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _future = MonitoringFacade.report(period);
    });
  }

  void _reload() {
    setState(() => _future = MonitoringFacade.report(_period));
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: tr('rep_title'),
      subtitle: tr('rep_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PeriodChip(
                label: tr('rep_month'),
                selected: _period == 'month',
                onTap: () => _setPeriod('month'),
              ),
              const SizedBox(width: 10),
              _PeriodChip(
                label: tr('rep_year'),
                selected: _period == 'year',
                onTap: () => _setPeriod('year'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<ClientReport>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Etapa3Loading();
              }
              if (snapshot.hasError) {
                final msg = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : tr('rep_errLoad');
                return Etapa3Error(message: msg, onRetry: _reload);
              }
              return _buildReport(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReport(ClientReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return GridView.count(
              crossAxisCount: compact ? 1 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: compact ? 2.35 : 1.34,
              children: [
                MetricTile(
                  icon: Icons.show_chart,
                  label: tr('rep_avg'),
                  value: etapa3Num(report.average, decimals: 1),
                  caption: etapa3Unit,
                  accent: Etapa3Palette.blue,
                ),
                MetricTile(
                  icon: Icons.trending_up,
                  label: tr('rep_peak'),
                  value: etapa3Num(report.peak, decimals: 1),
                  caption: etapa3Unit,
                  accent: etapa3LevelColor(
                      report.peak >= 200 ? 'danger'
                          : report.peak >= 100 ? 'caution' : 'safe'),
                ),
                MetricTile(
                  icon: Icons.dataset_outlined,
                  label: tr('rep_readings'),
                  value: report.totalReadings.toString(),
                  caption: '',
                  accent: Etapa3Palette.cyan,
                ),
                MetricTile(
                  icon: Icons.notifications_active_outlined,
                  label: tr('rep_alerts'),
                  value: report.totalAlerts.toString().padLeft(2, '0'),
                  caption: '',
                  accent: report.totalAlerts > 0
                      ? Etapa3Palette.amber
                      : Etapa3Palette.green,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('rep_trend')),
        const SizedBox(height: 10),
        _TrendChart(buckets: report.buckets),
        const SizedBox(height: 20),
        SectionLabel(tr('rep_detail')),
        const SizedBox(height: 10),
        if (report.buckets.isEmpty)
          GlassPanel(
            child: Text(
              tr('rep_empty'),
              style:
                  const TextStyle(color: Etapa3Palette.muted, fontSize: 13),
            ),
          )
        else
          for (final bucket in report.buckets.reversed) ...[
            _BucketRow(bucket: bucket),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Etapa3Palette.cyan.withValues(alpha: 0.14)
              : Etapa3Palette.panelSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Etapa3Palette.cyan.withValues(alpha: 0.5)
                : Etapa3Palette.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Etapa3Palette.cyan : Etapa3Palette.muted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Bar chart of bucket averages, colored by level (µT thresholds 100/200).
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.buckets});

  final List<ClientReportBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.isEmpty
        ? 1.0
        : buckets.map((b) => b.peak).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: buckets.isEmpty
                ? Center(
                    child: Text(
                      tr('rep_empty'),
                      style: const TextStyle(
                          color: Etapa3Palette.quiet, fontSize: 12),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final b in buckets) ...[
                        Expanded(
                          child: Tooltip(
                            message:
                                '${b.label}\n${etapa3Num(b.average, decimals: 1)} $etapa3Unit',
                            child: FractionallySizedBox(
                              heightFactor:
                                  (b.average / safeMax).clamp(0.04, 1.0),
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: etapa3LevelColor(
                                    b.average >= 200 ? 'danger'
                                        : b.average >= 100 ? 'caution' : 'safe',
                                  ).withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ],
                  ),
          ),
          if (buckets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  buckets.first.label,
                  style: const TextStyle(
                      color: Etapa3Palette.quiet, fontSize: 11),
                ),
                Text(
                  buckets.last.label,
                  style: const TextStyle(
                      color: Etapa3Palette.quiet, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({required this.bucket});

  final ClientReportBucket bucket;

  @override
  Widget build(BuildContext context) {
    final level = bucket.average >= 200
        ? 'danger'
        : bucket.average >= 100
            ? 'caution'
            : 'safe';
    final color = etapa3LevelColor(level);
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bucket.label,
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tr('rep_avg')}: ${etapa3Num(bucket.average, decimals: 1)} $etapa3Unit'
                  '  ·  ${tr('rep_peak')}: ${etapa3Num(bucket.peak, decimals: 1)} $etapa3Unit'
                  '  ·  ${bucket.readings} ${tr('rep_readings').toLowerCase()}',
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (bucket.alerts > 0) ...[
            const SizedBox(width: 8),
            StatusPill(
              label: '${bucket.alerts} ⚠',
              color: Etapa3Palette.amber,
            ),
          ],
        ],
      ),
    );
  }
}
