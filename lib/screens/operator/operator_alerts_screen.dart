import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../contexts/personaldosimetry/domain/operator_alert.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';
import 'operator_session_screen.dart';

class _AlertsData {
  _AlertsData(this.alerts, this.sessions);
  final List<OperatorAlert> alerts;
  final Map<String, ExposureSession> sessions;
}

/// Avisos de exposición del operario. El backend aún no le expone sus
/// alertas ni su confirmación: se derivan de las marcas de advertencia y
/// límite de sus jornadas, y cada aviso abre su jornada.
class OperatorAlertsScreen extends StatefulWidget {
  const OperatorAlertsScreen({super.key});

  @override
  State<OperatorAlertsScreen> createState() => _OperatorAlertsScreenState();
}

class _OperatorAlertsScreenState extends State<OperatorAlertsScreen> {
  late Future<_AlertsData> _future = _load();

  Future<_AlertsData> _load() async {
    final current = await DosimetryFacade.currentShift();
    final recent = await DosimetryFacade.history();
    final all = [?current, ...recent.content];
    return _AlertsData(OperatorAlert.fromSessions(all), {for (final s in all) s.id: s});
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() { _future = future; });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('op_alertsTitle'),
      subtitle: tr('op_exposureSubtitle'),
      selectedIndex: 3,
      onRefresh: _reload,
      trailing: EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: _reload),
      child: FutureBuilder<_AlertsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) return const Etapa3Loading();
          if (snap.hasError && !snap.hasData) {
            return Etapa3Error(message: snap.error is ApiException ? (snap.error as ApiException).message : tr('m_alertsErr'), onRetry: _reload);
          }
          final data = snap.data!;
          final c = context.ems;
          final exceeded = data.alerts.where((a) => a.isExceeded).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Cell(tr('al_total'), '${data.alerts.length}', null),
                      VerticalDivider(width: 1, color: c.borderSubtle),
                      _Cell(tr('op_statusWarning'), '${data.alerts.length - exceeded}', c.warningSignal),
                      VerticalDivider(width: 1, color: c.borderSubtle),
                      _Cell(tr('m_exceeded'), '$exceeded', c.dangerSignal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: EmsSpace.s4),
              EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.info, message: tr('m_opAlertsNote')),
              const SizedBox(height: EmsSpace.s7),
              if (data.alerts.isEmpty)
                OperatorEmpty(icon: PhosphorIconsRegular.bellSlash, title: tr('op_noAlerts'))
              else
                EmsGroup(
                  title: tr('m_alertLog'),
                  children: [
                    for (final a in data.alerts)
                      _AlertRow(
                        alert: a,
                        onTap: data.sessions[a.sessionId] == null
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorSessionScreen(session: data.sessions[a.sessionId]!))),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(EmsSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (color != null) ...[Container(width: 7, height: 7, color: color), const SizedBox(width: EmsSpace.s2)],
                  Flexible(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10))),
                ],
              ),
              const SizedBox(height: EmsSpace.s2),
              Text(value, style: context.type.metricMd),
            ],
          ),
        ),
      );
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, this.onTap});

  final OperatorAlert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse(alert.at ?? '')?.toLocal();
    final tone = alert.isExceeded ? EmsTone.danger : EmsTone.warning;
    return EmsRow(
      rail: emsTone(context, tone).signal,
      icon: alert.isExceeded ? PhosphorIconsRegular.warningOctagon : PhosphorIconsRegular.warning,
      iconTone: tone,
      title: tr(alert.isExceeded ? 'op_alertExceeded' : 'op_alertWarning'),
      subtitle: at == null ? null : '${EmsFormat.dayTitle(at)} · ${EmsFormat.time(at)}',
      trailing: EmsTag(exposurePercent(alert.percentage), tone: alert.isExceeded ? EmsTone.critical : EmsTone.warning),
      onTap: onTap,
    );
  }
}
