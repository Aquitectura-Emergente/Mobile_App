import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/iam/application/auth_facade.dart';
import '../../contexts/iam/domain/client_profile.dart';
import '../../contexts/radiationmonitoring/domain/radiation_level.dart';
import '../../contexts/radiationmonitoring/domain/reading_series.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../shared/measurement_overview.dart';
import 'sensor_detail_screen.dart';

class _MapData {
  _MapData(this.profile, this.devices);
  final ClientProfile profile;
  final List<ClientDevice> devices;
  List<ClientDevice> get sensors => devices.where((d) => !d.isPlug).toList();
}

/// Mapa del hogar. El backend solo conoce las coordenadas del domicilio, no
/// las de cada sensor: se marca el sitio (con el nivel más alto de sus
/// sensores) y los sensores se listan por su ubicación dentro del hogar.
class MapRadiationScreen extends StatefulWidget {
  const MapRadiationScreen({super.key});

  @override
  State<MapRadiationScreen> createState() => _MapRadiationScreenState();
}

class _MapRadiationScreenState extends State<MapRadiationScreen> {
  late Future<_MapData> _future = _load();
  String? _levelFilter; // null = todos
  _MapData? _data;
  bool _sharing = false;
  final _mapKey = GlobalKey();

  Future<_MapData> _load() async {
    final profile = await AuthFacade.profile();
    final devices = await DeviceFacade.all();
    return _MapData(profile, devices);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() { _future = future; });
    try {
      await future;
    } catch (_) {}
  }

  List<ClientDevice> _filtered(List<ClientDevice> sensors) =>
      _levelFilter == null ? sensors : sensors.where((d) => d.latestLevel == _levelFilter).toList();

  /// Comparte una captura del mapa con el resumen de niveles.
  Future<void> _share() async {
    final data = _data;
    final boundary = _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (data == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      final files = <XFile>[];
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/emsafe_map.png');
          await file.writeAsBytes(bytes.buffer.asUint8List());
          files.add(XFile(file.path, mimeType: 'image/png'));
        }
      }
      await SharePlus.instance.share(ShareParams(files: files.isEmpty ? null : files, text: _summary(data)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('map_shareError'))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _summary(_MapData data) {
    final lines = [
      tr('map_shareTitle'),
      for (final d in _filtered(data.sensors))
        '• ${d.name}${d.location == null ? '' : ' (${d.location})'}: ${levelLabel(d.latestLevel)}'
            '${d.latestValue == null ? '' : ' · ${EmsFormat.value(d.latestValue)} µT'}',
    ];
    final p = data.profile;
    if (p.hasCoordinates) {
      lines.add('https://www.openstreetmap.org/?mlat=${p.latitude}&mlon=${p.longitude}#map=17/${p.latitude}/${p.longitude}');
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return EmsPage(
      eyebrow: tr('m_mapEyebrow'),
      title: tr('map_title'),
      onRefresh: _reload,
      actions: [
        EmsIconButton(icon: PhosphorIconsRegular.shareNetwork, tooltip: tr('map_share'), onPressed: _sharing ? null : _share),
        EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload),
      ],
      child: FutureBuilder<_MapData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const EmsLoadingBlock(lines: 2);
          if (snapshot.hasError && !snapshot.hasData) {
            return EmsPanel(
              child: EmsEmptyState(
                kind: EmsEmptyKind.offline,
                title: snapshot.error is ApiException ? (snapshot.error as ApiException).message : tr('map_errLoad'),
                action: EmsButton(label: tr('common_retry'), kind: EmsButtonKind.secondary, expand: false, onPressed: _reload),
              ),
            );
          }
          _data = snapshot.data;
          return _content(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _content(BuildContext context, _MapData data) {
    final c = context.ems;
    final sensors = data.sensors;
    final shown = _filtered(sensors);
    final worst = worstLevelOf(sensors.map((s) => s.latestLevel));
    final p = data.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.hasCoordinates)
          RepaintBoundary(
            key: _mapKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EmsRadius.md),
              child: Container(
                height: 280,
                decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
                child: FlutterMap(
                  options: MapOptions(initialCenter: LatLng(p.latitude!, p.longitude!), initialZoom: 17),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.emsafe_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(p.latitude!, p.longitude!),
                          width: 56,
                          height: 56,
                          child: _SiteMarker(color: levelSignal(context, worst), count: sensors.length),
                        ),
                      ],
                    ),
                    const SimpleAttributionWidget(source: Text('OpenStreetMap')),
                  ],
                ),
              ),
            ),
          )
        else
          EmsPanel(
            padding: EdgeInsets.zero,
            child: EmsEmptyState(icon: PhosphorIconsRegular.mapPinLine, title: tr('m_noSiteTitle'), message: tr('m_noSiteMsg')),
          ),
        const SizedBox(height: EmsSpace.s4),
        EmsGroup(
          footer: tr('m_mapNote'),
          children: [
            EmsRow(
              icon: PhosphorIconsRegular.house,
              iconTone: worst == null ? null : levelTone(worst),
              title: tr('m_mySite'),
              subtitle: p.address?.isNotEmpty == true ? p.address : (p.location ?? tr('m_noAddress')),
              trailing: worst == null ? null : EmsTag(levelLabel(worst), tone: levelTone(worst)),
            ),
          ],
        ),
        const SizedBox(height: EmsSpace.s7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (lvl, label) in [
                (null, tr('map_all')),
                (RadiationLevel.danger, tr('map_danger')),
                (RadiationLevel.caution, tr('map_caution')),
                (RadiationLevel.safe, tr('map_safe')),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: EmsSpace.s3),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _levelFilter == lvl,
                    avatar: lvl == null ? null : Container(width: 8, height: 8, color: levelSignal(context, lvl)),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _levelFilter = lvl),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s4),
        if (shown.isEmpty)
          EmsPanel(padding: EdgeInsets.zero, child: EmsEmptyState(icon: PhosphorIconsRegular.funnel, title: tr('map_noneForFilter')))
        else
          EmsGroup(
            title: tr('m_sensorsBySpot'),
            children: [
              for (final d in shown)
                EmsRow(
                  rail: d.latestLevel == null ? null : levelSignal(context, d.latestLevel),
                  icon: PhosphorIconsRegular.mapPin,
                  title: d.location?.isNotEmpty == true ? d.location! : d.name,
                  subtitle: d.location?.isNotEmpty == true ? d.name : tr('m_noSpot'),
                  value: d.latestValue == null ? '—' : '${EmsFormat.value(d.latestValue)} µT',
                  mono: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SensorDetailScreen(device: d))),
                ),
            ],
          ),
      ],
    );
  }
}

class _SiteMarker extends StatelessWidget {
  const _SiteMarker({required this.color, required this.count});

  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.22))),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.chrome,
            borderRadius: BorderRadius.circular(EmsRadius.sm),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Icon(PhosphorIconsRegular.house, size: 18, color: c.chromeText),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            child: Text('$count', style: context.type.monoSm.copyWith(color: Colors.black, fontSize: 10)),
          ),
        ),
      ],
    );
  }
}
