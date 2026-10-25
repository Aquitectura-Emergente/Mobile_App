import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'routes/etapa2_routes.dart';
import 'routes/etapa3_routes.dart';
import 'services/app_i18n.dart';
import 'services/app_navigator.dart';
import 'services/app_settings_store.dart';
import 'services/onboarding_flow_store.dart';
import 'contexts/iam/infrastructure/session_store.dart';
import 'contexts/iottelemetry/infrastructure/realtime_service.dart';
import 'theme/app_theme.dart';
import 'screens/etapa1/screen_7_pair_your_sensor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSettingsStore.init();
  I18n.init();

  // Already authenticated → go straight to the dashboard.
  // Otherwise: returning user (account created) → login; brand-new user → splash.
  final String initialRoute;
  if (await SessionStore.isLoggedIn()) {
    initialRoute = Etapa3Routes.dashboardOverview;
  } else if (await OnboardingFlowStore.hasCreatedAccount()) {
    initialRoute = Etapa2Routes.login;
  } else {
    initialRoute = AppRoutes.splash1;
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = AppRoutes.splash1});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      title: 'EmSafe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      initialRoute: initialRoute,
      // App-wide DANGER modal: pops "cut the power?" when one of the client's
      // own sensors reports a DANGER reading over the WebSocket.
      builder: (context, child) =>
          DangerAlertGate(child: child ?? const SizedBox.shrink()),
      routes: AppRoutes.routes,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.pairYourSensor) {
          return PageRouteBuilder(
            settings: settings,
            opaque: false, // Mantiene viva la pantalla anterior debajo
            pageBuilder: (context, _, _) => const PairYourSensorScreen(),
          );
        }

        // Fallback: deja que MaterialApp resuelva con los routes existentes.
        return null;
      },
    );
  }
}
