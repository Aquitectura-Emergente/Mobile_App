/// Clasificacion de un campo electromagnetico medido en microtesla.
///
/// IMPORTANTE: el edge es la autoridad de la clasificacion. El backend respeta
/// el nivel que decide el edge y no reclasifica, y el movil muestra el `level`
/// que recibe. Esta funcion es solo el *fallback* para valores agregados que
/// llegan sin nivel (por ejemplo el pico de un informe).
///
/// Estaba escrita en linea en `reports_screen.dart`:
///     report.peak >= 200 ? 'danger' : report.peak >= 100 ? 'caution' : 'safe'
///
/// Los umbrales (referencia ICNIRP 50 Hz) estan duplicados a proposito en los
/// cuatro stacks. Si cambias estos, cambia los otros tres:
///   - emsafe-edge-flask/monitoring/domain/value_objects.py
///   - Back-End/.../radiationmonitoring/domain/services/RadiationLevel.java
///   - Front-End/.../contexts/radiationmonitoring/domain/radiation-level.ts
library;

const double cautionThresholdUT = 100.0;
const double dangerThresholdUT = 200.0;

/// Niveles tal y como los emite el backend para el movil: en minusculas.
/// (El edge los manda en MAYUSCULAS; el backend normaliza para `/client/**`.)
abstract final class RadiationLevel {
  static const String safe = 'safe';
  static const String caution = 'caution';
  static const String danger = 'danger';

  static const List<String> all = [safe, caution, danger];
}

/// Clasifica un valor en µT. Umbrales inclusivos: 100 µT ya es `caution`.
String levelForValue(double microTesla) {
  if (microTesla >= dangerThresholdUT) return RadiationLevel.danger;
  if (microTesla >= cautionThresholdUT) return RadiationLevel.caution;
  return RadiationLevel.safe;
}
