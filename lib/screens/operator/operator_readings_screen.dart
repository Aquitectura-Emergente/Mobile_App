import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../contexts/personaldosimetry/domain/personal_reading.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';
import 'operator_session_screen.dart';

class _ShiftReadings {
  const _ShiftReadings(this.session, this.readings);

  final ExposureSession? session;
  final List<PersonalReading> readings;
}

/// Pestaña Jornada: lecturas del dosímetro en la jornada actual.
class OperatorReadingsScreen extends StatefulWidget {
  const OperatorReadingsScreen({super.key});

  @override
  State<OperatorReadingsScreen> createState() => _OperatorReadingsScreenState();
}

class _OperatorReadingsScreenState extends State<OperatorReadingsScreen> {
  late Future<_ShiftReadings> _future = _load();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ModalRoute.of(context)?.isCurrent ?? true) _reload();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<_ShiftReadings> _load() async {
    final session = await DosimetryFacade.currentShift();
    if (session == null) return const _ShiftReadings(null, []);
    return _ShiftReadings(session, await DosimetryFacade.allShiftReadings(session.id));
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final future = _load();
    setState(() { _future = future; });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('op_readingsTitle'),
      subtitle: tr('op_exposureSubtitle'),
      selectedIndex: 1,
      onRefresh: _reload,
      trailing: EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload),
      child: FutureBuilder<_ShiftReadings>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) return const Etapa3Loading();
          if (snap.hasError && !snap.hasData) {
            return Etapa3Error(
              message: snap.error is ApiException ? (snap.error as ApiException).message : tr('m_readingsErr'),
              onRetry: _reload,
            );
          }
          final data = snap.data!;
          final session = data.session;
          if (session == null) {
            return OperatorEmpty(icon: PhosphorIconsRegular.cellSignalSlash, title: tr('op_noDosimeter'), subtitle: tr('op_noDosimeterHint'));
          }
          final start = DateTime.tryParse(session.startedAt ?? '')?.toLocal();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmsPanel(
                padding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorSessionScreen(session: session))),
                child: EmsRow(
                  icon: PhosphorIconsRegular.hardHat,
                  iconTone: session.isOpen ? EmsTone.live : EmsTone.neutral,
                  title: start == null ? tr('m_shift') : '${EmsFormat.dayTitle(start)} · ${EmsFormat.time(start)}',
                  subtitle: '${tr(session.isOpen ? 'm_shiftOpen' : (session.isClosed ? 'm_shiftClosed' : 'm_shiftClosing'))} · ${data.readings.length} ${tr('m_readings')}',
                  trailing: EmsTag(exposurePercent(session.percentage), tone: exposureTone(session.status)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorSessionScreen(session: session))),
                ),
              ),
              const SizedBox(height: EmsSpace.s3),
              Text(tr('m_doseVsField'), style: context.type.caption),
              const SizedBox(height: EmsSpace.s6),
              ShiftReadingsSection(session: session, readings: data.readings, recent: 8),
              const SizedBox(height: EmsSpace.s7),
              Text(tr('ds_notMetrology'), textAlign: TextAlign.center, style: context.type.caption),
            ],
          );
        },
      ),
    );
  }
}
