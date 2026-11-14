import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emsafe_app/screens/etapa3/etapa3_components.dart';

void main() {
  testWidgets('las tarjetas no se desbordan en pantallas estrechas',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget tile(String v) => MetricTile(
          icon: Icons.flag_outlined,
          label: 'Acumulada',
          value: v,
          caption: 'uT*s',
          accent: Colors.blue,
        );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile('123456789')),
                const SizedBox(width: 12),
                Expanded(child: tile('12.4k')),
              ],
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
