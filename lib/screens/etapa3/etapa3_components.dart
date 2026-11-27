import 'package:flutter/material.dart';

import '../../contexts/iam/infrastructure/session_store.dart';
import '../../design_system/design_system.dart';
import '../../routes/etapa3_routes.dart';
import '../../routes/operator_routes.dart';
import '../../services/app_i18n.dart';

/// Colores del tema oscuro de la app, tomados de los tokens del sistema de diseño.
/// Se mantiene como alias para pantallas que pintan fuera de un BuildContext.
class Etapa3Palette {
  static const bg = Color(0xFF0D0F13); // emsDark.bg
  static const panel = Color(0xFF14171C); // emsDark.surface
  static const panelSoft = Color(0xFF1A1E24); // emsDark.surfaceRaised
  static const stroke = Color(0xFF272C34); // emsDark.border
  static const cyan = Color(0xFF9C96FF); // emsDark.primary (interacción)
  static const blue = Color(0xFF7DB2E8); // emsDark.info
  static const text = Color(0xFFECEEF1); // emsDark.text
  static const muted = Color(0xFFA6ADB9); // emsDark.textSecondary
  static const quiet = Color(0xFF868E9C); // emsDark.textTertiary
  static const green = Color(0xFF3DB878); // emsDark.safeSignal
  static const amber = Color(0xFFE8B21C); // emsDark.warningSignal
  static const red = Color(0xFFF0544A); // emsDark.dangerSignal
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

/// Indicador de carga dentro del shell.
class Etapa3Loading extends StatelessWidget {
  const Etapa3Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: EmsSpace.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmsSkeleton(height: 220, radius: EmsRadius.md),
          SizedBox(height: EmsSpace.s5),
          EmsSkeleton(width: 160, height: 14),
          SizedBox(height: EmsSpace.s3),
          EmsSkeleton(height: 88, radius: EmsRadius.md),
        ],
      ),
    );
  }
}

/// Error con reintento dentro del shell.
class Etapa3Error extends StatelessWidget {
  const Etapa3Error({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: EmsSpace.s8),
      child: EmsPanel(
        child: EmsEmptyState(
          kind: EmsEmptyKind.offline,
          title: message,
          action: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 18),
            label: Text(tr('common_retry')),
          ),
        ),
      ),
    );
  }
}

/// Estructura de las pantallas principales: encabezado editorial, contenido y
/// barra de navegación inferior.
class Etapa3Shell extends StatelessWidget {
  const Etapa3Shell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.selectedIndex = 0,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final int selectedIndex;

  /// Deslizar hacia abajo para recargar.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    // Las pestañas se reemplazan entre sí, así que "atrás" en una pestaña
    // secundaria saldría de la app: primero vuelve a la pestaña principal.
    final atRoot = !Navigator.of(context).canPop();
    return PopScope(
      canPop: !atRoot || selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Stage3BottomNav.goToTab(context, 0);
      },
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ems.bg,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s4, EmsSpace.s5, 0),
                  child: _StageHeader(title: title, trailing: trailing),
                ),
                Expanded(child: _body(context)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Stage3BottomNav(selectedIndex: selectedIndex),
    );
  }
}

extension on Etapa3Shell {
  Widget _body(BuildContext context) {
    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s5, EmsSpace.s6, EmsSpace.s8),
      child: child,
    );
    if (onRefresh == null) return scroll;
    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: context.ems.primary,
      backgroundColor: context.ems.surface,
      child: scroll,
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const EmsBrandMark(size: 22),
            const SizedBox(width: EmsSpace.s3),
            Text('EMSAFE', style: context.type.eyebrow.copyWith(fontSize: 11)),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: EmsSpace.s4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.type.h1.copyWith(fontSize: 28, height: 1.1),
        ),
        const SizedBox(height: EmsSpace.s4),
        const EmsScaleRule(),
      ],
    );
  }
}

/// Lectura compacta (icono, valor mono, etiqueta y nota).
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
    final c = context.ems;
    return Container(
      padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s5, EmsSpace.s4, EmsSpace.s5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(EmsRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.eyebrow.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: EmsSpace.s4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: context.type.metricMd.copyWith(fontSize: 24)),
          ),
          if (caption != null) ...[
            const SizedBox(height: EmsSpace.s2),
            Text(caption!, style: context.type.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// Barra de navegación inferior (cromo grafito, indicador superior en el ítem activo).
class Stage3BottomNav extends StatelessWidget {
  const Stage3BottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return _buildBar(context, _items());
  }

  static List<(IconData, String, String)> _items() =>
      SessionStore.isOperator ? _operatorItems() : _homeItems();

  /// Cambio instantáneo a la pestaña [index].
  static void goToTab(BuildContext context, int index) {
    final route = _items()[index].$3;
    final builder = Etapa3Routes.routes[route] ?? OperatorRoutes.routes[route]!;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      settings: RouteSettings(name: route),
      pageBuilder: (ctx, _, _) => builder(ctx),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ));
  }

  // El operario no tiene sensores ni enchufe: su barra es de exposición.
  static List<(IconData, String, String)> _operatorItems() => [
        (PhosphorIconsRegular.gauge, tr('nav_exposure'), OperatorRoutes.exposure),
        (PhosphorIconsRegular.chartLine, tr('nav_shift'), OperatorRoutes.readings),
        (PhosphorIconsRegular.clockCounterClockwise, tr('nav_history'), OperatorRoutes.history),
        (PhosphorIconsRegular.bell, tr('nav_alerts'), OperatorRoutes.alerts),
        (PhosphorIconsRegular.gearSix, tr('nav_settings'), Etapa3Routes.systemSettings),
      ];

  static List<(IconData, String, String)> _homeItems() => [
        (PhosphorIconsRegular.squaresFour, tr('nav_home'), Etapa3Routes.dashboardOverview),
        (PhosphorIconsRegular.broadcast, tr('nav_monitor'), Etapa3Routes.monitor),
        (PhosphorIconsRegular.lightbulb, tr('nav_vitals'), Etapa3Routes.sensorMonitoringDetail),
        (PhosphorIconsRegular.bell, tr('nav_alerts'), Etapa3Routes.alertHistory),
        (PhosphorIconsRegular.gearSix, tr('nav_settings'), Etapa3Routes.systemSettings),
      ];

  Widget _buildBar(BuildContext context, List<(IconData, String, String)> items) {
    final c = context.ems;
    return Material(
      color: c.chrome,
      child: SafeArea(
        top: false,
        child: Container(
          height: EmsSize.bottomNav,
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.chromeBorder))),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _BottomNavItem(
                    icon: items[index].$1,
                    label: items[index].$2,
                    selected: selectedIndex == index,
                    onTap: () {
                      if (selectedIndex != index) goToTab(context, index);
                    },
                  ),
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
    final c = context.ems;
    final color = selected ? c.chromeText : c.chromeTextMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: EmsDuration.base,
              top: 0,
              left: selected ? 14 : 40,
              right: selected ? 14 : 40,
              height: EmsBorder.rail,
              child: AnimatedOpacity(
                duration: EmsDuration.base,
                opacity: selected ? 1 : 0,
                child: Container(color: c.chromeAccent),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: selected ? c.chromeAccent : color, size: 22),
                  const SizedBox(height: EmsSpace.s2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.caption.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
