import 'package:flutter/material.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'subpage_scaffold.dart';

/// Change the client's own password. Backed by PATCH /api/client/password
/// (validates the current password server-side).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_next.text.length < 6) {
      _toast(tr('pw_tooShort'));
      return;
    }
    if (_next.text != _confirm.text) {
      _toast(tr('pw_mismatch'));
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthFacade.changePassword(_current.text, _next.text);
      if (!mounted) return;
      _toast(tr('pw_saved'));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: tr('pw_title'),
      subtitle: tr('pw_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassField(
            label: tr('pw_current'),
            controller: _current,
            obscure: true,
          ),
          const SizedBox(height: 16),
          GlassField(label: tr('pw_new'), controller: _next, obscure: true),
          const SizedBox(height: 16),
          GlassField(
            label: tr('pw_confirm'),
            controller: _confirm,
            obscure: true,
          ),
          const SizedBox(height: 26),
          GlassButton(
            label: tr('common_save'),
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }
}
