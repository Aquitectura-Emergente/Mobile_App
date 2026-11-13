import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';

Color exposureColor(ExposureStatus status) => switch (status) {
      ExposureStatus.normal => Etapa3Palette.green,
      ExposureStatus.warning => Etapa3Palette.amber,
      ExposureStatus.exceeded => Etapa3Palette.red,
    };

String exposureLabel(ExposureStatus status) => switch (status) {
      ExposureStatus.normal => tr('op_statusNormal'),
      ExposureStatus.warning => tr('op_statusWarning'),
      ExposureStatus.exceeded => tr('op_statusExceeded'),
    };

/// Porcentaje con el formato de la app ("84 %").
String exposurePercent(double value) => '${value.round()} %';

/// Índice de exposición abreviado (12 400 → "12.4k").
String exposureIndex(double value) => value >= 10000
    ? '${(value / 1000).toStringAsFixed(1)}k'
    : etapa3Num(value, decimals: 0);

/// Fecha y hora cortas de una marca ISO.
String exposureDateTime(String? iso) {
  final dt = etapa3ParseTime(iso);
  if (dt == null) return '--';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
}

/// Anillo con el porcentaje del límite de jornada consumido.
class ExposureGauge extends StatelessWidget {
  const ExposureGauge({super.key, required this.session, this.size = 190});

  final ExposureSession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = exposureColor(session.status);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(progress: session.progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exposurePercent(session.percentage),
                style: TextStyle(
                  color: color,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('op_consumed'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Etapa3Palette.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    final base = Paint()
      ..color = Etapa3Palette.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, base);
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      start,
      sweep * progress,
      false,
      base..color = color,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
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
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          Icon(icon, color: Etapa3Palette.cyan, size: 40),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Etapa3Palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Etapa3Palette.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
