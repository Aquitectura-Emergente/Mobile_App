import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ems_theme.dart';
import 'ems_tokens.g.dart';

/// Una barra del gráfico de rangos: del mínimo al máximo de su tramo.
/// Sin valores ([low] y [high] nulos) es un tramo sin lecturas: se dibuja como
/// marca hueca en la base, nunca como cero.
class EmsRangeBar {
  const EmsRangeBar({this.low, this.high, this.color, this.hatched = false, this.semanticLabel});

  final double? low;
  final double? high;
  final Color? color;

  /// Lectura diferida o estimada: barra rayada.
  final bool hatched;
  final String? semanticLabel;

  bool get isEmpty => high == null;
}

/// Línea de referencia horizontal (umbral).
class EmsChartGuide {
  const EmsChartGuide(this.value, this.color, {this.label});
  final double value;
  final Color color;
  final String? label;
}

/// Gráfico compacto de barras verticales agrupadas por tiempo.
///
/// Cada barra cubre el rango min–max del tramo. Tocar o arrastrar selecciona
/// un tramo ([onSelect]); soltar fuera lo deselecciona.
class EmsRangeChart extends StatelessWidget {
  const EmsRangeChart({
    super.key,
    required this.bars,
    this.guides = const [],
    this.selected,
    this.onSelect,
    this.height = 168,
    this.xLabels = const {},
    this.yMax,
    this.yUnit,
    this.semanticSummary,
  });

  final List<EmsRangeBar> bars;
  final List<EmsChartGuide> guides;
  final int? selected;
  final ValueChanged<int?>? onSelect;
  final double height;

  /// Etiquetas del eje X por índice de barra.
  final Map<int, String> xLabels;
  final double? yMax;
  final String? yUnit;
  final String? semanticSummary;

  static const double _axisW = 38;
  static const double _labelH = 18;

