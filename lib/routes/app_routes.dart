import 'package:flutter/widgets.dart';

import '../screens/etapa1/screen_1_splash_em_safe_updated.dart';
import '../screens/etapa1/screen_1_splash_official_brand.dart';
import '../screens/etapa1/screen_2_onboarding_smart_alerts.dart';
import '../screens/etapa1/screen_3_onboarding_astra_ai_assistant.dart';
import '../screens/etapa1/screen_4_onboarding_smart_home_protection.dart';
import '../screens/etapa1/screen_6_pairing_sensors.dart';

import '../screens/etapa1/screen_8_onboarding_final_step.dart';

import 'etapa2_routes.dart';
import 'etapa3_routes.dart';
import 'operator_routes.dart';

class AppRoutes {
  static const String splash1 = '/etapa1/screen1/splash_official_brand';
  static const String splashUpdated = '/etapa1/screen1/splash_em_safe_updated';
  static const String onboardingSmartAlerts =
      '/etapa1/screen2/onboarding_smart_alerts';
  static const String onboardingAstraAssistant =
      '/etapa1/screen3/onboarding_astra_ai_assistant';
  static const String onboardingSmartHomeProtection =
      '/etapa1/screen4/onboarding_smart_home_protection';
  static const String pairingSensors = '/etapa1/screen6/pairing_sensors';
  static const String pairYourSensor = '/etapa1/screen7/pair_your_sensor';
  static const String onboardingFinalStep =
      '/etapa1/screen8/onboarding_final_step';

  static Map<String, WidgetBuilder> get routes => {
    splash1: (context) => const SplashOfficialBrandScreen(),
    splashUpdated: (context) => const SplashEmSafeUpdatedScreen(),
    onboardingSmartAlerts: (context) => const OnboardingSmartAlertsScreen(),
    onboardingAstraAssistant: (context) =>
        const OnboardingAstraAIAssistantScreen(),
    onboardingSmartHomeProtection: (context) =>
        const OnboardingSmartHomeProtectionScreen(),
    pairingSensors: (context) => const PairingSensorsScreen(),
    pairYourSensor: (context) => const PairingSensorsScreen(),
    onboardingFinalStep: (context) => const OnboardingFinalStepScreen(),
    ...Etapa2Routes.routes,
    ...Etapa3Routes.routes,
    ...OperatorRoutes.routes,
  };
}
