import 'package:flutter/material.dart';

import '../../contexts/personaldosimetry/application/dosimetry_facade.dart';
import '../../contexts/personaldosimetry/domain/exposure_session.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';
import '../etapa3/etapa3_components.dart';
import 'operator_components.dart';
import 'operator_session_screen.dart';

/// Historial de jornadas, agrupado por mes. Cada fila muestra el porcentaje
/// del límite consumido (dosis acumulada) y abre el detalle de la jornada.
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
      onRefresh: () => _loadMore(reset: true),
      trailing: EmsIconButton(icon: PhosphorIconsRegular.arrowsClockwise, tooltip: tr('common_refresh'), onPressed: () => _loadMore(reset: true)),
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null && _sessions.isEmpty) {
      return Etapa3Error(message: _error!, onRetry: () => _loadMore(reset: true));
    }
    if (_sessions.isEmpty) {
      return _loading ? const Etapa3Loading() : OperatorEmpty(icon: PhosphorIconsRegular.clockCounterClockwise, title: tr('op_noHistory'));
    }
    final c = context.ems;
    final groups = <String, List<ExposureSession>>{};
    for (final s in _sessions) {
      final t = DateTime.tryParse(s.startedAt ?? '')?.toLocal();
      final key = t == null ? '—' : '${EmsFormat.month(t.month)} ${t.year}';
      groups.putIfAbsent(key, () => []).add(s);
    }
    final warned = _sessions.where((s) => s.status != ExposureStatus.normal).length;
    final exceeded = _sessions.where((s) => s.status == ExposureStatus.exceeded).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.md)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cell(tr('m_shifts'), '${_sessions.length}${_last ? '' : '+'}', null),
                VerticalDivider(width: 1, color: c.borderSubtle),
                _Cell(tr('op_statusWarning'), '$warned', warned > 0 ? c.warning : null),
                VerticalDivider(width: 1, color: c.borderSubtle),
                _Cell(tr('m_exceeded'), '$exceeded', exceeded > 0 ? c.danger : null),
              ],
            ),
          ),
        ),
        const SizedBox(height: EmsSpace.s7),
        for (final e in groups.entries) ...[
          EmsGroup(
            title: e.key,
            trailing: Text('${e.value.length}', style: context.type.monoSm),
            children: [for (final s in e.value) _SessionRow(session: s)],
          ),
          const SizedBox(height: EmsSpace.s6),
        ],
        if (_error != null) ...[
          EmsBanner(tone: EmsTone.danger, icon: PhosphorIconsRegular.warningCircle, message: _error!),
          const SizedBox(height: EmsSpace.s4),
        ],
        if (!_last)
          EmsButton(label: tr('op_loadMore'), kind: EmsButtonKind.secondary, loading: _loading, onPressed: _loadMore),
      ],
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
              Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow.copyWith(fontSize: 10)),
              const SizedBox(height: EmsSpace.s2),
              Text(value, style: context.type.metricMd.copyWith(color: color)),
            ],
          ),
        ),
      );
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final ExposureSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final s = session;
    final start = DateTime.tryParse(s.startedAt ?? '')?.toLocal();
    final end = DateTime.tryParse(s.endedAt ?? '')?.toLocal();
    final tone = exposureTone(s.status);
    final t = emsTone(context, s.status == ExposureStatus.exceeded ? EmsTone.danger : tone);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OperatorSessionScreen(session: s))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(EmsSpace.s5 - EmsBorder.rail, EmsSpace.s4, EmsSpace.s4, EmsSpace.s4),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: t.signal, width: EmsBorder.rail))),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(start == null ? '—' : EmsFormat.weekday(start).toUpperCase(), style: context.type.monoSm),
                    Text(start == null ? '—' : '${start.day}', style: context.type.metricMd.copyWith(fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(width: EmsSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      start == null ? '—' : '${EmsFormat.time(start)} – ${end == null ? tr('m_inProgress') : EmsFormat.time(end)}',
                      style: context.type.mono.copyWith(color: c.text),
                    ),
                    const SizedBox(height: EmsSpace.s3),
                    EmsDoseBar(fraction: s.progress, warnAt: null, tone: s.status == ExposureStatus.exceeded ? EmsTone.danger : tone, height: 6),
                  ],
                ),
              ),
              const SizedBox(width: EmsSpace.s4),
              SizedBox(
                width: 56,
                child: Text(exposurePercent(s.percentage), textAlign: TextAlign.right, style: context.type.mono.copyWith(fontSize: 15, color: t.fg)),
              ),
              const SizedBox(width: EmsSpace.s2),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
