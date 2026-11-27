import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_i18n.dart';
import '../shared/auth_scaffold.dart';
import '../shared/setup_guide.dart';

/// Solicitud de alta enviada. La cuenta queda pendiente hasta que un
/// administrador la apruebe; hasta entonces el acceso se rechaza.
class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final email = ModalRoute.of(context)?.settings.arguments as String?;
    return AuthScaffold(
      showBack: false,
      eyebrow: tr('m_sentEyebrow'),
      title: tr('m_sentTitle'),
      intro: tr('m_sentIntro'),
      bottom: EmsButton(
        label: tr('m_goToLogin'),
        icon: PhosphorIconsRegular.signIn,
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Etapa2Routes.login, (r) => false),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsRailBox(
            color: c.safeSubtle,
            borderColor: c.safeBorder,
            railColor: c.safeSignal,
            radius: EmsRadius.md,
            padding: const EdgeInsets.all(EmsSpace.s5),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.checkCircle, color: c.safe, size: 28),
                const SizedBox(width: EmsSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('m_sentOk'), style: context.type.h4.copyWith(color: c.safe)),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(email, style: context.type.mono.copyWith(color: c.text)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EmsSpace.s5),
          EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.hourglassMedium, title: tr('m_pendingTitle'), message: tr('m_pendingMsg')),
          const SizedBox(height: EmsSpace.s8),
          EmsSectionHeader(title: tr('m_whatNext')),
          const SetupGuideContent(highlight: 2),
        ],
      ),
    );
  }
}
