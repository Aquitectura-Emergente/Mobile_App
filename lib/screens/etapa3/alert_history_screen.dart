import 'package:flutter/material.dart';

import '../../contexts/alerts/application/alert_facade.dart';
import '../../contexts/alerts/domain/alert_filter.dart';
import '../../contexts/alerts/domain/client_alert.dart';
import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/plug_status.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'etapa3_components.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  late Future<List<ClientAlert>> _future;
  late Future<PlugStatus?> _plug;
  AlertFilter _filter = const AlertFilter();

  @override
  void initState() {
    super.initState();
    _future = AlertFacade.all();
    _plug = _loadPlug();
  }

  // El enchufe es opcional: si falla, el historial se muestra igual.
  Future<PlugStatus?> _loadPlug() async {
    try {
      return await DeviceFacade.homePlugStatus();
    } catch (_) {
      return null;
    }
  }

  void _reload() {
    setState(() {
      _future = AlertFacade.all();
      _plug = _loadPlug();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('al_title'),
      subtitle: tr('al_subtitle'),
      selectedIndex: 3,
      trailing: IconButton(
        tooltip: tr('common_refresh'),
        onPressed: _reload,
        style: IconButton.styleFrom(
          backgroundColor: Etapa3Palette.panel,
          foregroundColor: Etapa3Palette.blue,
          side: const BorderSide(color: Etapa3Palette.stroke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.refresh),
      ),
      child: FutureBuilder<List<ClientAlert>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Etapa3Loading();
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : tr('al_errLoad');
            return Etapa3Error(message: msg, onRetry: _reload);
          }
          return _buildList(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildList(List<ClientAlert> all) {
    final alerts = _filter.apply(all);
    final high = alerts.where((a) => a.level == 'danger').length;
    final medium = alerts.where((a) => a.level == 'caution').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlertSummary(total: alerts.length, high: high, medium: medium),
        FutureBuilder<PlugStatus?>(
          future: _plug,
          builder: (context, snap) {
            final command = snap.data?.lastCommand;
            if (command == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 18),
              child: _PlugActionCard(command: command),
            );
          },
        ),
        const SizedBox(height: 18),
        SectionLabel(tr('al_events')),
        const SizedBox(height: 10),
        _FilterBar(
          filter: _filter,
          devices: AlertFilter.devicesIn(all),
          onChanged: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          GlassPanel(
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Etapa3Palette.green, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(_filter.isActive ? 'al_emptyFiltered' : 'al_empty'),
                    style: const TextStyle(
                      color: Etapa3Palette.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final alert in alerts) ...[
            _AlertCard(alert: alert),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({
    required this.total,
    required this.high,
    required this.medium,
  });

  final int total;
  final int high;
  final int medium;

  @override
  Widget build(BuildContext context) {
    final hasHigh = high > 0;
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (hasHigh ? Etapa3Palette.red : Etapa3Palette.green)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (hasHigh ? Etapa3Palette.red : Etapa3Palette.green)
                        .withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: hasHigh ? Etapa3Palette.red : Etapa3Palette.green,
                  size: 27,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total ${tr('al_eventsLogged')}',
                      style: const TextStyle(
                        color: Etapa3Palette.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasHigh
                          ? '$high ${tr('al_highNeedReview')}'
                          : tr('al_noHigh'),
                      style: const TextStyle(
                        color: Etapa3Palette.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: tr('al_high'),
                  value: high.toString().padLeft(2, '0'),
                  color: Etapa3Palette.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryStat(
                  label: tr('al_medium'),
                  value: medium.toString().padLeft(2, '0'),
                  color: Etapa3Palette.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryStat(
                  label: tr('al_total'),
                  value: total.toString().padLeft(2, '0'),
                  color: Etapa3Palette.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Etapa3Palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final ClientAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = etapa3LevelColor(alert.level);
    final icon = alert.level == 'danger'
        ? Icons.warning_amber_rounded
        : Icons.bolt;
    return GlassPanel(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Etapa3Palette.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      etapa3TimeAgo(alert.recordedAt, fallbackDate: alert.time),
                      style: const TextStyle(
                        color: Etapa3Palette.quiet,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  alert.deviceName ?? 'Sensor',
                  style: const TextStyle(
                    color: Etapa3Palette.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.description,
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                StatusPill(
                  label: '${etapa3Num(alert.value)} $etapa3Unit',
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtros por fecha, nivel y sensor.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.devices,
    required this.onChanged,
  });

  final AlertFilter filter;
  final Map<int, String> devices;
  final ValueChanged<AlertFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final periods = {
      AlertPeriod.all: tr('al_periodAll'),
      AlertPeriod.today: tr('al_periodToday'),
      AlertPeriod.week: tr('al_periodWeek'),
      AlertPeriod.month: tr('al_periodMonth'),
    };
    final levels = <String?, String>{
      null: tr('map_all'),
      'danger': tr('map_danger'),
      'caution': tr('map_caution'),
      'safe': tr('map_safe'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in periods.entries)
              _Chip(
                label: e.value,
                selected: filter.period == e.key,
                color: Etapa3Palette.cyan,
                onTap: () => onChanged(filter.copyWith(period: e.key)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in levels.entries)
              _Chip(
                label: e.value,
                selected: filter.level == e.key,
                color: e.key == null
                    ? Etapa3Palette.cyan
                    : etapa3LevelColor(e.key),
                onTap: () => onChanged(filter.copyWith(level: () => e.key)),
              ),
          ],
        ),
        if (devices.length > 1) ...[
          const SizedBox(height: 8),
          DropdownButton<int?>(
            value: devices.containsKey(filter.deviceId) ? filter.deviceId : null,
            isExpanded: true,
            dropdownColor: Etapa3Palette.panel,
            style: const TextStyle(color: Etapa3Palette.text, fontSize: 13),
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem<int?>(
                  value: null, child: Text(tr('al_allSensors'))),
              for (final e in devices.entries)
                DropdownMenuItem<int?>(value: e.key, child: Text(e.value)),
            ],
            onChanged: (id) => onChanged(filter.copyWith(deviceId: () => id)),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Etapa3Palette.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? color.withValues(alpha: 0.6) : Etapa3Palette.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Etapa3Palette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Última orden enviada al enchufe y en qué quedó.
class _PlugActionCard extends StatelessWidget {
  const _PlugActionCard({required this.command});

  final PlugCommand command;

  @override
  Widget build(BuildContext context) {
    final off = command.action == PlugPower.off;
    final (statusLabel, color) = command.isConfirmed
        ? (tr('al_plugConfirmed'), Etapa3Palette.green)
        : command.hasFailed
            ? (tr('al_plugFailed'), Etapa3Palette.red)
            : (tr('plug_pendingBadge'), Etapa3Palette.amber);
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.power_settings_new,
              color: off ? Etapa3Palette.red : Etapa3Palette.green, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(off ? 'al_plugOff' : 'al_plugOn'),
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  etapa3TimeAgo(command.requestedAt),
                  style:
                      const TextStyle(color: Etapa3Palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          StatusPill(label: statusLabel, color: color),
        ],
      ),
    );
  }
}
