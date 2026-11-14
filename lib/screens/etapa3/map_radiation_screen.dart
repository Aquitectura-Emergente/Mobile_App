import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../contexts/iam/domain/client_profile.dart';
import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'etapa3_components.dart';
import 'subpage_scaffold.dart';

class _MapData {
  _MapData(this.profile, this.devices);
  final ClientProfile profile;
  final List<ClientDevice> devices;
}

/// Radiation map: the client's site with one marker per sensor, color-coded
/// by its level, plus level filters and sharing.
/// Tiles: OpenStreetMap via flutter_map (no API key).
class MapRadiationScreen extends StatefulWidget {
  const MapRadiationScreen({super.key});

  @override
  State<MapRadiationScreen> createState() => _MapRadiationScreenState();
}

class _MapRadiationScreenState extends State<MapRadiationScreen> {
  late Future<_MapData> _future;
  String _levelFilter = 'all'; // all | safe | caution | danger
  ClientDevice? _selected;
  _MapData? _data;
  bool _sharing = false;
  final _mapKey = GlobalKey();

  // Fallback center (Lima) when the client has no registered coordinates.
  static const _limaCenter = LatLng(-12.05, -77.05);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MapData> _load() async {
    final profile = await AuthFacade.profile();
    final devices = await DeviceFacade.all();
    return _MapData(profile, devices);
  }

  void _reload() {
    final future = _load();
    setState(() { _future = future; });
  }

  /// All sensors sit at the client's registered site; spread them on a small
  /// deterministic ring (~60 m) so every marker stays visible and tappable.
  LatLng _positionFor(ClientProfile p, int index, int total) {
    final base = (p.latitude != null && p.longitude != null)
        ? LatLng(p.latitude!, p.longitude!)
        : _limaCenter;
    if (total <= 1) return base;
    final angle = (2 * math.pi * index) / total;
    const spread = 0.0006; // ≈ 60 m
    return LatLng(
      base.latitude + spread * math.sin(angle),
      base.longitude + spread * math.cos(angle),
    );
  }

  List<ClientDevice> _filtered(List<ClientDevice> devices) {
    if (_levelFilter == 'all') return devices;
    return devices
        .where((d) => (d.latestLevel ?? 'safe') == _levelFilter)
        .toList();
  }

  /// Comparte una captura del mapa con el resumen de niveles.
  Future<void> _share() async {
    final data = _data;
    final boundary =
        _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (data == null || boundary == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/emsafe_map.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: _summary(data),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('map_shareError'))));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _summary(_MapData data) {
    final lines = [
      tr('map_shareTitle'),
      for (final d in _filtered(data.devices))
        '• ${d.name}: ${etapa3LevelLabel(d.latestLevel)}'
            '${d.latestValue == null ? '' : ' (${etapa3Num(d.latestValue)} $etapa3Unit)'}',
    ];
    final p = data.profile;
    if (p.hasCoordinates) {
      lines.add(
        'https://www.openstreetmap.org/?mlat=${p.latitude}&mlon=${p.longitude}#map=17/${p.latitude}/${p.longitude}',
      );
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: tr('map_title'),
      subtitle: tr('map_subtitle'),
      scrollable: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: tr('map_share'),
            onPressed: _sharing ? null : _share,
            style: _actionStyle,
            icon: const Icon(Icons.ios_share),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: tr('common_refresh'),
            onPressed: _reload,
            style: _actionStyle,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      child: FutureBuilder<_MapData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Etapa3Loading();
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : tr('map_errLoad');
            return Etapa3Error(message: msg, onRetry: _reload);
          }
          _data = snapshot.data;
          return _buildMap(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildMap(_MapData data) {
    final devices = _filtered(data.devices);
    final center =
        (data.profile.latitude != null && data.profile.longitude != null)
        ? LatLng(data.profile.latitude!, data.profile.longitude!)
        : _limaCenter;

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: tr('map_all'),
                color: Etapa3Palette.cyan,
                selected: _levelFilter == 'all',
                onTap: () => setState(() => _levelFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: tr('map_safe'),
                color: Etapa3Palette.green,
                selected: _levelFilter == 'safe',
                onTap: () => setState(() => _levelFilter = 'safe'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: tr('map_caution'),
                color: Etapa3Palette.amber,
                selected: _levelFilter == 'caution',
                onTap: () => setState(() => _levelFilter = 'caution'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: tr('map_danger'),
                color: Etapa3Palette.red,
                selected: _levelFilter == 'danger',
                onTap: () => setState(() => _levelFilter = 'danger'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RepaintBoundary(
            key: _mapKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 16,
                  onTap: (_, _) => setState(() => _selected = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.emsafe_app',
                  ),
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < devices.length; i++)
                        Marker(
                          point: _positionFor(
                            data.profile,
                            data.devices.indexOf(devices[i]),
                            data.devices.length,
                          ),
                          width: 34,
                          height: 34,
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = devices[i]),
                            child: Container(
                              decoration: BoxDecoration(
                                color: etapa3LevelColor(devices[i].latestLevel),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sensors,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selected != null) ...[
          const SizedBox(height: 12),
          _DeviceInfoCard(device: _selected!),
        ] else if (devices.isEmpty) ...[
          const SizedBox(height: 12),
          GlassPanel(
            child: Text(
              tr('map_noneForFilter'),
              style: const TextStyle(color: Etapa3Palette.muted, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

final _actionStyle = IconButton.styleFrom(
  backgroundColor: Etapa3Palette.panel,
  foregroundColor: Etapa3Palette.blue,
  side: const BorderSide(color: Etapa3Palette.stroke),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : Etapa3Palette.panelSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : Etapa3Palette.stroke,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Etapa3Palette.muted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({required this.device});

  final ClientDevice device;

  @override
  Widget build(BuildContext context) {
    final color = etapa3LevelColor(device.latestLevel);
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.sensors, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.location ?? device.serialNumber ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusPill(
            label: device.latestValue != null
                ? '${etapa3Num(device.latestValue)} $etapa3Unit'
                : '--',
            color: color,
          ),
        ],
      ),
    );
  }
}
