import 'package:flutter/material.dart';

import '../../contexts/radiationmonitoring/domain/reading_series.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import 'measurement_overview.dart';

/// Ventana del histórico completo.
enum HistoryWindow { week, month, all }

/// Nivel 2: todas las lecturas agrupadas por día, con navegación entre fechas,
/// filtro temporal, días sin lecturas y acceso al detalle de cada lectura.
class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({
    super.key,
    required this.title,
    required this.points,
    required this.onOpen,
    this.eyebrow,
    this.unit = 'µT',
    this.byLevel = true,
    this.flaggedLabel,
    this.note,
  });

  final String title;
  final String? eyebrow;
  final List<SeriesPoint> points;
  final void Function(BuildContext context, SeriesPoint point) onOpen;
  final String unit;
  final bool byLevel;
  final String? flaggedLabel;

  /// Aviso bajo el resumen (p. ej. lecturas sin hora exacta).
  final String? note;

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

/// Un día del calendario, con o sin lecturas.
class _Day {
  _Day(this.day, this.group);
  final DateTime day;
  final DayGroup? group;
}

/// Fila de la lista de días: un día, o un tramo de días vacíos agrupados.
class _DayRowData {
  _DayRowData.day(_Day this.day)
      : gapFrom = null,
        gapTo = null,
        gapDays = 0;
  _DayRowData.gap(DateTime this.gapFrom, DateTime this.gapTo, this.gapDays) : day = null;
  final _Day? day;
  final DateTime? gapFrom;
  final DateTime? gapTo;
  final int gapDays;
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  HistoryWindow _window = HistoryWindow.week;
  DateTime? _selectedDay;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Días de la ventana (del más reciente al más antiguo), incluidos los vacíos.
  List<_Day> _days() {
    final groups = {for (final g in ReadingSeries.byDay(widget.points)) g.day: g};
    final today = _dayOf(DateTime.now());
    final oldest = groups.isEmpty ? today : groups.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    final from = switch (_window) {
      HistoryWindow.week => DateTime(today.year, today.month, today.day - 6),
      HistoryWindow.month => DateTime(today.year, today.month, today.day - 29),
      HistoryWindow.all => oldest,
    };
    // Lecturas con fecha futura (reloj del equipo) también se muestran.
    final newest = groups.isEmpty ? today : groups.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    final top = newest.isAfter(today) ? newest : today;
    final out = <_Day>[];
    for (var d = top; !d.isBefore(from); d = DateTime(d.year, d.month, d.day - 1)) {
      out.add(_Day(d, groups[d]));
    }
    return out;
  }

  List<_DayRowData> _rows(List<_Day> days) {
    final rows = <_DayRowData>[];
    var i = 0;
    while (i < days.length) {
      if (days[i].group != null) {
        rows.add(_DayRowData.day(days[i]));
        i++;
        continue;
      }
      var j = i;
      while (j < days.length && days[j].group == null) {
        j++;
      }
      final n = j - i;
      if (n == 1) {
        rows.add(_DayRowData.day(days[i]));
      } else {
        rows.add(_DayRowData.gap(days[j - 1].day, days[i].day, n));
      }
      i = j;
    }
    return rows;
  }

