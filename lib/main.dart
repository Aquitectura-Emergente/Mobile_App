import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'routes/etapa2_routes.dart';
import 'services/app_i18n.dart';
import 'services/app_navigator.dart';
import 'services/app_settings_store.dart';
import 'services/onboarding_flow_store.dart';
import 'contexts/iam/infrastructure/session_store.dart';
import 'contexts/devicemanagement/infrastructure/realtime_service.dart';
import 'theme/app_theme.dart';
import 'routes/home_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSettingsStore.init();
  I18n.init();

  // Already authenticated → straight to the home of their segment.
  // Otherwise: returning user (account created) → login; brand-new user → splash.
  final String initialRoute;
  if (await SessionStore.isLoggedIn()) {
    // Con el bloqueo biométrico activado, se desbloquea antes de entrar.
    initialRoute = AppSettingsStore.biometricLock
        ? Etapa2Routes.faceIdAuthentication
        : await storedHomeRoute();
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
    );
  }
}
