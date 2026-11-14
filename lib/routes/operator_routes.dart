import 'package:flutter/widgets.dart';

import '../screens/operator/operator_alerts_screen.dart';
import '../screens/operator/operator_exposure_screen.dart';
import '../screens/operator/operator_history_screen.dart';
import '../screens/operator/operator_readings_screen.dart';

class OperatorRoutes {
  static const String exposure = '/operator/exposure';
  static const String readings = '/operator/readings';
  static const String history = '/operator/history';
  static const String alerts = '/operator/alerts';

  static Map<String, WidgetBuilder> get routes => {
        exposure: (context) => const OperatorExposureScreen(),
        readings: (context) => const OperatorReadingsScreen(),
        history: (context) => const OperatorHistoryScreen(),
        alerts: (context) => const OperatorAlertsScreen(),
      };
}
