import 'package:flutter/widgets.dart';

import '../screens/etapa3/alert_history_screen.dart';
import '../screens/etapa3/dashboard_overview_screen.dart';
import '../screens/etapa3/empty_state_screen.dart';
import '../screens/etapa3/monitor_screen.dart';
import '../screens/etapa3/sensor_monitoring_detail_screen.dart';
import '../screens/etapa3/system_settings_screen.dart';

class Etapa3Routes {
  static const String alertHistory = '/etapa3/alert-history';
  static const String dashboardOverview = '/etapa3/dashboard-overview';
  static const String emptyState = '/etapa3/empty-state';
  static const String monitor = '/etapa3/monitor';
  static const String sensorMonitoringDetail =
      '/etapa3/sensor-monitoring-detail';
  static const String systemSettings = '/etapa3/system-settings';

  static Map<String, WidgetBuilder> get routes => {
    alertHistory: (context) => const AlertHistoryScreen(),
    dashboardOverview: (context) => const DashboardOverviewScreen(),
    emptyState: (context) => const EmptyStateScreen(),
    monitor: (context) => const MonitorScreen(),
    sensorMonitoringDetail: (context) => const SensorMonitoringDetailScreen(),
    systemSettings: (context) => const SystemSettingsScreen(),
  };
}
