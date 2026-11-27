import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';

/// Cómo empieza el monitoreo en EMSafe, tal como funciona el sistema: la
/// cuenta la aprueba un administrador y los sensores y el enchufe los instala
/// y registra un técnico. La app no empareja equipos por su cuenta.
class SetupGuideContent extends StatelessWidget {
  const SetupGuideContent({super.key, this.highlight = 0});

  /// Paso destacado (0 = ninguno).
  final int highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final steps = [
      (PhosphorIconsRegular.userPlus, tr('m_setup1'), tr('m_setup1Msg')),
      (PhosphorIconsRegular.sealCheck, tr('m_setup2'), tr('m_setup2Msg')),
      (PhosphorIconsRegular.wrench, tr('m_setup3'), tr('m_setup3Msg')),
      (PhosphorIconsRegular.chartBar, tr('m_setup4'), tr('m_setup4Msg')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: highlight == i + 1 ? c.primary : c.surface,
                        borderRadius: BorderRadius.circular(EmsRadius.sm),
                        border: Border.all(color: highlight == i + 1 ? c.primary : c.borderStrong),
                      ),
                      child: Icon(steps[i].$1, size: 18, color: highlight == i + 1 ? c.onPrimary : c.textSecondary),
                    ),
                    if (i < steps.length - 1) Expanded(child: Container(width: 1, color: c.borderStrong)),
                  ],
                ),
                const SizedBox(width: EmsSpace.s5),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < steps.length - 1 ? EmsSpace.s7 : 0, top: EmsSpace.s1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${(i + 1).toString().padLeft(2, '0')} · ${steps[i].$2}', style: context.type.h4),
                        const SizedBox(height: EmsSpace.s2),
                        Text(steps[i].$3, style: context.type.bodySm),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
