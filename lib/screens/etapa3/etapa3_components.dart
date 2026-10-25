import 'dart:ui';

import 'package:flutter/material.dart';

import '../../routes/etapa3_routes.dart';
import '../../services/app_i18n.dart';

class Etapa3Palette {
  static const bg = Color(0xFF10131B);
  static const panel = Color(0xFF1D1F28);
  static const panelSoft = Color.fromRGBO(29, 31, 40, 0.72);
  static const stroke = Color.fromRGBO(66, 70, 85, 0.32);
  static const cyan = Color(0xFF65DAFF);
  static const blue = Color(0xFFB2C5FF);
  static const text = Color(0xFFE1E2EE);
  static const muted = Color(0xFFC2C6D8);
  static const quiet = Color(0xFF8C90A1);
  static const green = Color(0xFF2EA043);
  static const amber = Color(0xFFFFC857);
  static const red = Color(0xFFFF5B6E);
}

/// Maps a backend radiation level ("safe" | "caution" | "danger") to a color.
Color etapa3LevelColor(String? level) {
  switch (level) {
    case 'danger':
      return Etapa3Palette.red;
    case 'caution':
      return Etapa3Palette.amber;
    case 'safe':
      return Etapa3Palette.green;
    default:
      return Etapa3Palette.cyan;
  }
}

/// Uppercase label for a backend radiation level.
String etapa3LevelLabel(String? level) {
  switch (level) {
    case 'danger':
      return 'DANGER';
    case 'caution':
      return 'CAUTION';
    case 'safe':
      return 'SAFE';
    default:
      return (level ?? 'UNKNOWN').toUpperCase();
  }
}

/// Formats a nullable reading value for display.
String etapa3Num(double? value, {int decimals = 2}) {
  if (value == null) return '--';
  return value.toStringAsFixed(decimals);
}

/// Parses a backend ISO timestamp (LocalDateTime, no zone) as a local DateTime.
DateTime? etapa3ParseTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  return DateTime.tryParse(iso)?.toLocal();
}

/// Local time-of-day for an ISO timestamp, e.g. "14:37". Falls back to
/// [fallbackDate] (a plain date string) when no timestamp is available.
String etapa3TimeOfDay(String? iso, {String? fallbackDate}) {
  final dt = etapa3ParseTime(iso);
  if (dt == null) return fallbackDate ?? '--';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Human "time ago" for an ISO timestamp: "ahora mismo", "hace 36 min",
/// "hace 2 h", "hace 3 d" (localized). Falls back to [fallbackDate].
String etapa3TimeAgo(String? iso, {String? fallbackDate}) {
  final dt = etapa3ParseTime(iso);
  if (dt == null) return fallbackDate ?? '--';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return tr('time_justNow');
  final String n;
  final String u;
  if (diff.inMinutes < 60) {
    n = '${diff.inMinutes}';
    u = 'min';
  } else if (diff.inHours < 24) {
    n = '${diff.inHours}';
    u = 'h';
  } else {
    n = '${diff.inDays}';
    u = 'd';
  }
  return tr('time_ago_fmt').replaceAll('{n}', n).replaceAll('{u}', u);
}

/// Unit shown next to radiation values across the app (microtesla, magnetic field).
const String etapa3Unit = 'µT';

/// Safe limit in µT (danger threshold, ICNIRP 50 Hz reference — same as backend/edge).
const double etapa3SafetyThreshold = 200;

/// Centered loading spinner used inside Etapa3Shell while data loads.
class Etapa3Loading extends StatelessWidget {
  const Etapa3Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Etapa3Palette.cyan),
        ),
      ),
    );
  }
}

/// Error panel with a retry button, used inside Etapa3Shell on load failure.
class Etapa3Error extends StatelessWidget {
  const Etapa3Error({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: GlassPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: Etapa3Palette.red, size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Etapa3Palette.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Etapa3Palette.cyan,
                side: const BorderSide(color: Etapa3Palette.stroke),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class Etapa3Shell extends StatelessWidget {
  const Etapa3Shell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.selectedIndex = 0,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Etapa3Palette.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                      child: _StageHeader(
                        title: title,
                        trailing: trailing,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                        child: child,
                      ),
                    ),
                    Stage3BottomNav(selectedIndex: selectedIndex),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(178, 197, 255, 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color.fromRGBO(178, 197, 255, 0.2)),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Etapa3Palette.blue,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          // Header shows only the title — subtitle descriptions were removed app-wide.
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Etapa3Palette.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 8,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Etapa3Palette.panelSoft,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Etapa3Palette.stroke),
          ),
          child: child,
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.circle, color: color, size: icon == null ? 8 : 14),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Etapa3Palette.quiet,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Etapa3Palette.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Etapa3Palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              style: const TextStyle(
                color: Etapa3Palette.quiet,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Stage3BottomNav extends StatelessWidget {
  const Stage3BottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_outlined, tr('nav_home'), Etapa3Routes.dashboardOverview),
      (Icons.sensors, tr('nav_monitor'), Etapa3Routes.monitor),
      (
        Icons.monitor_heart_outlined,
        tr('nav_vitals'),
        Etapa3Routes.sensorMonitoringDetail,
      ),
      (Icons.notifications_none, tr('nav_alerts'), Etapa3Routes.alertHistory),
      (Icons.settings_outlined, tr('nav_settings'), Etapa3Routes.systemSettings),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(16, 19, 27, 0.88),
            border: Border(top: BorderSide(color: Etapa3Palette.stroke)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var index = 0; index < items.length; index++)
                _BottomNavItem(
                  icon: items[index].$1,
                  label: items[index].$2,
                  selected: selectedIndex == index,
                  onTap: () {
                    if (selectedIndex == index) return;
                    final route = items[index].$3;
                    final builder = Etapa3Routes.routes[route]!;
                    // Instant swap (no slide) between tabs.
                    Navigator.of(context).pushReplacement(PageRouteBuilder(
                      settings: RouteSettings(name: route),
                      pageBuilder: (ctx, _, _) => builder(ctx),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Etapa3Palette.cyan : Etapa3Palette.quiet;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
