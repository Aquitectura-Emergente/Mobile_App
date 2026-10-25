import 'package:flutter/material.dart';

import '../../contexts/clientportal/application/astra_facade.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'etapa3_components.dart';
import 'subpage_scaffold.dart';

class _ChatMessage {
  _ChatMessage(this.role, this.text); // role: 'user' | 'model'
  final String role;
  final String text;
}

/// "Astra" — the EMSafe AI assistant (US10). The conversation is proxied
/// through the backend (POST /api/client/chat → Gemini), grounded with the
/// client's real sensor data.
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
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    // History sent to the backend excludes the local welcome message.
    final history = _messages
        .skip(1)
        .map((m) => {'role': m.role, 'text': m.text})
        .toList();

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
      setState(() => _messages.add(_ChatMessage('model', e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage('model', tr('chat_error'))));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: tr('chat_title'),
      subtitle: tr('chat_subtitle'),
      scrollable: false,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              itemCount: _messages.length + (_sending ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == _messages.length) return const _TypingBubble();
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(
                      color: Etapa3Palette.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('chat_hint'),
                    hintStyle: const TextStyle(
                        color: Etapa3Palette.quiet, fontSize: 13),
                    filled: true,
                    fillColor: Etapa3Palette.panelSoft,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: Etapa3Palette.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: Etapa3Palette.cyan),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                height: 46,
                child: FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor:
                        Etapa3Palette.cyan.withValues(alpha: 0.16),
                    foregroundColor: Etapa3Palette.cyan,
                    side: BorderSide(
                        color: Etapa3Palette.cyan.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23)),
                  ),
                  child: const Icon(Icons.send_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Etapa3Palette.blue.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Etapa3Palette.blue.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Etapa3Palette.blue, size: 15),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isUser
                  ? Etapa3Palette.cyan.withValues(alpha: 0.14)
                  : Etapa3Palette.panelSoft,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 3),
                bottomRight: Radius.circular(isUser ? 3 : 14),
              ),
              border: Border.all(
                color: isUser
                    ? Etapa3Palette.cyan.withValues(alpha: 0.3)
                    : Etapa3Palette.stroke,
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: Etapa3Palette.text,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Etapa3Palette.blue.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome,
              color: Etapa3Palette.blue, size: 15),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Etapa3Palette.panelSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Etapa3Palette.stroke),
          ),
          child: const SizedBox(
            width: 28,
            height: 10,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFF32343E),
              valueColor:
                  AlwaysStoppedAnimation<Color>(Etapa3Palette.cyan),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}
