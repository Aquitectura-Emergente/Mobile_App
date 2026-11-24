import 'package:flutter_test/flutter_test.dart';
import 'package:emsafe_app/contexts/devicemanagement/application/plug_command_tracker.dart';
import 'package:emsafe_app/contexts/devicemanagement/domain/plug_status.dart';

PlugCommand command(String status) => PlugCommand(
      commandId: 'c-1',
      plugId: 'EMSafe-PLUG-01',
      action: 'OFF',
      status: status,
    );

PlugCommandTracker tracker(List<String> answers) {
  var i = 0;
  return PlugCommandTracker(
    fetch: (_) async => command(answers[i < answers.length ? i++ : answers.length - 1]),
    wait: (_) async {},
  );
}

void main() {
  group('orden al enchufe', () {
    test('lee la vista del backend', () {
      final c = PlugCommand.fromJson({
        'commandId': 'c-1',
        'plugId': 'EMSafe-PLUG-01',
        'action': 'off',
        'status': 'PENDING',
        'requestedAt': '2026-11-13T10:00:00Z',
      });
      expect(c.action, 'OFF');
      expect(c.isPending, isTrue);
    });

    test('NOT_APPLIED y SEND_FAILED son fallos', () {
      expect(command('NOT_APPLIED').hasFailed, isTrue);
      expect(command('SEND_FAILED').hasFailed, isTrue);
      expect(command('CONFIRMED').hasFailed, isFalse);
    });
  });

  group('estado real', () {
    test('expone la orden pendiente', () {
      final s = PlugStatus.fromJson({
        'plugId': 'EMSafe-PLUG-01',
        'state': 'ON',
        'source': 'USER',
        'lastCommand': {'commandId': 'c-1', 'plugId': 'EMSafe-PLUG-01', 'action': 'OFF', 'status': 'PENDING'},
      });
      expect(s.isOn, isTrue);
      expect(s.pendingCommand?.action, 'OFF');
    });

    test('UNKNOWN no es un estado conocido', () {
      expect(PlugStatus.fromJson({'plugId': 'p', 'state': 'UNKNOWN'}).isKnown, isFalse);
    });
  });

  group('seguimiento de la orden', () {
    test('confirma cuando el Edge responde', () async {
      expect(await tracker(['PENDING', 'CONFIRMED']).track(command('PENDING')),
          PlugOrderOutcome.confirmed);
    });

    test('informa el fallo', () async {
      expect(await tracker(['NOT_APPLIED']).track(command('PENDING')),
          PlugOrderOutcome.failed);
    });

    test('sin respuesta queda no confirmada', () async {
      expect(await tracker(['PENDING']).track(command('PENDING')),
          PlugOrderOutcome.unconfirmed);
    });

    test('un error de red no corta el seguimiento', () async {
      var calls = 0;
      final t = PlugCommandTracker(
        fetch: (_) async {
          calls++;
          if (calls == 1) throw Exception('sin red');
          return command('CONFIRMED');
        },
        wait: (_) async {},
      );
      expect(await t.track(command('PENDING')), PlugOrderOutcome.confirmed);
    });
  });
}
