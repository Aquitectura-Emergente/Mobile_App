import 'package:flutter/material.dart';

import '../../services/app_i18n.dart';
import 'etapa3_components.dart';

/// "Vitals" tab — purely informational electromagnetic-health guidance.
///
/// By design this screen shows NO live sensor data or alarm level: only
/// educational content (what exposure levels mean, risk categories and health
/// recommendations). Live measurements live only in Home and Monitor.
class SensorMonitoringDetailScreen extends StatelessWidget {
  const SensorMonitoringDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('vit_title'),
      subtitle: tr('vit_subtitle'),
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(tr('vit_levels')),
          const SizedBox(height: 10),
          _RiskLevelRow(
            color: Etapa3Palette.green,
            icon: Icons.check_circle_outline,
            label: tr('vit_lvLow'),
            title: tr('vit_riskLowTitle'),
            description: tr('vit_riskLowDesc'),
          ),
          const SizedBox(height: 10),
          _RiskLevelRow(
            color: Etapa3Palette.amber,
            icon: Icons.shield_outlined,
            label: tr('vit_lvMid'),
            title: tr('vit_riskModTitle'),
            description: tr('vit_riskModDesc'),
          ),
          const SizedBox(height: 10),
          _RiskLevelRow(
            color: Etapa3Palette.red,
            icon: Icons.warning_amber_rounded,
            label: tr('vit_lvHigh'),
            title: tr('vit_riskHighTitle'),
            description: tr('vit_riskHighDesc'),
          ),
          const SizedBox(height: 20),
          SectionLabel(tr('vit_categories')),
          const SizedBox(height: 10),
          _CategoryTile(
            icon: Icons.bedtime_outlined,
            accent: Etapa3Palette.blue,
            title: tr('vit_catSleep'),
            description: tr('vit_catSleepDesc'),
          ),
          const SizedBox(height: 10),
          _CategoryTile(
            icon: Icons.phone_android_outlined,
            accent: Etapa3Palette.cyan,
            title: tr('vit_catDevices'),
            description: tr('vit_catDevicesDesc'),
          ),
          const SizedBox(height: 10),
          _CategoryTile(
            icon: Icons.router_outlined,
            accent: Etapa3Palette.amber,
            title: tr('vit_catRouters'),
            description: tr('vit_catRoutersDesc'),
          ),
          const SizedBox(height: 10),
          _CategoryTile(
            icon: Icons.location_on_outlined,
            accent: Etapa3Palette.red,
            title: tr('vit_catZones'),
            description: tr('vit_catZonesDesc'),
          ),
          const SizedBox(height: 20),
          SectionLabel(tr('vit_tips')),
          const SizedBox(height: 10),
          _TipTile(
            impact: tr('vit_impactHigh'),
            color: Etapa3Palette.red,
            action: tr('vit_tip1'),
            reason: tr('vit_tip1Why'),
          ),
          const SizedBox(height: 10),
          _TipTile(
            impact: tr('vit_impactHigh'),
            color: Etapa3Palette.red,
            action: tr('vit_tip2'),
            reason: tr('vit_tip2Why'),
          ),
          const SizedBox(height: 10),
          _TipTile(
            impact: tr('vit_impactMid'),
            color: Etapa3Palette.amber,
            action: tr('vit_tip3'),
            reason: tr('vit_tip3Why'),
          ),
          const SizedBox(height: 10),
          _TipTile(
            impact: tr('vit_impactMid'),
            color: Etapa3Palette.amber,
            action: tr('vit_tip4'),
            reason: tr('vit_tip4Why'),
          ),
          const SizedBox(height: 10),
          _TipTile(
            impact: tr('vit_impactLow'),
            color: Etapa3Palette.green,
            action: tr('vit_tip5'),
            reason: tr('vit_tip5Why'),
          ),
        ],
      ),
    );
  }
}

/// Static educational row explaining what a given exposure level means.
class _RiskLevelRow extends StatelessWidget {
  const _RiskLevelRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.title,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusPill(label: label, color: color),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({
    required this.impact,
    required this.color,
    required this.action,
    required this.reason,
  });

  final String impact;
  final Color color;
  final String action;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(label: impact, color: color),
          const SizedBox(height: 10),
          Text(
            action,
            style: const TextStyle(
              color: Etapa3Palette.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            reason,
            style: const TextStyle(
              color: Etapa3Palette.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
