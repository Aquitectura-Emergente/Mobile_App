import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'ems_icons.g.dart';

import 'ems_theme.dart';
import 'ems_tokens.g.dart';

/// Tonos semánticos compartidos con la web (`.ems-tag--*`).
/// Verde = seguro, amarillo = advertencia, rojo = peligro / excedido.
enum EmsTone { neutral, safe, warning, danger, critical, info, live, primary, accent }

class EmsToneColors {
  const EmsToneColors(this.fg, this.bg, this.border, this.signal);
  final Color fg;
  final Color bg;
  final Color border;
  final Color signal;
}

EmsToneColors emsTone(BuildContext context, EmsTone tone) {
  final c = context.ems;
  switch (tone) {
    case EmsTone.safe:
      return EmsToneColors(c.safe, c.safeSubtle, c.safeBorder, c.safeSignal);
    case EmsTone.warning:
      return EmsToneColors(c.warning, c.warningSubtle, c.warningBorder, c.warningSignal);
    case EmsTone.danger:
      return EmsToneColors(c.danger, c.dangerSubtle, c.dangerBorder, c.dangerSignal);
    case EmsTone.critical:
      return EmsToneColors(Colors.white, c.dangerSignal, c.dangerSignal, Colors.white);
    case EmsTone.info:
      return EmsToneColors(c.info, c.infoSubtle, c.infoBorder, c.infoSignal);
    case EmsTone.live:
      return EmsToneColors(c.live, c.liveSubtle, c.live, c.liveSignal);
    case EmsTone.primary:
      return EmsToneColors(c.primary, c.primarySubtle, c.primaryBorder, c.primary);
    case EmsTone.accent:
      return EmsToneColors(c.accent, c.accentSubtle, c.border, c.accent);
    case EmsTone.neutral:
      return EmsToneColors(c.textSecondary, c.bgSunken, c.border, c.offline);
  }
}

/// Etiqueta de estado: marca cuadrada (o icono) + texto en mayúsculas mono.
class EmsTag extends StatelessWidget {
  const EmsTag(this.label, {super.key, this.tone = EmsTone.neutral, this.icon});

  final String label;
  final EmsTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = emsTone(context, tone);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s3),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(EmsRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 13, color: t.fg)
          else
            Container(width: 7, height: 7, color: t.signal),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: context.type.monoSm.copyWith(color: t.fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de conectividad / frescura de un dato.
enum EmsSignalState { live, online, offline, stale, syncing, pending }

class EmsSignal extends StatefulWidget {
  const EmsSignal({super.key, required this.state, required this.label, this.style});

  final EmsSignalState state;
  final String label;
  final TextStyle? style;

  @override
  State<EmsSignal> createState() => _EmsSignalState();
}

class _EmsSignalState extends State<EmsSignal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  bool get _animated => widget.state == EmsSignalState.live || widget.state == EmsSignalState.syncing;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (_animated) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant EmsSignal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_animated && !_c.isAnimating) _c.repeat();
    if (!_animated && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Widget dot;
    switch (widget.state) {
      case EmsSignalState.live:
      case EmsSignalState.online:
        dot = _Dot(color: c.safeSignal, ring: widget.state == EmsSignalState.live && !reduce ? _c : null);
      case EmsSignalState.syncing:
        dot = FadeTransition(opacity: reduce ? const AlwaysStoppedAnimation(1) : Tween(begin: 0.35, end: 1.0).animate(_c), child: _Dot(color: c.liveSignal));
      case EmsSignalState.stale:
        dot = _Dot(color: c.warningSignal, hollow: true);
      case EmsSignalState.pending:
        dot = _Dot(color: c.primary, hollow: true);
      case EmsSignalState.offline:
        dot = _Dot(color: c.offline);
    }
    return Semantics(
      label: widget.label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 16, height: 16, child: Center(child: dot)),
          const SizedBox(width: EmsSpace.s2),
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: widget.style ??
                  context.type.caption.copyWith(
                    color: widget.state == EmsSignalState.offline ? c.textTertiary : c.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.hollow = false, this.ring});
  final Color color;
  final bool hollow;
  final Animation<double>? ring;

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hollow ? Colors.transparent : color,
        border: hollow ? Border.all(color: color, width: 2) : null,
      ),
    );
    if (ring == null) return core;
    return AnimatedBuilder(
      animation: ring!,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 8 + 8 * ring!.value,
            height: 8 + 8 * ring!.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 1 - ring!.value)),
            ),
          ),
          child!,
        ],
      ),
      child: core,
    );
  }
}

