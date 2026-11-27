import 'package:flutter/material.dart';

import '../../contexts/radiationmonitoring/domain/radiation_level.dart';
import '../../contexts/radiationmonitoring/domain/reading_series.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';

/// Tono de un nivel de radiación del backend.
EmsTone levelTone(String? level) => switch (level) {
      RadiationLevel.danger => EmsTone.danger,
      RadiationLevel.caution => EmsTone.warning,
      RadiationLevel.safe => EmsTone.safe,
      _ => EmsTone.neutral,
    };

String levelLabel(String? level) => switch (level) {
      RadiationLevel.danger => tr('m_lvDanger'),
      RadiationLevel.caution => tr('m_lvCaution'),
      RadiationLevel.safe => tr('m_lvSafe'),
      _ => tr('m_lvUnknown'),
    };

IconData levelIcon(String? level) => switch (level) {
      RadiationLevel.danger => PhosphorIconsRegular.warningOctagon,
      RadiationLevel.caution => PhosphorIconsRegular.warning,
      RadiationLevel.safe => PhosphorIconsRegular.checkCircle,
      _ => PhosphorIconsRegular.question,
    };

Color levelSignal(BuildContext context, String? level) => emsTone(context, levelTone(level)).signal;

/// Barras del gráfico a partir de tramos reales.
List<EmsRangeBar> barsFor(BuildContext context, List<SeriesBucket> buckets, {bool byLevel = true}) => [
      for (final b in buckets)
        b.isEmpty
            ? const EmsRangeBar()
            : EmsRangeBar(
                low: b.min,
                high: b.max,
                color: byLevel && b.worstLevel != null ? levelSignal(context, b.worstLevel) : null,
                hatched: b.hasFlagged,
              ),
    ];

/// Etiquetas del eje X: unas pocas, en el inicio de tramos legibles.
Map<int, String> axisLabels(List<SeriesBucket> buckets) {
  if (buckets.isEmpty) return const {};
  final span = buckets.first.span;
  final out = <int, String>{};
  final n = buckets.length;
  final step = (n / 4).ceil().clamp(1, n);
  for (var i = 0; i < n; i += step) {
    final t = buckets[i].start;
    out[i] = span >= const Duration(days: 1)
        ? EmsFormat.dayMonth(t)
        : span >= const Duration(hours: 6)
            ? EmsFormat.shortDay(t)
            : EmsFormat.time(t);
  }
  return out;
}

/// Nivel 1: gráfico compacto con resumen y acceso al histórico completo.
///
/// Muestra solo mediciones instantáneas (µT). Los tramos sin lecturas se
/// dibujan como huecos; tocar un tramo muestra su rango y su recuento.
class MeasurementOverview extends StatefulWidget {
  const MeasurementOverview({
    super.key,
    required this.points,
    this.unit = 'µT',
    this.byLevel = true,
    this.guides = const [],
    this.interval,
    this.onShowAll,
    this.title,
    this.flaggedLabel,
    this.initialRange = SeriesRange.day,
  });

  final List<SeriesPoint> points;
  final String unit;

  /// Colorear por nivel (sensores del hogar). El dosímetro no trae nivel.
  final bool byLevel;
  final List<EmsChartGuide> guides;

  /// Intervalo fijo (una jornada) en lugar de rangos seleccionables.
  final (DateTime, DateTime)? interval;
  final VoidCallback? onShowAll;
  final String? title;

  /// Leyenda de las barras rayadas, si las hay.
  final String? flaggedLabel;
  final SeriesRange initialRange;

  @override
  State<MeasurementOverview> createState() => _MeasurementOverviewState();
}

class _MeasurementOverviewState extends State<MeasurementOverview> {
  late SeriesRange _range = widget.initialRange;
  int? _selected;

  // Clave del encabezado: nueva en cada cambio, para que el AnimatedSwitcher
  // no repita la de un hijo que aún se está desvaneciendo.
  Object? _headlineId;
  int _headlineKey = 0;

  int _keyFor(Object id) {
    if (id != _headlineId) {
      _headlineId = id;
      _headlineKey++;
    }
    return _headlineKey;
  }

