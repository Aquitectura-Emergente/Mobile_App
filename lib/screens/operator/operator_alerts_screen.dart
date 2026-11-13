import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/operator_alert.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';

/// Avisos de exposición de las jornadas del operario.
class OperatorAlertsScreen extends StatefulWidget {
  const OperatorAlertsScreen({super.key});

  @override
  State<OperatorAlertsScreen> createState() => _OperatorAlertsScreenState();
}

class _OperatorAlertsScreenState extends State<OperatorAlertsScreen> {
  late Future<List<OperatorAlert>> _future = DosimetryFacade.alerts();

  void _reload() => setState(() => _future = DosimetryFacade.alerts());

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('op_alertsTitle'),
      subtitle: tr('op_exposureSubtitle'),
      selectedIndex: 3,
      trailing: IconButton(
        icon: const Icon(Icons.refresh, color: Etapa3Palette.muted),
        onPressed: _reload,
      ),
      child: FutureBuilder<List<OperatorAlert>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Etapa3Loading();
          }
          if (snap.hasError) {
            return Etapa3Error(message: snap.error.toString(), onRetry: _reload);
          }
          final alerts = snap.data ?? const [];
          if (alerts.isEmpty) {
            return OperatorEmpty(
              icon: Icons.notifications_off_outlined,
              title: tr('op_noAlerts'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final a in alerts) ...[
                _AlertTile(alert: a),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final OperatorAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = exposureColor(alert.status);
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            alert.isExceeded ? Icons.dangerous_outlined : Icons.warning_amber_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(alert.isExceeded ? 'op_alertExceeded' : 'op_alertWarning'),
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exposureDateTime(alert.at),
                  style: const TextStyle(color: Etapa3Palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          StatusPill(label: exposurePercent(alert.percentage), color: color),
        ],
      ),
    );
  }
}
