import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emsafe_app/contexts/devicemanagement/infrastructure/realtime_service.dart';
import 'package:emsafe_app/contexts/iam/infrastructure/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cerrar la sesión avisa a quien tenga algo abierto', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    void listener() => calls++;
    SessionStore.addClearListener(listener);
    SessionStore.addClearListener(listener);
    await SessionStore.clear();
    expect(calls, 1);
  });

  test('cerrar la sesión limpia el aviso de peligro pendiente', () async {
    SharedPreferences.setMockInitialValues({});
    RealtimeService.dangerReading.value = {'level': 'DANGER'};
    SessionStore.addClearListener(RealtimeService.disconnect);
    await SessionStore.clear();
    expect(RealtimeService.dangerReading.value, isNull);
  });

  group('conexión en vivo', () {
    test('no se reutiliza la de otra cuenta', () {
      expect(RealtimeService.needsNewConnection(connectedUserId: 14, currentUserId: 15), isTrue);
      expect(RealtimeService.needsNewConnection(connectedUserId: 14, currentUserId: null), isTrue);
    });

    test('se reutiliza la de la misma cuenta o si no había', () {
      expect(RealtimeService.needsNewConnection(connectedUserId: 14, currentUserId: 14), isFalse);
      expect(RealtimeService.needsNewConnection(connectedUserId: null, currentUserId: 14), isFalse);
    });
  });
}