  void _select(DateTime day) {
    setState(() => _selectedDay = day);
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: EmsDuration.slow, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final days = _days();
    final withData = days.where((d) => d.group != null).toList();
    final selected = days.firstWhere(
      (d) => d.day == _selectedDay,
      orElse: () => withData.isNotEmpty ? withData.first : days.first,
    );
    final idx = days.indexOf(selected);
    final windowPoints = withData.expand((d) => d.group!.points);
    final summary = SeriesSummary.of(windowPoints);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                EmsPageHeader(title: widget.title, eyebrow: widget.eyebrow ?? tr('m_allData')),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s5, EmsSpace.s6, EmsSpace.s9),
                    children: [
                      EmsSegmented<HistoryWindow>(
                        value: _window,
                        segments: [
                          (HistoryWindow.week, tr('m_win7')),
                          (HistoryWindow.month, tr('m_win30')),
                          (HistoryWindow.all, tr('m_winAll')),
                        ],
                        onChanged: (w) => setState(() {
                          _window = w;
                          _selectedDay = null;
                        }),
                      ),
                      const SizedBox(height: EmsSpace.s5),
                      _WindowSummary(summary: summary, daysWithData: withData.length, totalDays: days.length, unit: widget.unit),
                      if (widget.note != null) ...[
                        const SizedBox(height: EmsSpace.s4),
                        EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.info, message: widget.note!),
                      ],
                      const SizedBox(height: EmsSpace.s7),
                      // Navegación entre fechas.
                      _DayNavigator(
                        day: selected,
                        unit: widget.unit,
                        byLevel: widget.byLevel,
                        onPrev: idx < days.length - 1 ? () => setState(() => _selectedDay = days[idx + 1].day) : null,
                        onNext: idx > 0 ? () => setState(() => _selectedDay = days[idx - 1].day) : null,
                      ),
                      const SizedBox(height: EmsSpace.s4),
                      if (selected.group == null)
                        EmsPanel(
                          padding: EdgeInsets.zero,
                          child: EmsEmptyState(
                            icon: PhosphorIconsRegular.cloudSlash,
                            title: tr('m_dayEmptyTitle'),
                            message: tr('m_dayEmptyMsg'),
                          ),
                        )
                      else
                        EmsGroup(
                          title: tr('m_dayReadings'),
                          trailing: Text('${selected.group!.points.length}', style: context.type.monoSm),
                          children: [
                            for (final p in selected.group!.points)
                              _PointRow(
                                point: p,
                                unit: widget.unit,
                                byLevel: widget.byLevel,
                                flaggedLabel: widget.flaggedLabel,
                                onTap: () => widget.onOpen(context, p),
                              ),
                          ],
                        ),
                      const SizedBox(height: EmsSpace.s8),
                      EmsSectionHeader(title: tr('m_byDay'), trailing: Text('${withData.length}/${days.length}', style: context.type.monoSm)),
                      EmsGroup(
                        children: [
                          for (final r in _rows(days))
                            if (r.day != null)
                              _DayListRow(
                                day: r.day!,
                                selected: r.day!.day == selected.day,
                                byLevel: widget.byLevel,
                                unit: widget.unit,
                                onTap: () => _select(r.day!.day),
                              )
                            else
                              EmsRow(
                                icon: PhosphorIconsRegular.minus,
                                title: tr('m_gapDays').replaceAll('{n}', '${r.gapDays}'),
                                subtitle: '${EmsFormat.dayMonth(r.gapFrom!)} – ${EmsFormat.dayMonth(r.gapTo!)}',
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowSummary extends StatelessWidget {
  const _WindowSummary({required this.summary, required this.daysWithData, required this.totalDays, required this.unit});

  final SeriesSummary summary;
  final int daysWithData;
  final int totalDays;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    Widget cell(String label, String value, {String? u}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s4, vertical: EmsSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10)),
                const SizedBox(height: EmsSpace.s2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: context.type.metricMd.copyWith(fontSize: 19)))),
                    if (u != null) ...[const SizedBox(width: 3), Text(u, style: context.type.monoSm)],
                  ],
                ),
              ],
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(tr('m_min'), EmsFormat.value(summary.min), u: unit),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_max'), EmsFormat.value(summary.max), u: unit),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_readingsCount'), '${summary.count}'),
            VerticalDivider(width: 1, color: c.borderSubtle),
            cell(tr('m_daysWithData'), '$daysWithData/$totalDays'),
          ],
        ),
      ),
    );
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({required this.day, required this.unit, required this.byLevel, this.onPrev, this.onNext});

  final _Day day;
  final String unit;
  final bool byLevel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final g = day.group;
    final hourly = g?.hourly ??
        ReadingSeries.bucket(const [], from: day.day, to: DateTime(day.day.year, day.day.month, day.day.day + 1), span: const Duration(hours: 1));
    return EmsPanel(
      padding: const EdgeInsets.fromLTRB(EmsSpace.s3, EmsSpace.s3, EmsSpace.s3, EmsSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EmsIconButton(icon: PhosphorIconsRegular.caretLeft, tooltip: tr('m_prevDay'), onPressed: onPrev),
              Expanded(
                child: Column(
                  children: [
                    Text(EmsFormat.dayTitle(day.day), textAlign: TextAlign.center, style: context.type.h4),
                    const SizedBox(height: 2),
                    Text(EmsFormat.date(day.day), textAlign: TextAlign.center, style: context.type.monoSm),
                  ],
                ),
              ),
              EmsIconButton(icon: PhosphorIconsRegular.caretRight, tooltip: tr('m_nextDay'), onPressed: onNext),
            ],
          ),
          const SizedBox(height: EmsSpace.s4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s3),
            child: EmsRangeChart(
              height: 120,
              bars: barsFor(context, hourly, byLevel: byLevel),
              xLabels: const {0: '00', 6: '06', 12: '12', 18: '18', 23: '23'},
              yUnit: unit,
              semanticSummary: g == null
                  ? tr('m_dayEmptyTitle')
                  : '${tr('m_min')} ${EmsFormat.value(g.summary.min)}, ${tr('m_max')} ${EmsFormat.value(g.summary.max)} $unit, ${g.summary.count} ${tr('m_readings')}',
            ),
          ),
          if (g != null) ...[
            const SizedBox(height: EmsSpace.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s4),
              child: Row(
                children: [
                  _MiniStat(tr('m_min'), EmsFormat.value(g.summary.min)),
                  _MiniStat(tr('m_max'), EmsFormat.value(g.summary.max)),
                  _MiniStat(tr('m_average'), EmsFormat.value(g.summary.average)),
                  _MiniStat(tr('m_readingsCount'), '${g.summary.count}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: context.type.mono.copyWith(color: context.ems.text, fontSize: 14)),
          ],
        ),
      );
}