/// Superficie plana con filete (no todo es tarjeta: sin sombra, radio 6).
class EmsPanel extends StatelessWidget {
  const EmsPanel({super.key, required this.child, this.padding = const EdgeInsets.all(EmsSpace.s6), this.color, this.borderColor, this.onTap, this.railColor});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final Color? railColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EmsRadius.md),
        side: BorderSide(color: borderColor ?? c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: railColor == null
            ? content
            : DecoratedBox(
                decoration: BoxDecoration(border: Border(left: BorderSide(color: railColor!, width: EmsBorder.rail))),
                child: content,
              ),
      ),
    );
  }
}

/// Encabezado de sección: índice mono en cobre + título + acción opcional.
class EmsSectionHeader extends StatelessWidget {
  const EmsSectionHeader({super.key, required this.title, this.index, this.trailing, this.padding = const EdgeInsets.only(bottom: EmsSpace.s4)});

  final String title;
  final String? index;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (index != null) ...[
            Text(index!, style: context.type.monoSm.copyWith(color: c.accent)),
            const SizedBox(width: EmsSpace.s3),
          ],
          Expanded(child: Text(title.toUpperCase(), style: context.type.eyebrow, overflow: TextOverflow.ellipsis)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Lectura de instrumento: etiqueta, valor mono, unidad y nota.
class EmsReadout extends StatelessWidget {
  const EmsReadout({super.key, required this.label, required this.value, this.unit, this.note, this.tone, this.icon, this.large = false});

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final EmsTone? tone;
  final IconData? icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final t = tone == null ? null : emsTone(context, tone!);
    final valueStyle = (large ? context.type.metricXl : context.type.metricLg).copyWith(
      color: tone == EmsTone.danger ? c.danger : c.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: t?.fg ?? c.textTertiary), const SizedBox(width: 6)],
            Flexible(child: Text(label.toUpperCase(), style: context.type.eyebrow.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: EmsSpace.s2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: valueStyle),
              if (unit != null) ...[
                const SizedBox(width: EmsSpace.s2),
                Text(unit!, style: context.type.mono.copyWith(color: c.textTertiary)),
              ],
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: EmsSpace.s1),
          Text(note!, style: context.type.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}

/// Barra de dosis con escala graduada y marcas de advertencia y límite.
/// [fraction] es la proporción consumida del límite (1.0 = 100 %).
class EmsDoseBar extends StatelessWidget {
  const EmsDoseBar({super.key, required this.fraction, this.warnAt = 0.8, this.tone = EmsTone.safe, this.height = 12});

  final double fraction;
  final double? warnAt;
  final EmsTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final t = emsTone(context, tone);
    final f = fraction.clamp(0.0, 1.0);
    return Semantics(
      value: '${(fraction * 100).round()} %',
      child: SizedBox(
        height: height + 14,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.bgSunken,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(EmsRadius.xs),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: EmsDuration.slow,
                        curve: Curves.easeOutCubic,
                        width: w * f,
                        child: CustomPaint(
                          painter: tone == EmsTone.danger || tone == EmsTone.critical
                              ? _HatchPainter(t.signal, c.danger)
                              : null,
                          child: Container(color: tone == EmsTone.danger || tone == EmsTone.critical ? null : t.signal),
                        ),
                      ),
                    ),
                  ),
                ),
                if (warnAt != null)
                  Positioned(left: w * warnAt! - 1, top: -3, width: 2, height: height + 6, child: Container(color: c.warningSignal)),
                Positioned(right: 0, top: -3, width: 2, height: height + 6, child: Container(color: c.dangerSignal)),
                Positioned(left: 0, right: 0, top: height + 4, height: 8, child: CustomPaint(painter: EmsScalePainter(c.borderStrong, major: 10, minor: 40))),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final p = Paint()
      ..color = b
      ..strokeWidth = 4;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double x = -size.height; x < size.width + size.height; x += 10) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HatchPainter old) => old.a != a || old.b != b;
}

