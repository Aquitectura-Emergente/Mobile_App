import 'package:flutter/material.dart';

import '../../contexts/clientportal/application/astra_facade.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../../services/ems_format.dart';

class _ChatMessage {
  _ChatMessage(this.role, this.text, {this.failed = false}) : at = DateTime.now();
  final String role;
  final String text;
  final bool failed;
  final DateTime at;
  bool get isUser => role == 'user';
}

/// Asistente ASTRA. El backend hace de proxy al modelo: la clave nunca viaja
/// en la app. Todo lo que responde ASTRA lleva el acento cobre de IA.
class AstraChatScreen extends StatefulWidget {
  const AstraChatScreen({super.key});

  @override
  State<AstraChatScreen> createState() => _AstraChatScreenState();
}

class _AstraChatScreenState extends State<AstraChatScreen> {
  final List<_ChatMessage> _messages = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage('model', tr('chat_welcome')));
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    // El historial excluye el saludo local y las respuestas fallidas.
    final history = _messages.skip(1).where((m) => !m.failed).map((m) => {'role': m.role, 'text': m.text}).toList();
    setState(() {
      _messages.add(_ChatMessage('user', text));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();
    try {
      final reply = await AstraFacade.ask(text, history);
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage('model', reply)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage('model', e.message, failed: true)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage('model', tr('chat_error'), failed: true)));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: EmsDuration.slow, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final suggestions = [tr('m_astraQ1'), tr('m_astraQ2'), tr('m_astraQ3')];
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                EmsPageHeader(title: 'ASTRA', eyebrow: tr('m_astraEyebrow'), actions: const [Padding(padding: EdgeInsets.only(right: EmsSpace.s3), child: EmsAiBadge('IA'))]),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s5, EmsSpace.s6, EmsSpace.s5),
                    children: [
                      for (final m in _messages) ...[
                        _Bubble(message: m),
                        const SizedBox(height: EmsSpace.s5),
                      ],
                      if (_sending) const _Typing(),
                      if (_messages.length == 1 && !_sending) ...[
                        const SizedBox(height: EmsSpace.s3),
                        Text(tr('m_astraTry').toUpperCase(), style: context.type.eyebrow),
                        const SizedBox(height: EmsSpace.s3),
                        for (final q in suggestions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: EmsSpace.s3),
                            child: EmsPanel(
                              padding: EdgeInsets.zero,
                              onTap: () => _send(q),
                              child: EmsRow(icon: PhosphorIconsRegular.sparkle, iconTone: EmsTone.accent, title: q, onTap: () => _send(q)),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.borderSubtle))),
                  padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s5, EmsSpace.s4),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              minLines: 1,
                              maxLines: 4,
                              onSubmitted: (_) => _send(),
                              textInputAction: TextInputAction.send,
                              style: context.type.body.copyWith(fontSize: 15),
                              cursorColor: c.primary,
                              decoration: InputDecoration(
                                hintText: tr('chat_hint'),
                                hintStyle: context.type.body.copyWith(color: c.textDisabled),
                                filled: true,
                                fillColor: c.surface,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: EmsSpace.s5, vertical: 14),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.borderStrong)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.focus, width: 2)),
                              ),
                            ),
                          ),
                          const SizedBox(width: EmsSpace.s3),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton.filled(
                              tooltip: tr('m_send'),
                              onPressed: _sending || _input.text.trim().isEmpty ? null : _send,
                              style: IconButton.styleFrom(
                                backgroundColor: c.primary,
                                foregroundColor: c.onPrimary,
                                disabledBackgroundColor: c.bgSunken,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.sm)),
                              ),
                              icon: const Icon(PhosphorIconsRegular.paperPlaneRight, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EmsSpace.s3),
                      Text(tr('m_astraDisclaimer'), textAlign: TextAlign.center, style: context.type.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s5, vertical: EmsSpace.s4),
            decoration: BoxDecoration(color: c.primarySubtle, border: Border.all(color: c.primaryBorder), borderRadius: BorderRadius.circular(EmsRadius.md)),
            child: SelectableText(message.text, style: context.type.body.copyWith(color: c.text)),
          ),
        ),
      );
    }
    final rail = message.failed ? c.dangerSignal : c.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(message.failed ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.sparkle, size: 14, color: rail),
            const SizedBox(width: EmsSpace.s2),
            Text('ASTRA', style: context.type.monoSm.copyWith(color: rail)),
            const SizedBox(width: EmsSpace.s3),
            Text(EmsFormat.time(message.at), style: context.type.monoSm),
          ],
        ),
        const SizedBox(height: EmsSpace.s2),
        EmsRailBox(
          color: message.failed ? c.dangerSubtle : c.accentSubtle,
          borderColor: message.failed ? c.dangerBorder : c.border,
          railColor: rail,
          radius: EmsRadius.sm,
          padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s5, EmsSpace.s4),
          child: SelectableText(message.text, style: context.type.body.copyWith(color: c.text, height: 1.55)),
        ),
      ],
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Row(
      children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6, color: c.accent)),
        const SizedBox(width: EmsSpace.s3),
        Text(tr('m_astraThinking'), style: context.type.caption),
      ],
    );
  }
}