class _DayListRow extends StatelessWidget {
  const _DayListRow({required this.day, required this.selected, required this.byLevel, required this.unit, required this.onTap});

  final _Day day;
  final bool selected;
  final bool byLevel;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final g = day.group;
    return Material(
      color: selected ? c.primarySubtle : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s4, EmsSpace.s4),
          decoration: selected ? BoxDecoration(border: Border(left: BorderSide(color: c.primary, width: EmsBorder.rail))) : null,
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(EmsFormat.weekday(day.day).toUpperCase(), style: context.type.monoSm),
                    Text('${day.day.day}', style: context.type.metricMd.copyWith(fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(width: EmsSpace.s3),
              Expanded(
                child: g == null
                    ? Text(tr('m_noReadings'), style: context.type.bodySm.copyWith(color: c.textTertiary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${EmsFormat.value(g.summary.min)}–${EmsFormat.value(g.summary.max)} $unit', style: context.type.mono.copyWith(color: c.text)),
                          const SizedBox(height: 2),
                          Text('${g.summary.count} ${tr(g.summary.count == 1 ? 'm_reading' : 'm_readings')}', style: context.type.caption),
                        ],
                      ),
              ),
              if (g != null) ...[
                EmsSparkBars(bars: barsFor(context, g.hourly, byLevel: byLevel), width: 72, height: 26),
                if (byLevel && g.worstLevel != null) ...[
                  const SizedBox(width: EmsSpace.s3),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: levelSignal(context, g.worstLevel), borderRadius: BorderRadius.circular(1))),
                ],
              ],
              const SizedBox(width: EmsSpace.s2),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({required this.point, required this.unit, required this.byLevel, required this.onTap, this.flaggedLabel});

  final SeriesPoint point;
  final String unit;
  final bool byLevel;
  final String? flaggedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s3, EmsSpace.s4, EmsSpace.s3),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(EmsFormat.time(point.at), style: context.type.mono.copyWith(color: c.textSecondary))),
              if (byLevel)
                Container(width: 3, height: 22, color: levelSignal(context, point.level))
              else
                Container(width: 3, height: 22, color: point.flagged ? c.warningSignal : c.primary),
              const SizedBox(width: EmsSpace.s4),
              // En pantallas estrechas el valor se reduce en vez de cortarse.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(EmsFormat.value(point.value, decimals: 2), style: context.type.mono.copyWith(fontSize: 16, color: c.text, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      Text(unit, style: context.type.monoSm),
                    ],
                  ),
                ),
              ),
              if (point.flagged && flaggedLabel != null)
                EmsTag(flaggedLabel!, tone: EmsTone.warning)
              else if (byLevel)
                EmsTag(levelLabel(point.level), tone: levelTone(point.level)),
              const SizedBox(width: EmsSpace.s2),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
