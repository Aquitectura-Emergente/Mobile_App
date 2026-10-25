import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/iottelemetry/application/device_facade.dart';
import '../../contexts/iottelemetry/domain/client_device.dart';
import '../../contexts/iottelemetry/infrastructure/realtime_service.dart';
import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../contexts/radiationmonitoring/domain/client_reading.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'etapa3_components.dart';

/// Loaded payload for the monitor screen: all devices + the selected one
/// with its readings.
class _SensorData {
  _SensorData(this.devices, this.device, this.readings);
  final List<ClientDevice> devices;
  final ClientDevice? device;
  final List<ClientReading> readings;
}

/// Live sensor data view (real backend data) — "Monitor" tab.
/// Coexists with the informational "Vitals" tab (health tips).
class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late Future<_SensorData> _future;
  bool _plugBusy = false;
  int? _selectedId;
  Timer? _liveDebounce;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // Live updates: refresh (debounced) whenever a reading arrives via STOMP.
    RealtimeService.ensureConnected();
    RealtimeService.readingTick.addListener(_onLiveReading);
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

  Future<_SensorData> _load() async {
    final devices = await DeviceFacade.all();
    if (devices.isEmpty) return _SensorData(devices, null, const []);
    final selected = devices.firstWhere(
      (d) => d.id == _selectedId,
      orElse: () => devices.first,
    );
    _selectedId = selected.id;
    final readings = await MonitoringFacade.deviceReadings(selected.id);
    return _SensorData(devices, selected, readings);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _selectDevice(int id) {
    if (id == _selectedId) return;
    _selectedId = id;
    _reload();
  }

  /// Sends the user's relay order (cut / restore power) to the backend;
  /// the edge picks it up and drives the physical relay.
  Future<void> _setPlug(ClientDevice device, bool on) async {
    setState(() => _plugBusy = true);
    try {
      await DeviceFacade.setPlug(device.id, on ? 'ON' : 'OFF');
      _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _plugBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SensorData>(
      future: _future,
      builder: (context, snapshot) {
        final device = snapshot.data?.device;
        return Etapa3Shell(
          title: tr('mon_title'),
          subtitle: device?.name ?? tr('mon_subtitle'),
          selectedIndex: 1,
          trailing: IconButton(
            tooltip: tr('common_refresh'),
            onPressed: _reload,
            style: IconButton.styleFrom(
              backgroundColor: Etapa3Palette.panel,
              foregroundColor: Etapa3Palette.blue,
              side: const BorderSide(color: Etapa3Palette.stroke),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.refresh),
          ),
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_SensorData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Etapa3Loading();
    }
    if (snapshot.hasError) {
      final msg = snapshot.error is ApiException
          ? (snapshot.error as ApiException).message
          : tr('mon_errLoad');
      return Etapa3Error(message: msg, onRetry: _reload);
    }

    final data = snapshot.data!;
    final device = data.device;
    final readings = data.readings;

    if (device == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: GlassPanel(
          child: Text(
            tr('mon_noSensors'),
            style: const TextStyle(
              color: Etapa3Palette.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.devices.length > 1) ...[
          SectionLabel(tr('mon_yourSensors')),
          const SizedBox(height: 10),
          _DeviceSelector(
            devices: data.devices,
            selectedId: device.id,
            onSelect: _selectDevice,
          ),
          const SizedBox(height: 16),
        ],
        _SensorHero(device: device),
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
              childAspectRatio: compact ? 2.35 : 1.08,
              children: [
                MetricTile(
                  icon: Icons.show_chart,
                  label: tr('mon_latest'),
                  value: etapa3Num(device.latestValue),
                  caption: '$etapa3Unit ${tr('mon_reading')}',
                  accent: etapa3LevelColor(device.latestLevel),
                ),
                MetricTile(
                  icon: Icons.dataset_outlined,
                  label: tr('mon_readings'),
                  value: device.readingsCount.toString(),
                  caption: tr('mon_records'),
                  accent: Etapa3Palette.cyan,
                ),
                MetricTile(
                  icon: Icons.memory_outlined,
                  label: tr('mon_type'),
                  value: device.type.isEmpty ? '--' : device.type,
                  caption: device.serialNumber ?? '',
                  accent: Etapa3Palette.blue,
                ),
                MetricTile(
                  icon: Icons.power_settings_new,
                  label: tr('mon_status'),
                  value: device.status.isEmpty ? '--' : device.status,
                  caption: device.location ?? '',
                  accent: device.status.toLowerCase() == 'active'
                      ? Etapa3Palette.green
                      : Etapa3Palette.amber,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('mon_powerControl')),
        const SizedBox(height: 10),
        _PlugCard(
          device: device,
          busy: _plugBusy,
          onChanged: (on) => _setPlug(device, on),
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('mon_signalTrend')),
        const SizedBox(height: 10),
        _TrendCard(readings: readings),
        const SizedBox(height: 20),
        SectionLabel(tr('mon_recentReadings')),
        const SizedBox(height: 10),
        if (readings.isEmpty)
          GlassPanel(
            child: Text(
              tr('mon_noReadingsYet'),
              style:
                  const TextStyle(color: Etapa3Palette.muted, fontSize: 13),
            ),
          )
        else
          for (final reading in readings.take(8)) ...[
            _ReadingRow(reading: reading),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

/// Horizontal chip selector to switch between the client's sensors.
class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({
    required this.devices,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ClientDevice> devices;
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = devices[i];
          final selected = d.id == selectedId;
          final levelColor = etapa3LevelColor(d.latestLevel);
          return InkWell(
            onTap: () => onSelect(d.id),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? Etapa3Palette.cyan.withValues(alpha: 0.14)
                    : Etapa3Palette.panelSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Etapa3Palette.cyan.withValues(alpha: 0.5)
                      : Etapa3Palette.stroke,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: levelColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    d.name,
                    style: TextStyle(
                      color: selected
                          ? Etapa3Palette.cyan
                          : Etapa3Palette.muted,
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SensorHero extends StatelessWidget {
  const _SensorHero({required this.device});

  final ClientDevice device;

  @override
  Widget build(BuildContext context) {
    final color = etapa3LevelColor(device.latestLevel);
    final online = device.status.toLowerCase() == 'active';
    final double progress = (device.latestValue ?? 0) / etapa3SafetyThreshold;

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              StatusPill(
                label: online ? tr('mon_online') : device.status.toUpperCase(),
                color: online ? Etapa3Palette.green : Etapa3Palette.amber,
              ),
              const Spacer(),
              Text(
                device.latestReadingDate != null
                    ? '${tr('mon_updated')} ${device.latestReadingDate}'
                    : tr('mon_noData'),
                style: TextStyle(
                  color: Etapa3Palette.quiet.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.06),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 28),
              ],
            ),
            child: Icon(Icons.sensors, color: color, size: 76),
          ),
          const SizedBox(height: 26),
          Text(
            etapa3Num(device.latestValue),
            style: const TextStyle(
              color: Etapa3Palette.text,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$etapa3Unit · ${tr('dash_currentExposure').toLowerCase()}',
            style: const TextStyle(
              color: Etapa3Palette.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFF32343E),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart-plug relay control: shows the state reported by the device and lets
/// the user order the relay to open (cut power) or close (restore power).
class _PlugCard extends StatelessWidget {
  const _PlugCard({
    required this.device,
    required this.busy,
    required this.onChanged,
  });

  final ClientDevice device;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // What the user ordered (falls back to what the device reports).
    final desired = (device.desiredPlug ?? device.plug ?? 'ON').toUpperCase();
    final isOn = desired == 'ON';
    final color = isOn ? Etapa3Palette.green : Etapa3Palette.red;
    final reported = device.plug?.toUpperCase();

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Icon(Icons.power_settings_new, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOn ? tr('mon_powerOn') : tr('mon_powerOff'),
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reported == null
                      ? tr('mon_noRelayState')
                      : '${tr('mon_relayReports')} $reported. ${tr('mon_relayToggleHint')}',
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Switch(
                  value: isOn,
                  activeThumbColor: Etapa3Palette.green,
                  activeTrackColor:
                      Etapa3Palette.green.withValues(alpha: 0.28),
                  inactiveThumbColor: Etapa3Palette.red,
                  inactiveTrackColor:
                      Etapa3Palette.red.withValues(alpha: 0.22),
                  onChanged: onChanged,
                ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.readings});

  final List<ClientReading> readings;

  @override
  Widget build(BuildContext context) {
    // readings come newest-first; take a window and show oldest→newest.
    final window = readings.take(12).toList().reversed.toList();
    final values = window
        .map((r) => r.value ?? 0)
        .where((v) => v >= 0)
        .toList();
    final maxVal = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('mon_recentTitle'),
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusPill(
                label: '${window.length} pts',
                color: Etapa3Palette.cyan,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: window.isEmpty
                ? Center(
                    child: Text(
                      tr('mon_noChart'),
                      style: const TextStyle(
                          color: Etapa3Palette.quiet, fontSize: 12),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final reading in window) ...[
                        Expanded(
                          child: FractionallySizedBox(
                            heightFactor:
                                ((reading.value ?? 0) / safeMax).clamp(0.04, 1.0),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: etapa3LevelColor(reading.level)
                                    .withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            '${tr('mon_peakWindow')} ${etapa3Num(safeMax)} $etapa3Unit.',
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

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.reading});

  final ClientReading reading;

  @override
  Widget build(BuildContext context) {
    final color = etapa3LevelColor(reading.level);
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(Icons.bolt, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${etapa3Num(reading.value)} $etapa3Unit',
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reading.recordedAt != null
                      ? '${reading.readingDate ?? ''} · ${etapa3TimeOfDay(reading.recordedAt)}'
                      : (reading.readingDate ?? ''),
                  style: const TextStyle(
                    color: Etapa3Palette.quiet,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(label: etapa3LevelLabel(reading.level), color: color),
        ],
      ),
    );
  }
}
