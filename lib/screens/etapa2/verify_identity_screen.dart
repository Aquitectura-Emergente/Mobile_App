import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_i18n.dart';
import '../shared/auth_scaffold.dart';
import '../shared/setup_guide.dart';

/// Verificación de la cuenta. En EMSafe la identidad de una cuenta nueva la
/// verifica un administrador al aprobarla (no hay código por SMS o correo):
/// esta pantalla explica ese estado y qué viene después.
class VerifyIdentityScreen extends StatelessWidget {
  const VerifyIdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: tr('m_verifyEyebrow'),
      title: tr('m_verifyTitle'),
      intro: tr('m_verifyIntro'),
      bottom: EmsButton(
        label: tr('m_goToLogin'),
        icon: PhosphorIconsRegular.signIn,
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Etapa2Routes.login, (r) => false),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsGroup(
            children: [
              EmsRow(icon: PhosphorIconsRegular.hourglassMedium, iconTone: EmsTone.warning, title: tr('m_statePending'), subtitle: tr('m_statePendingMsg')),
              EmsRow(icon: PhosphorIconsRegular.sealCheck, iconTone: EmsTone.safe, title: tr('m_stateActive'), subtitle: tr('m_stateActiveMsg')),
              EmsRow(icon: PhosphorIconsRegular.lockKey, iconTone: EmsTone.neutral, title: tr('m_stateInactive'), subtitle: tr('m_stateInactiveMsg')),
            ],
          ),
          const SizedBox(height: EmsSpace.s8),
          EmsSectionHeader(title: tr('m_whatNext')),
          const SetupGuideContent(highlight: 2),
        ],
      ),
    );
  }
}
