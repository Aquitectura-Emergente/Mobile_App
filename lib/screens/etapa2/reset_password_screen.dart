import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_i18n.dart';
import '../shared/auth_scaffold.dart';

/// Recuperar el acceso. El backend no tiene restablecimiento por correo, así
/// que no se simula un envío: se explica cómo recuperar la cuenta de verdad.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: tr('m_resetEyebrow'),
      title: tr('m_resetTitle'),
      intro: tr('m_resetIntro'),
      bottom: EmsButton(
        label: tr('m_backToLogin'),
        icon: PhosphorIconsRegular.arrowLeft,
        kind: EmsButtonKind.secondary,
        onPressed: () => Navigator.of(context).canPop()
            ? Navigator.of(context).pop()
            : Navigator.of(context).pushReplacementNamed(Etapa2Routes.login),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsGroup(
            title: tr('m_resetHow'),
            children: [
              EmsRow(icon: PhosphorIconsRegular.house, title: tr('m_resetHome'), subtitle: tr('m_resetHomeMsg')),
              EmsRow(icon: PhosphorIconsRegular.hardHat, title: tr('m_resetOperator'), subtitle: tr('m_resetOperatorMsg')),
            ],
          ),
          const SizedBox(height: EmsSpace.s6),
          EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.lockKey, message: tr('m_resetKnown')),
          const SizedBox(height: EmsSpace.s4),
          EmsBanner(tone: EmsTone.warning, icon: PhosphorIconsRegular.timer, message: tr('m_resetLocked')),
        ],
      ),
    );
  }
}