  double _niceMax() {
    var m = yMax ?? 0;
    for (final b in bars) {
      if (b.high != null && b.high! > m) m = b.high!;
    }
    for (final g in guides) {
      if (g.value > m) m = g.value;
    }
    if (m <= 0) return 1;
    final exp = math.pow(10, (math.log(m) / math.ln10).floor()).toDouble();
    for (final s in [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
      if (s * exp >= m * 1.05) return s * exp;
    }
    return 10 * exp;
  }

  int? _indexAt(double dx, double width) {
    if (bars.isEmpty) return null;
    final plotW = width - _axisW;
    if (dx < 0 || dx > plotW) return null;
    return (dx / plotW * bars.length).floor().clamp(0, bars.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final max = _niceMax();
    return Semantics(
      label: semanticSummary,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, cons) {
            void pick(Offset p) {
              final i = _indexAt(p.dx, cons.maxWidth);
              if (i != null && i != selected) HapticFeedback.selectionClick();
              onSelect?.call(i);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: onSelect == null ? null : (d) => pick(d.localPosition),
              onHorizontalDragStart: onSelect == null ? null : (d) => pick(d.localPosition),
              onHorizontalDragUpdate: onSelect == null ? null : (d) => pick(d.localPosition),
              child: CustomPaint(
                size: Size(cons.maxWidth, height),
                painter: _RangePainter(
                  bars: bars,
                  guides: guides,
                  selected: selected,
                  max: max,
                  xLabels: xLabels,
                  grid: c.grid,
                  gridStrong: c.borderStrong,
                  barColor: c.primary,
                  gapColor: c.textDisabled,
                  labelStyle: context.type.monoSm.copyWith(fontSize: 10, color: c.textTertiary),
                  selectColor: c.text,
                  bg: c.surface,
                  axisW: _axisW,
                  labelH: _labelH,
                  yUnit: yUnit,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RangePainter extends CustomPainter {
  _RangePainter({
    required this.bars,
    required this.guides,
    required this.selected,
    required this.max,
    required this.xLabels,
    required this.grid,
    required this.gridStrong,
    required this.barColor,
    required this.gapColor,
    required this.labelStyle,
    required this.selectColor,
    required this.bg,
    required this.axisW,
    required this.labelH,
    this.yUnit,
  });

  final List<EmsRangeBar> bars;
  final List<EmsChartGuide> guides;
  final int? selected;
  final double max;
  final Map<int, String> xLabels;
  final Color grid, gridStrong, barColor, gapColor, selectColor, bg;
  final TextStyle labelStyle;
  final double axisW, labelH;
  final String? yUnit;

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    if (v >= 10 || v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: color == null ? labelStyle : labelStyle.copyWith(color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - axisW;
    final plotH = size.height - labelH - 6;
    double y(double v) => 6 + plotH - (v / max).clamp(0, 1) * plotH;

    // Retícula: base y tres divisiones.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final v = max * i / 3;
      final yy = y(v).roundToDouble() + 0.5;
      _dashed(canvas, Offset(0, yy), Offset(plotW, yy), i == 0 ? (Paint()..color = gridStrong..strokeWidth = 1) : gridPaint, dashed: i != 0);
      _text(canvas, _fmt(v), Offset(size.width, yy), align: TextAlign.right);
    }
    if (yUnit != null) _text(canvas, yUnit!, Offset(plotW + 4, size.height - labelH / 2 + 2));

    // Umbrales.
    for (final g in guides) {
      if (g.value > max) continue;
      final yy = y(g.value).roundToDouble() + 0.5;
      _dashed(canvas, Offset(0, yy), Offset(plotW, yy), Paint()..color = g.color.withValues(alpha: 0.7)..strokeWidth = 1, dash: 2, gap: 3);
    }

    if (bars.isEmpty) return;
    final slot = plotW / bars.length;
    final barW = (slot * 0.56).clamp(2.0, 12.0);

    // Banda del tramo seleccionado.
    if (selected != null && selected! >= 0 && selected! < bars.length) {
      final x = slot * selected!;
      canvas.drawRect(Rect.fromLTWH(x, 0, slot, plotH + 6), Paint()..color = selectColor.withValues(alpha: 0.07));
      canvas.drawLine(Offset(x + slot / 2, 0), Offset(x + slot / 2, plotH + 6), Paint()..color = selectColor.withValues(alpha: 0.35)..strokeWidth = 1);
    }

    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = slot * i + slot / 2;
      final dim = selected != null && selected != i;
      if (b.isEmpty) {
        // Hueco: marca corta y hueca sobre la base.
        final p = Paint()
          ..color = gapColor.withValues(alpha: dim ? 0.35 : 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y(0) - 3), width: math.min(barW, 6), height: 4), const Radius.circular(1)), p);
        continue;
      }
      final lo = b.low ?? b.high!;
      var top = y(b.high!);
      var bottom = y(lo);
      if (bottom - top < barW) {
        // Rango estrecho: cápsula mínima centrada en el valor.
        final mid = (top + bottom) / 2;
        top = mid - barW / 2;
        bottom = mid + barW / 2;
      }
      final color = (b.color ?? barColor).withValues(alpha: dim ? 0.35 : 1);
      final r = RRect.fromRectAndRadius(Rect.fromLTRB(cx - barW / 2, top, cx + barW / 2, bottom), Radius.circular(barW / 2));
      if (b.hatched) {
        canvas.drawRRect(r, Paint()..color = color.withValues(alpha: 0.18));
        canvas.save();
        canvas.clipRRect(r);
        final hp = Paint()
          ..color = color
          ..strokeWidth = 1.2;
        for (var yy = top - barW; yy < bottom + barW; yy += 3.5) {
          canvas.drawLine(Offset(cx - barW, yy + barW), Offset(cx + barW, yy - barW), hp);
        }
        canvas.restore();
        canvas.drawRRect(r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1);
      } else {
        canvas.drawRRect(r, Paint()..color = color);
      }
    }

    // Etiquetas del eje X.
    for (final e in xLabels.entries) {
      if (e.key < 0 || e.key >= bars.length) continue;
      final x = slot * e.key + slot / 2;
      canvas.drawLine(Offset(x, plotH + 6), Offset(x, plotH + 10), Paint()..color = gridStrong..strokeWidth = 1);
      _text(canvas, e.value, Offset(x.clamp(10, plotW - 10), size.height - labelH / 2 + 2), align: TextAlign.center);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint p, {bool dashed = true, double dash = 3, double gap = 4}) {
    if (!dashed) {
      canvas.drawLine(a, b, p);
      return;
    }
    var x = a.dx;
    while (x < b.dx) {
      canvas.drawLine(Offset(x, a.dy), Offset(math.min(x + dash, b.dx), a.dy), p);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_RangePainter old) =>
      old.bars != bars || old.selected != selected || old.max != max || old.guides != guides || old.barColor != barColor;
}

/// Mini tira de barras (sin ejes) para filas de lista.
class EmsSparkBars extends StatelessWidget {
  const EmsSparkBars({super.key, required this.bars, this.height = 28, this.width = 96});

  final List<EmsRangeBar> bars;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparkPainter(bars, c.primary, c.textDisabled),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.bars, this.color, this.gap);
  final List<EmsRangeBar> bars;
  final Color color, gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    var max = 0.0;
    for (final b in bars) {
      if ((b.high ?? 0) > max) max = b.high!;
    }
    if (max <= 0) max = 1;
    final slot = size.width / bars.length;
    final w = (slot * 0.6).clamp(1.5, 5.0);
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = slot * i + slot / 2;
      if (b.isEmpty) {
        canvas.drawLine(Offset(cx - w / 2, size.height - 0.5), Offset(cx + w / 2, size.height - 0.5), Paint()..color = gap..strokeWidth = 1);
        continue;
      }
      var top = size.height - (b.high! / max) * size.height;
      var bottom = size.height - ((b.low ?? b.high!) / max) * size.height;
      if (bottom - top < w) {
        final mid = (top + bottom) / 2;
        top = (mid - w / 2).clamp(0, size.height - w);
        bottom = top + w;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(cx - w / 2, top, cx + w / 2, bottom), Radius.circular(w / 2)),
        Paint()..color = b.color ?? color,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.bars != bars;
}

/// Leyenda breve de marcas del gráfico.
class EmsChartLegend extends StatelessWidget {
  const EmsChartLegend({super.key, required this.items});

  /// (color, etiqueta, hueco).
  final List<(Color, String, bool)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: EmsSpace.s5,
      runSpacing: EmsSpace.s2,
      children: [
        for (final (color, label, hollow) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: hollow ? 7 : 6,
                height: hollow ? 5 : 12,
                decoration: BoxDecoration(
                  color: hollow ? null : color,
                  border: hollow ? Border.all(color: color) : null,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: EmsSpace.s2),
              Text(label, style: context.type.caption),
            ],
          ),
      ],
    );
  }
}