/// Regla graduada: firma visual (escala de instrumento).
class EmsScalePainter extends CustomPainter {
  EmsScalePainter(this.color, {this.major = 5, this.minor = 25});
  final Color color;
  final int major;
  final int minor;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (int i = 0; i <= minor; i++) {
      final x = (size.width - 1) * i / minor + 0.5;
      final isMajor = i % (minor ~/ major) == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, isMajor ? size.height : size.height * 0.45), p);
    }
  }

  @override
  bool shouldRepaint(covariant EmsScalePainter old) => old.color != color;
}

class EmsScaleRule extends StatelessWidget {
  const EmsScaleRule({super.key, this.height = 7, this.color});
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final col = color ?? context.ems.borderStrong;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: EmsScalePainter(col, major: 6, minor: 48))),
        Container(height: 1, color: col),
      ],
    );
  }
}

/// Aviso con riel lateral de estado.
class EmsBanner extends StatelessWidget {
  const EmsBanner({super.key, required this.tone, required this.message, this.title, this.icon, this.action});

  final EmsTone tone;
  final String message;
  final String? title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = emsTone(context, tone);
    final c = context.ems;
    return EmsRailBox(
      color: t.bg,
      borderColor: t.border,
      railColor: t.signal,
      padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s4, EmsSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? PhosphorIconsRegular.info, size: 18, color: t.fg),
          const SizedBox(width: EmsSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: context.type.label.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                Text(message, style: context.type.bodySm),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: EmsSpace.s3), action!],
        ],
      ),
    );
  }
}

/// Caja con filete uniforme, radio y riel lateral de color (estado).
class EmsRailBox extends StatelessWidget {
  const EmsRailBox({super.key, required this.child, required this.color, required this.borderColor, required this.railColor, this.padding = EdgeInsets.zero, this.railWidth = EmsBorder.rail, this.radius = EmsRadius.sm});

  final Widget child;
  final Color color;
  final Color borderColor;
  final Color railColor;
  final EdgeInsetsGeometry padding;
  final double railWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: railWidth, color: railColor),
            Expanded(child: Padding(padding: padding, child: child)),
          ],
        ),
      ),
    );
  }
}

/// Distintivo de contenido generado por IA (nunca se confunde con un cálculo).
class EmsAiBadge extends StatelessWidget {
  const EmsAiBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => EmsTag(label, tone: EmsTone.accent, icon: PhosphorIconsRegular.sparkle);
}

enum EmsEmptyKind { empty, error, offline, noPermission }

/// Estado vacío / error / sin conexión.
class EmsEmptyState extends StatelessWidget {
  const EmsEmptyState({super.key, required this.title, this.message, this.kind = EmsEmptyKind.empty, this.icon, this.action});

