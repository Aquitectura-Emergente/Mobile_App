import 'package:flutter/material.dart';

import '../../services/onboarding_flow_store.dart';
import 'register_screen.dart';

/// Paso de seguridad del alta. Sin datos previos, empieza por el primer paso.
class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      RegisterScreen(initialStep: OnboardingFlowStore.personalDetailsDraft == null ? 0 : 3);
}
