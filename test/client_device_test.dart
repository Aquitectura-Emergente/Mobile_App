import 'package:flutter_test/flutter_test.dart';

import 'package:emsafe_app/contexts/iottelemetry/domain/client_device.dart';

ClientDevice device({String? plug, String? desiredPlug, String status = 'active'}) =>
    ClientDevice(
      id: 1,
      name: 'Sensor EM 01',
      type: 'Sensor',
      status: status,
      readingsCount: 10,
      plug: plug,
      desiredPlug: desiredPlug,
    );

void main() {
  group('control del rele', () {
    test('hay orden pendiente cuando lo pedido difiere de lo reportado', () {
      expect(device(plug: 'ON', desiredPlug: 'OFF').plugOrderPending, isTrue);
    });

    test('no hay orden pendiente cuando coinciden', () {
      expect(device(plug: 'OFF', desiredPlug: 'OFF').plugOrderPending, isFalse);
    });

    test('sin orden del usuario no hay nada pendiente', () {
      expect(device(plug: 'ON').plugOrderPending, isFalse);
    });

    test('el estado efectivo prioriza la orden del usuario', () {
      // El rele es asincrono: hasta que el edge recoja la orden, la interfaz
      // debe mostrar lo que el usuario pidio.
      expect(device(plug: 'ON', desiredPlug: 'OFF').effectivePlug, 'OFF');
    });

    test('sin orden, el estado efectivo es el que reporto el dispositivo', () {
      expect(device(plug: 'ON').effectivePlug, 'ON');
    });

    test('toggle invierte el estado', () {
      expect(PlugState.toggle('ON'), 'OFF');
      expect(PlugState.toggle('OFF'), 'ON');
    });

    test('toggle sin estado conocido enciende', () {
      expect(PlugState.toggle(null), 'ON');
    });
  });

  group('estado del sensor', () {
    test('"active" aqui significa reportando, no cuenta habilitada', () {
      expect(device(status: 'active').isReporting, isTrue);
      expect(device(status: 'collecting').isReporting, isTrue);
      expect(device(status: 'unregistered').isReporting, isFalse);
      expect(device(status: 'in-maintenance').isReporting, isFalse);
    });
  });
}
