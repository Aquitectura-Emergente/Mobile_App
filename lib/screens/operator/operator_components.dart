import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';

/// Color de señal por estado de exposición (verde normal, amarillo advertencia, rojo excedido).
Color exposureColor(ExposureStatus status) => switch (status) {
      ExposureStatus.normal => Etapa3Palette.green,
      ExposureStatus.warning => Etapa3Palette.amber,
      ExposureStatus.exceeded => Etapa3Palette.red,
    };

/// Tono del sistema de diseño por estado. Advertencia y excedido son estados distintos:
/// el excedido usa el tono crítico (relleno sólido).
EmsTone exposureTone(ExposureStatus status) => switch (status) {
      ExposureStatus.normal => EmsTone.safe,
      ExposureStatus.warning => EmsTone.warning,
      ExposureStatus.exceeded => EmsTone.critical,
    };

String exposureLabel(ExposureStatus status) => switch (status) {
      ExposureStatus.normal => tr('op_statusNormal'),
      ExposureStatus.warning => tr('op_statusWarning'),
      ExposureStatus.exceeded => tr('op_statusExceeded'),
    };

/// Porcentaje con el formato de la app ("84 %").
String exposurePercent(double value) => '${value.round()} %';

/// Unidad del índice como se muestra al operario ("uT*s" → "µT·s").
String exposureUnit(String unit) => unit.replaceAll('uT', 'µT').replaceAll('*', '·');

/// Índice de exposición abreviado con un decimal: 950 → "950",
/// 12 400 → "12.4k", 3 000 000 → "3M".
String exposureIndex(double value) {
  final abs = value.abs();
  if (abs < 999.5) return etapa3Num(value, decimals: 0);
  // Se redondea antes de elegir el sufijo para no mostrar "1000k".
  final inK = (value / 1000 * 10).round() / 10;
  if (inK.abs() < 1000) return '${_oneDecimal(inK)}k';
  return '${_oneDecimal((value / 1000000 * 10).round() / 10)}M';
}

String _oneDecimal(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Fecha y hora cortas de una marca ISO.
String exposureDateTime(String? iso) {
  final dt = etapa3ParseTime(iso);
  if (dt == null) return '--';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
}

/// Medidor de la jornada: arco graduado con el porcentaje del límite consumido.
/// La marca roja al final del arco es el límite configurado por el SSO (100 %).
class ExposureGauge extends StatelessWidget {
  const ExposureGauge({super.key, required this.session, this.size = 200});

  final ExposureSession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final color = exposureColor(session.status);
    return Semantics(
      label: '${exposurePercent(session.percentage)} ${tr('op_consumed')}',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GaugePainter(
            progress: session.progress,
            color: color,
            track: c.bgSunken,
            tick: c.borderStrong,
            limit: c.dangerSignal,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  exposurePercent(session.percentage),
                  style: context.type.metricXl.copyWith(
                    fontSize: size * 0.22,
                    color: session.status == ExposureStatus.normal ? c.text : color,
                  ),
                ),
                const SizedBox(height: EmsSpace.s1),
                SizedBox(
                  width: size * 0.62,
                  child: Text(
                    tr('op_consumed'),
                    textAlign: TextAlign.center,
                    style: context.type.caption,
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

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color, required this.track, required this.tick, required this.limit});

  final double progress;
  final Color color;
  final Color track;
  final Color tick;
  final Color limit;

  static const start = math.pi * 0.75;
  static const sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: r);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, start, sweep, false, base);
    if (progress > 0) canvas.drawArc(rect, start, sweep * progress, false, base..color = color);

    // Escala: 50 divisiones (cada 2 %), mayores cada 10 %
    final p = Paint();
    for (int i = 0; i <= 50; i++) {
      final a = start + sweep * i / 50;
      final major = i % 5 == 0;
      final isLimit = i == 50;
      p
        ..color = isLimit ? limit : tick
        ..strokeWidth = isLimit ? 2.5 : 1;
      final r1 = r + stroke / 2 + 3;
      final r2 = r1 + (isLimit ? 10 : (major ? 7 : 3.5));
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + d * r1, center + d * r2, p);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress || old.color != color || old.track != track;
}

/// Banda de estado de la jornada: evidente sin leer cifras (color + icono + texto).
class ExposureStatusBand extends StatelessWidget {
  const ExposureStatusBand({super.key, required this.status});

  final ExposureStatus status;

  @override
  Widget build(BuildContext context) {
    final t = emsTone(context, exposureTone(status));
    final c = context.ems;
    final critical = status == ExposureStatus.exceeded;
    final (IconData icon, String hint) = switch (status) {
      ExposureStatus.normal => (PhosphorIconsRegular.shieldCheck, tr('op_statusNormalHint')),
      ExposureStatus.warning => (PhosphorIconsRegular.warning, tr('op_statusWarningHint')),
      ExposureStatus.exceeded => (PhosphorIconsRegular.warningOctagon, tr('op_statusExceededHint')),
    };
    return Semantics(
      liveRegion: true,
      child: EmsRailBox(
        color: critical ? c.dangerSignal : t.bg,
        borderColor: critical ? c.dangerSignal : t.border,
        railColor: critical ? c.danger : t.signal,
        railWidth: 4,
        radius: EmsRadius.md,
        padding: const EdgeInsets.all(EmsSpace.s5),
        child: Row(
          children: [
            Icon(icon, size: 30, color: critical ? Colors.white : t.fg),
            const SizedBox(width: EmsSpace.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exposureLabel(status),
                    style: context.type.h2.copyWith(color: critical ? Colors.white : t.fg, height: 1.1),
                  ),
                  const SizedBox(height: EmsSpace.s1),
                  Text(
                    hint,
                    style: context.type.bodySm.copyWith(color: critical ? Colors.white.withValues(alpha: 0.9) : c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje centrado para estados vacíos.
class OperatorEmpty extends StatelessWidget {
  const OperatorEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return EmsPanel(
      padding: EdgeInsets.zero,
      child: EmsEmptyState(icon: icon, title: title, message: subtitle),
    );
  }
}
