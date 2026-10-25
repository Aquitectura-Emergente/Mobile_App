import 'package:flutter_test/flutter_test.dart';

import 'package:emsafe_app/contexts/radiationmonitoring/domain/radiation_level.dart';

/// El edge es la autoridad de la clasificacion y estos umbrales estan
/// duplicados en los cuatro stacks. Si estos tests cambian, hay que cambiar
/// el edge (Python), el backend (Java) y la web (TypeScript) con ellos.
void main() {
  group('levelForValue', () {
    test('por debajo de 100 µT es seguro', () {
      for (final v in [0.0, 45.2, 99.99]) {
        expect(levelForValue(v), RadiationLevel.safe, reason: '$v µT');
      }
    });

    test('el umbral de precaucion es inclusivo', () {
      expect(levelForValue(cautionThresholdUT), RadiationLevel.caution);
      expect(levelForValue(100.0), RadiationLevel.caution);
    });

    test('entre 100 y 200 µT es precaucion', () {
      for (final v in [100.01, 150.7, 199.99]) {
        expect(levelForValue(v), RadiationLevel.caution, reason: '$v µT');
      }
    });

    test('el umbral de peligro es inclusivo', () {
      expect(levelForValue(dangerThresholdUT), RadiationLevel.danger);
      expect(levelForValue(200.0), RadiationLevel.danger);
    });

    test('por encima de 200 µT es peligro', () {
      for (final v in [250.4, 10000.0]) {
        expect(levelForValue(v), RadiationLevel.danger, reason: '$v µT');
      }
    });

    test('los umbrales son los acordados con los otros stacks', () {
      expect(cautionThresholdUT, 100.0);
      expect(dangerThresholdUT, 200.0);
    });

    test('los niveles viajan en minusculas en la API del movil', () {
      // El edge los emite en MAYUSCULAS; el backend normaliza para /client/**.
      expect(RadiationLevel.safe, 'safe');
      expect(RadiationLevel.caution, 'caution');
      expect(RadiationLevel.danger, 'danger');
    });
  });
}
