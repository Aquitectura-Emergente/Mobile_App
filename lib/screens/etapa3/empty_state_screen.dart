import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../shared/setup_guide.dart';

/// Hogar sin sensores: explica cómo se instalan, sin simular emparejamientos.
class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmsPage(
      eyebrow: tr('m_noSensorsEyebrow'),
      title: tr('m_howInstall'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.info, message: tr('m_noDevicesMsg')),
          const SizedBox(height: EmsSpace.s7),
          const SetupGuideContent(highlight: 3),
        ],
      ),
    );
  }
}
