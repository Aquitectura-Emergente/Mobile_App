import 'package:flutter_test/flutter_test.dart';
import 'package:emsafe_app/contexts/iam/domain/user_segment.dart';
import 'package:emsafe_app/contexts/iam/infrastructure/segment_probe.dart';

void main() {
  group('segmento de la cuenta', () {
    test('403 es cliente del hogar (sin membresía)', () {
      expect(SegmentProbe.classify(403), UserSegment.home);
    });

    test('404 es operario sin jornada abierta', () {
      expect(SegmentProbe.classify(404), UserSegment.operator);
    });

    test('otros errores no deciden', () {
      expect(SegmentProbe.classify(500), isNull);
      expect(SegmentProbe.classify(null), isNull);
    });

    test('se recupera desde su nombre guardado', () {
      expect(UserSegment.fromName('operator'), UserSegment.operator);
      expect(UserSegment.fromName('x'), isNull);
    });
  });
}
