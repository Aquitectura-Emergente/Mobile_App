import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/iottelemetry/domain/client_device.dart';
import '../../contexts/iottelemetry/infrastructure/notification_service.dart';
import '../../contexts/iottelemetry/infrastructure/realtime_service.dart';
import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../contexts/radiationmonitoring/domain/client_dashboard.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'astra_chat_screen.dart';
import 'etapa3_components.dart';
import 'map_radiation_screen.dart';
import 'reports_screen.dart';

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() =>
      _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  late Future<ClientDashboard> _future;
  Timer? _liveDebounce;

  @override
  void initState() {
    super.initState();
    _future = MonitoringFacade.dashboard();
    // Live updates: refresh (debounced) whenever a reading arrives via STOMP.
    RealtimeService.ensureConnected();
    RealtimeService.readingTick.addListener(_onLiveReading);
    NotificationService.init();
  }

  @override
  void dispose() {
    _liveDebounce?.cancel();
    RealtimeService.readingTick.removeListener(_onLiveReading);
    super.dispose();
  }

  void _onLiveReading() {
    _liveDebounce?.cancel();
    _liveDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _reload();
    });
  }

  void _reload() {
    setState(() => _future = MonitoringFacade.dashboard());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClientDashboard>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final level = data?.level ?? 'safe';
        return Etapa3Shell(
          title: 'EMSAFE',
          subtitle: tr('dash_subtitle'),
          selectedIndex: 0,
          trailing: data == null
              ? null
              : StatusPill(
                  label: etapa3LevelLabel(level),
                  color: etapa3LevelColor(level),
                ),
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<ClientDashboard> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Etapa3Loading();
    }
    if (snapshot.hasError) {
      final msg = snapshot.error is ApiException
          ? (snapshot.error as ApiException).message
          : tr('dash_errLoad');
      return Etapa3Error(message: msg, onRetry: _reload);
    }

    final data = snapshot.data!;
    final color = etapa3LevelColor(data.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExposureHero(data: data),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return GridView.count(
              crossAxisCount: compact ? 1 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: compact ? 2.35 : 1.34,
              children: [
                MetricTile(
                  icon: Icons.show_chart,
                  label: tr('dash_average'),
                  value: etapa3Num(data.currentAverage),
                  caption: '$etapa3Unit ${tr('dash_avgCaption')}',
                  accent: Etapa3Palette.blue,
                ),
                MetricTile(
                  icon: Icons.trending_up,
                  label: tr('dash_peak'),
                  value: etapa3Num(data.maxValue),
                  caption: tr('dash_peakCaption'),
                  accent: color,
                ),
                MetricTile(
                  icon: Icons.sensors_outlined,
                  label: tr('dash_online'),
                  value: '${data.activeDeviceCount}/${data.deviceCount}',
                  caption: tr('dash_reporting'),
                  accent: Etapa3Palette.cyan,
                ),
                MetricTile(
                  icon: Icons.notifications_active_outlined,
                  label: tr('dash_alerts'),
                  value: data.alertCount.toString().padLeft(2, '0'),
                  caption: tr('dash_needReview'),
                  accent: data.alertCount > 0
                      ? Etapa3Palette.amber
                      : Etapa3Palette.green,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.bar_chart_rounded,
                label: tr('dash_qaReports'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.map_outlined,
                label: tr('dash_qaMap'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MapRadiationScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.auto_awesome,
                label: tr('dash_qaAstra'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AstraChatScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('dash_activeZones')),
        const SizedBox(height: 10),
        if (data.devices.isEmpty)
          GlassPanel(
            child: Text(
              tr('dash_noSensors'),
              style: const TextStyle(
                color: Etapa3Palette.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          )
        else
          for (final device in data.devices) ...[
            _ZoneRow(device: device),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 8),
        GlassPanel(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_graph, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.alertCount == 0
                          ? tr('dash_stable')
                          : '${data.alertCount} ${tr('dash_aboveSafe')}',
                      style: const TextStyle(
                        color: Etapa3Palette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.alertCount == 0
                          ? tr('dash_noSpikes')
                          : tr('dash_openAlerts'),
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
        ),
      ],
    );
  }
}

/// Shortcut card in the Home tab (Reports / Map / Astra assistant).
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Etapa3Palette.panelSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Etapa3Palette.stroke),
        ),
        child: Column(
          children: [
            Icon(icon, color: Etapa3Palette.cyan, size: 22),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Etapa3Palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExposureHero extends StatelessWidget {
  const _ExposureHero({required this.data});

  final ClientDashboard data;

  @override
  Widget build(BuildContext context) {
    final color = etapa3LevelColor(data.level);
    final double progress = data.safetyThreshold > 0
        ? (data.currentAverage / data.safetyThreshold).clamp(0.0, 1.0)
        : 0.0;

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          SizedBox(
            height: 238,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 238,
                  height: 238,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.24),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.22),
                      width: 14,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etapa3Num(data.currentAverage),
                      style: TextStyle(
                        color: color,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      etapa3Unit,
                      style: TextStyle(
                        color: Etapa3Palette.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            tr('dash_currentExposure'),
            style: const TextStyle(
              color: Etapa3Palette.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.level == 'safe'
                ? tr('dash_msgSafe')
                : data.level == 'caution'
                    ? tr('dash_msgCaution')
                    : tr('dash_msgDanger'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Etapa3Palette.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFF32343E),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.device});

  final ClientDevice device;

  @override
  Widget build(BuildContext context) {
    final color = etapa3LevelColor(device.latestLevel);
    final value = device.latestValue != null
        ? '${etapa3Num(device.latestValue)} $etapa3Unit'
        : tr('dash_noReadings');
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.location?.isNotEmpty == true
                      ? device.location!
                      : device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            label: etapa3LevelLabel(device.latestLevel),
            color: color,
          ),
        ],
      ),
    );
  }
}
