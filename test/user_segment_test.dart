import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emsafe_app/contexts/iam/application/auth_facade.dart';
import 'package:emsafe_app/contexts/iam/domain/client_profile.dart';
import 'package:emsafe_app/contexts/iam/domain/user_segment.dart';
import 'package:emsafe_app/contexts/iam/infrastructure/segment_probe.dart';
import 'package:emsafe_app/contexts/iam/infrastructure/session_store.dart';

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

  group('quién usa la app', () {
    test('cliente, operario y admin de pruebas; el resto va al portal web', () {
      expect(MobileRole.isAllowed('client'), isTrue);
      expect(MobileRole.isAllowed('worker'), isTrue);
      expect(MobileRole.isAllowed('admin'), isTrue);
      expect(MobileRole.isAllowed('sso_responsible'), isFalse);
      expect(MobileRole.isAllowed('technician'), isFalse);
    });

    test('una cuenta WORKER entra como operario sin consultar la membresía', () async {
      SharedPreferences.setMockInitialValues({});
      await SessionStore.save(token: 't', name: 'Ana', email: 'ana@quantumdyn.com', role: 'worker', userId: 12);

      expect(await AuthFacade.refreshSegment(), UserSegment.operator);
      expect(await SessionStore.segment(), 'operator');
    });
  });
}
