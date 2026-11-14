import 'package:flutter_test/flutter_test.dart';

import 'package:emsafe_app/contexts/devicemanagement/domain/client_device.dart';

ClientDevice device(
        {String? plug,
        String? desiredPlug,
        String status = 'active',
        String type = 'Sensor'}) =>
    ClientDevice(
      id: 1,
      name: 'Sensor EM 01',
      type: type,
      status: status,
      readingsCount: 10,
      plug: plug,
      desiredPlug: desiredPlug,
    );

void main() {
  group('control del rele', () {
    test('hay orden pendiente cuando lo pedido difiere de lo reportado', () {
      expect(device(plug: 'ON', desiredPlug: 'OFF').plugOrderPending, isTrue);
      expect(device(plug: 'ON', desiredPlug: 'OFF').pendingPlug, 'OFF');
    });

    test('no hay orden pendiente cuando coinciden', () {
      expect(device(plug: 'OFF', desiredPlug: 'OFF').plugOrderPending, isFalse);
      expect(device(plug: 'OFF', desiredPlug: 'OFF').pendingPlug, isNull);
    });

    test('sin orden del usuario no hay nada pendiente', () {
      expect(device(plug: 'ON', desiredPlug: 'ON').plugOrderPending, isFalse);
      expect(device(plug: 'ON').plugOrderPending, isFalse);
    });

    test('el estado mostrado es el real aunque haya una orden en curso', () {
      // Hasta que el Edge confirme, el relé sigue como estaba.
      expect(device(plug: 'ON', desiredPlug: 'OFF').realPlug, 'ON');
      expect(device(plug: 'ON', desiredPlug: 'OFF').isPlugOn, isTrue);
    });

    test('UNKNOWN no es un estado real', () {
      expect(device(plug: 'UNKNOWN').realPlug, isNull);
      expect(device(plug: 'UNKNOWN', desiredPlug: 'OFF').plugOrderPending, isTrue);
    });

    test('toggle invierte el estado', () {
      expect(PlugPower.toggle('ON'), 'OFF');
      expect(PlugPower.toggle('OFF'), 'ON');
    });

    test('toggle sin estado conocido enciende', () {
      expect(PlugPower.toggle(null), 'ON');
    });

    test('solo el tipo Plug es enchufe', () {
      expect(device().isPlug, isFalse);
      expect(device(type: 'Plug').isPlug, isTrue);
      expect(homePlugOf([device(), device(type: 'Plug')])?.type, 'Plug');
      expect(homePlugOf([device()]), isNull);
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