  final String title;
  final String? message;
  final EmsEmptyKind kind;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final (IconData ic, Color col, Color border) = switch (kind) {
      EmsEmptyKind.error => (PhosphorIconsRegular.warningOctagon, c.danger, c.dangerBorder),
      EmsEmptyKind.offline => (PhosphorIconsRegular.wifiSlash, c.warning, c.warningBorder),
      EmsEmptyKind.noPermission => (PhosphorIconsRegular.lockKey, c.textTertiary, c.borderStrong),
      EmsEmptyKind.empty => (PhosphorIconsRegular.tray, c.textTertiary, c.borderStrong),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s7, vertical: EmsSpace.s9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(EmsRadius.sm),
            ),
            child: Icon(icon ?? ic, color: col, size: 24),
          ),
          const SizedBox(height: EmsSpace.s5),
          Text(title, textAlign: TextAlign.center, style: context.type.h4),
          if (message != null) ...[
            const SizedBox(height: EmsSpace.s3),
            Text(message!, textAlign: TextAlign.center, style: context.type.bodySm),
          ],
          if (action != null) ...[const SizedBox(height: EmsSpace.s6), action!],
        ],
      ),
    );
  }
}

/// Esqueleto de carga con brillo sutil.
class EmsSkeleton extends StatefulWidget {
  const EmsSkeleton({super.key, this.width = double.infinity, this.height = 14, this.radius = EmsRadius.xs});
  final double width;
  final double height;
  final double radius;

  @override
  State<EmsSkeleton> createState() => _EmsSkeletonState();
}

class _EmsSkeletonState extends State<EmsSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 3 * _c.value, 0),
            end: Alignment(1 + 3 * _c.value, 0),
            colors: [c.bgSunken, c.surfaceHover, c.bgSunken],
          ),
        ),
      ),
    );
  }
}

/// Marca oficial EMSafe (escudo + E + pulso) en su cian original.
class EmsBrandMark extends StatelessWidget {
  const EmsBrandMark({super.key, this.size = 32, this.wordmark = false, this.color});

  static const Color logoCyan = Color(0xFF3FE3EC);

  final double size;
  final bool wordmark;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(width: size, height: size, child: CustomPaint(painter: _BrandPainter()));
    if (!wordmark) return Semantics(label: 'EMSafe', child: mark);
    return Semantics(
      label: 'EMSafe',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.32),
          Text(
            'EMSafe',
            style: TextStyle(
              fontFamily: EmsFont.heading,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.72,
              letterSpacing: 0.4,
              color: color ?? context.ems.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32;
    final p = Paint()
      ..color = EmsBrandMark.logoCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shield = Path()
      ..moveTo(16 * s, 2.5 * s)
      ..lineTo(4.5 * s, 7 * s)
      ..lineTo(4.5 * s, 15.2 * s)
      ..cubicTo(4.5 * s, 22.2 * s, 9.3 * s, 27.5 * s, 16 * s, 29.5 * s)
      ..cubicTo(22.7 * s, 27.5 * s, 27.5 * s, 22.2 * s, 27.5 * s, 15.2 * s)
      ..lineTo(27.5 * s, 7 * s)
      ..close();
    canvas.drawPath(shield, p);
    final e = Path()
      ..moveTo(20.5 * s, 10 * s)
      ..lineTo(12 * s, 10 * s)
      ..lineTo(12 * s, 22 * s)
      ..lineTo(20.5 * s, 22 * s)
      ..moveTo(12 * s, 16 * s)
      ..lineTo(18 * s, 16 * s);
    canvas.drawPath(e, p);
    final pulse = Path()
      ..moveTo(3 * s, 16 * s)
      ..lineTo(8 * s, 16 * s)
      ..lineTo(9.6 * s, 13 * s)
      ..lineTo(11.6 * s, 19 * s)
      ..lineTo(13 * s, 16 * s)
      ..lineTo(19 * s, 16 * s)
      ..lineTo(20.4 * s, 13.4 * s)
      ..lineTo(22.2 * s, 18.6 * s)
      ..lineTo(23.6 * s, 16 * s)
      ..lineTo(29 * s, 16 * s);
    canvas.drawPath(pulse, p..strokeWidth = 1.3 * s);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Utilidad: ángulo para medidores circulares.
double emsArc(double fraction) => math.pi * 2 * fraction.clamp(0.0, 1.0);
