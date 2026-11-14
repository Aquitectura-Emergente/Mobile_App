import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';

/// Jornadas anteriores del operario, por páginas.
class OperatorHistoryScreen extends StatefulWidget {
  const OperatorHistoryScreen({super.key});

  @override
  State<OperatorHistoryScreen> createState() => _OperatorHistoryScreenState();
}

class _OperatorHistoryScreenState extends State<OperatorHistoryScreen> {
  final List<ExposureSession> _sessions = [];
  int _page = 0;
  bool _last = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _sessions.clear();
        _page = 0;
        _last = false;
      }
    });
    try {
      final page = await DosimetryFacade.history(page: _page);
      if (!mounted) return;
      setState(() {
        _sessions.addAll(page.content);
        _last = page.last;
        _page++;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Etapa3Shell(
      title: tr('op_historyTitle'),
      subtitle: tr('op_exposureSubtitle'),
      selectedIndex: 2,
      trailing: IconButton(
        icon: const Icon(Icons.refresh, color: Etapa3Palette.muted),
        onPressed: () => _loadMore(reset: true),
      ),
      child: _body(),
    );
  }

  Widget _body() {
    if (_error != null && _sessions.isEmpty) {
      return Etapa3Error(message: _error!, onRetry: () => _loadMore(reset: true));
    }
    if (_sessions.isEmpty) {
      return _loading
          ? const Etapa3Loading()
          : OperatorEmpty(icon: Icons.history, title: tr('op_noHistory'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in _sessions) ...[
          _SessionTile(session: s),
          const SizedBox(height: 10),
        ],
        if (!_last)
          TextButton(
            onPressed: _loading ? null : _loadMore,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr('op_loadMore')),
          ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final ExposureSession session;

  @override
  Widget build(BuildContext context) {
    final color = exposureColor(session.status);
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.badge_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exposureDateTime(session.startedAt),
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  session.isClosed
                      ? '${tr('op_shiftClosed')} · ${exposureDateTime(session.endedAt)}'
                      : exposureLabel(session.status),
                  style: const TextStyle(color: Etapa3Palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          StatusPill(label: exposurePercent(session.percentage), color: color),
        ],
      ),
    );
  }
}