  String _rangeCaption() => switch (_range) {
        SeriesRange.day => tr('m_last24h'),
        SeriesRange.week => tr('m_last7d'),
        SeriesRange.month => tr('m_last30d'),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final interval = widget.interval;
    final buckets = interval != null
        ? ReadingSeries.forInterval(widget.points, interval.$1, interval.$2)
        : ReadingSeries.forRange(widget.points, _range);
    final inWindow = buckets.expand((b) => b.points).toList();
    final summary = SeriesSummary.of(inWindow);
    final latest = SeriesSummary.of(widget.points).latest;
    final sel = _selected != null && _selected! < buckets.length ? buckets[_selected!] : null;
    final emptyBuckets = buckets.where((b) => b.isEmpty).length;

    return EmsPanel(
      padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s5, EmsSpace.s5, EmsSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null) ...[
            Text(widget.title!.toUpperCase(), style: context.type.eyebrow),
            const SizedBox(height: EmsSpace.s4),
          ],
          if (interval == null) ...[
            EmsSegmented<SeriesRange>(
              dense: true,
              value: _range,
              segments: [
                (SeriesRange.day, tr('m_rangeDay')),
                (SeriesRange.week, tr('m_rangeWeek')),
                (SeriesRange.month, tr('m_rangeMonth')),
              ],
              onChanged: (r) => setState(() {
                _range = r;
                _selected = null;
              }),
            ),
            const SizedBox(height: EmsSpace.s5),
          ],
          // Lectura del encabezado: rango de la ventana o del tramo tocado.
          AnimatedSwitcher(
            duration: EmsDuration.fast,
            child: KeyedSubtree(
              key: ValueKey(_keyFor(sel?.start ?? _range)),
              child: sel == null
                  ? _Headline(
                      label: tr('m_range'),
                      value: summary.isEmpty ? '—' : '${EmsFormat.value(summary.min)}–${EmsFormat.value(summary.max)}',
                      unit: widget.unit,
                      caption: interval != null
                          ? '${EmsFormat.time(interval.$1)} – ${EmsFormat.time(interval.$2)}'
                          : _rangeCaption(),
                    )
                  : _Headline(
                      label: sel.isEmpty ? tr('m_noReadings') : tr('m_range'),
                      value: sel.isEmpty ? '—' : (sel.min == sel.max ? EmsFormat.value(sel.max) : '${EmsFormat.value(sel.min)}–${EmsFormat.value(sel.max)}'),
                      unit: sel.isEmpty ? '' : widget.unit,
                      caption: sel.span >= const Duration(days: 1)
                          ? EmsFormat.dayTitle(sel.start)
                          : '${EmsFormat.dayMonth(sel.start)} · ${EmsFormat.span(sel.start, sel.end)}'
                              '${sel.isEmpty ? '' : ' · ${sel.count} ${tr(sel.count == 1 ? 'm_reading' : 'm_readings')}'}',
                      tone: widget.byLevel && !sel.isEmpty ? levelTone(sel.worstLevel) : null,
                    ),
            ),
          ),
          const SizedBox(height: EmsSpace.s4),
          EmsRangeChart(
            bars: barsFor(context, buckets, byLevel: widget.byLevel),
            guides: widget.guides,
            selected: _selected,
            onSelect: (i) => setState(() => _selected = i == _selected ? null : i),
            xLabels: axisLabels(buckets),
            yUnit: widget.unit,
            semanticSummary: summary.isEmpty
                ? tr('m_noReadingsWindow')
                : '${tr('m_range')} ${EmsFormat.value(summary.min)}–${EmsFormat.value(summary.max)} ${widget.unit}, ${summary.count} ${tr('m_readings')}',
          ),
          const SizedBox(height: EmsSpace.s3),
          EmsChartLegend(items: [
            if (widget.byLevel) ...[
              (c.safeSignal, tr('m_lvSafe'), false),
              (c.warningSignal, tr('m_lvCaution'), false),
              (c.dangerSignal, tr('m_lvDanger'), false),
            ] else
              (c.primary, tr('m_measured'), false),
            if (widget.flaggedLabel != null && inWindow.any((p) => p.flagged)) (c.primary, widget.flaggedLabel!, true),
            if (emptyBuckets > 0) (c.textDisabled, tr('m_noReadings'), true),
          ]),
          const SizedBox(height: EmsSpace.s4),
          Divider(height: 1, color: c.borderSubtle),
          const SizedBox(height: EmsSpace.s4),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: tr('m_latest'),
                  value: latest == null ? '—' : EmsFormat.value(latest.value),
                  note: latest == null ? null : _ago(latest.at),
                ),
              ),
              Expanded(child: _Stat(label: tr('m_average'), value: EmsFormat.value(summary.average))),
              Expanded(child: _Stat(label: tr('m_readingsCount'), value: '${summary.count}')),
            ],
          ),
          if (widget.onShowAll != null) ...[
            const SizedBox(height: EmsSpace.s2),
            EmsDrillLink(label: tr('m_showAll'), detail: '${widget.points.length}', onTap: widget.onShowAll!),
          ] else
            const SizedBox(height: EmsSpace.s3),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return tr('time_justNow');
    final n = d.inMinutes < 60 ? '${d.inMinutes}' : (d.inHours < 24 ? '${d.inHours}' : '${d.inDays}');
    final u = d.inMinutes < 60 ? 'min' : (d.inHours < 24 ? 'h' : 'd');
    return tr('time_ago_fmt').replaceAll('{n}', n).replaceAll('{u}', u);
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.label, required this.value, required this.unit, required this.caption, this.tone});

  final String label;
  final String value;
  final String unit;
  final String caption;
  final EmsTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: context.type.eyebrow),
        const SizedBox(height: EmsSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: context.type.metricLg.copyWith(color: tone == null ? c.text : emsTone(context, tone!).fg)),
              ),
            ),
            const SizedBox(width: EmsSpace.s2),
            Text(unit, style: context.type.mono.copyWith(color: c.textTertiary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(caption, style: context.type.caption),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10)),
        const SizedBox(height: EmsSpace.s2),
        Text(value, style: context.type.metricMd.copyWith(fontSize: 18)),
        if (note != null) Text(note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
