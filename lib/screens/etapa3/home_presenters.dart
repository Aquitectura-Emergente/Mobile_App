import 'package:flutter/material.dart';

import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/radiationmonitoring/domain/client_reading.dart';
import '../../contexts/radiationmonitoring/domain/radiation_level.dart';
import '../../contexts/radiationmonitoring/domain/reading_series.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../shared/reading_history_screen.dart';
import 'reading_detail_screen.dart';

/// Puntos de la serie a partir de las lecturas de un sensor. Solo entran las
/// que traen hora exacta: sin ella no se pueden ubicar en un tramo horario.
List<SeriesPoint> homePoints(Iterable<ClientReading> readings) => [
      for (final r in readings)
        if (r.hasExactTime && r.value != null)
          SeriesPoint(at: r.takenAt!, value: r.value!, level: r.effectiveLevel, source: r),
    ];

/// Umbrales del hogar (referencia ICNIRP 50 Hz, los mismos del backend).
List<EmsChartGuide> homeGuides(BuildContext context) => [
      EmsChartGuide(cautionThresholdUT, context.ems.warningSignal),
      EmsChartGuide(dangerThresholdUT, context.ems.dangerSignal),
    ];

/// Estado de comunicación de un sensor según su estado en el catálogo.
(EmsSignalState, String) sensorSignal(ClientDevice d) {
  if (d.isReporting) return (EmsSignalState.online, tr('m_sensorReporting'));
  return switch (d.status) {
    'requires-maintenance' => (EmsSignalState.stale, tr('m_sensorNeedsMaint')),
    'in-maintenance' => (EmsSignalState.offline, tr('m_sensorInMaint')),
    _ => (EmsSignalState.offline, tr('m_sensorSilent')),
  };
}

/// Abre el histórico completo de un sensor.
void openSensorHistory(BuildContext context, ClientDevice device, List<ClientReading> readings) {
  final points = homePoints(readings);
  final missing = readings.length - points.length;
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ReadingHistoryScreen(
      title: device.name,
      points: points,
      note: missing > 0 ? tr('m_noExactTime').replaceAll('{n}', '$missing') : null,
      onOpen: (ctx, p) => Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => HomeReadingDetailScreen(reading: p.source! as ClientReading, device: device),
      )),
    ),
  ));
}

/// Escala de niveles del hogar con la posición de la lectura. Se pinta sin
/// LayoutBuilder para poder vivir dentro de cajas de altura intrínseca.
class HomeLevelScale extends StatelessWidget {
  const HomeLevelScale({super.key, required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Semantics(
      label: tr('m_scaleSemantics'),
      child: SizedBox(
        height: 38,
        width: double.infinity,
        child: CustomPaint(
          painter: _LevelScalePainter(
            value: value,
            safe: c.safeSignal,
            caution: c.warningSignal,
            danger: c.dangerSignal,
            marker: c.text,
            label: context.type.monoSm.copyWith(fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _LevelScalePainter extends CustomPainter {
  _LevelScalePainter({required this.value, required this.safe, required this.caution, required this.danger, required this.marker, required this.label});

  final double? value;
  final Color safe, caution, danger, marker;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    const top = dangerThresholdUT * 1.5;
    double x(double u) => (u / top).clamp(0, 1) * size.width;
    const y = 10.0, h = 8.0;
    canvas.drawRect(Rect.fromLTRB(0, y, x(cautionThresholdUT), y + h), Paint()..color = safe.withValues(alpha: 0.55));
    canvas.drawRect(Rect.fromLTRB(x(cautionThresholdUT), y, x(dangerThresholdUT), y + h), Paint()..color = caution.withValues(alpha: 0.55));
    canvas.drawRect(Rect.fromLTRB(x(dangerThresholdUT), y, size.width, y + h), Paint()..color = danger.withValues(alpha: 0.55));
    for (final t in [cautionThresholdUT, dangerThresholdUT]) {
      final tp = TextPainter(text: TextSpan(text: t.toStringAsFixed(0), style: label), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x(t) - tp.width / 2, 22));
    }
    final v = value;
    if (v != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x(v) - 1.5, 4, 3, 20), const Radius.circular(1)),
        Paint()..color = marker,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelScalePainter old) => old.value != value || old.marker != marker;
}
