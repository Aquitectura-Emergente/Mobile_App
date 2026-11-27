import 'package:flutter/material.dart';

import '../../contexts/radiationmonitoring/domain/radiation_level.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import 'etapa3_components.dart';

/// Guía de exposición del hogar: qué significa cada nivel (con los mismos
/// umbrales que aplica el sistema), fuentes habituales y hábitos útiles.
/// Contenido informativo: no muestra mediciones.
class SensorMonitoringDetailScreen extends StatelessWidget {
  const SensorMonitoringDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final levels = [
      (RadiationLevel.safe, EmsTone.safe, PhosphorIconsRegular.checkCircle, tr('vit_riskLowTitle'), tr('vit_riskLowDesc'), '< ${cautionThresholdUT.toStringAsFixed(0)}'),
      (RadiationLevel.caution, EmsTone.warning, PhosphorIconsRegular.warning, tr('vit_riskModTitle'), tr('vit_riskModDesc'), '${cautionThresholdUT.toStringAsFixed(0)}–${dangerThresholdUT.toStringAsFixed(0)}'),
      (RadiationLevel.danger, EmsTone.danger, PhosphorIconsRegular.warningOctagon, tr('vit_riskHighTitle'), tr('vit_riskHighDesc'), '≥ ${dangerThresholdUT.toStringAsFixed(0)}'),
    ];
    final sources = [
      (PhosphorIconsRegular.moon, tr('vit_catSleep'), tr('vit_catSleepDesc')),
      (PhosphorIconsRegular.deviceMobile, tr('vit_catDevices'), tr('vit_catDevicesDesc')),
      (PhosphorIconsRegular.broadcast, tr('vit_catRouters'), tr('vit_catRoutersDesc')),
      (PhosphorIconsRegular.mapPin, tr('vit_catZones'), tr('vit_catZonesDesc')),
    ];
    final tips = [
      (3, tr('vit_tip1'), tr('vit_tip1Why')),
      (3, tr('vit_tip2'), tr('vit_tip2Why')),
      (2, tr('vit_tip3'), tr('vit_tip3Why')),
      (2, tr('vit_tip4'), tr('vit_tip4Why')),
      (1, tr('vit_tip5'), tr('vit_tip5Why')),
    ];

    return Etapa3Shell(
      title: tr('nav_vitals'),
      subtitle: tr('vit_subtitle'),
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('vit_subtitle'), style: context.type.bodyLg.copyWith(color: c.textSecondary)),
          const SizedBox(height: EmsSpace.s7),
          EmsSectionHeader(index: '01', title: tr('vit_levels'), trailing: Text('µT', style: context.type.monoSm)),
          Container(
            decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < levels.length; i++) ...[
                  _LevelRow(tone: levels[i].$2, icon: levels[i].$3, title: levels[i].$4, description: levels[i].$5, range: levels[i].$6),
                  if (i < levels.length - 1) Divider(height: 1, color: c.borderSubtle),
                ],
              ],
            ),
          ),
          const SizedBox(height: EmsSpace.s3),
          Text(tr('m_guideThresholds'), style: context.type.caption),
          const SizedBox(height: EmsSpace.s8),
          EmsSectionHeader(index: '02', title: tr('vit_categories')),
          EmsGroup(children: [for (final s in sources) EmsRow(icon: s.$1, title: s.$2, subtitle: s.$3)]),
          const SizedBox(height: EmsSpace.s8),
          EmsSectionHeader(index: '03', title: tr('vit_tips')),
          for (var i = 0; i < tips.length; i++) ...[
            _Tip(n: i + 1, impact: tips[i].$1, action: tips[i].$2, reason: tips[i].$3),
            const SizedBox(height: EmsSpace.s3),
          ],
          const SizedBox(height: EmsSpace.s5),
          Text(tr('ds_notMetrology'), textAlign: TextAlign.center, style: context.type.caption),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.tone, required this.icon, required this.title, required this.description, required this.range});

  final EmsTone tone;
  final IconData icon;
  final String title;
  final String description;
  final String range;

  @override
  Widget build(BuildContext context) {
    final t = emsTone(context, tone);
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: t.signal, width: EmsBorder.rail))),
      padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s5, EmsSpace.s5, EmsSpace.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: t.fg, size: 22),
          const SizedBox(width: EmsSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.type.h4),
                const SizedBox(height: EmsSpace.s2),
                Text(description, style: context.type.bodySm),
              ],
            ),
          ),
          const SizedBox(width: EmsSpace.s3),
          Text(range, style: context.type.mono.copyWith(color: t.fg)),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.n, required this.impact, required this.action, required this.reason});

  final int n;
  final int impact;
  final String action;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final impactLabel = switch (impact) { 3 => tr('vit_impactHigh'), 2 => tr('vit_impactMid'), _ => tr('vit_impactLow') };
    return EmsPanel(
      padding: const EdgeInsets.all(EmsSpace.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.toString().padLeft(2, '0'), style: context.type.metricMd.copyWith(color: c.primary, fontSize: 18)),
          const SizedBox(width: EmsSpace.s5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: context.type.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: EmsSpace.s2),
                Text(reason, style: context.type.bodySm),
                const SizedBox(height: EmsSpace.s3),
                Row(
                  children: [
                    for (var i = 1; i <= 3; i++) ...[
                      Container(width: 14, height: 4, color: i <= impact ? c.primary : c.border),
                      const SizedBox(width: 3),
                    ],
                    const SizedBox(width: EmsSpace.s3),
                    Text(impactLabel, style: context.type.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
