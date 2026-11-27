import 'package:flutter/material.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../shared/form_validators.dart';

/// Cambia la contraseña propia (PATCH /api/client/password; el backend valida
/// la actual).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthFacade.changePassword(_current.text, _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('pw_saved'))));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmsPage(
      eyebrow: tr('set_account'),
      title: tr('pw_title'),
      bottom: EmsButton(label: tr('m_updatePassword'), icon: PhosphorIconsRegular.lockKey, loading: _saving, onPressed: _save),
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                EmsBanner(tone: EmsTone.danger, icon: PhosphorIconsRegular.warningCircle, message: _error!),
                const SizedBox(height: EmsSpace.s5),
              ],
              EmsField(
                label: tr('pw_current'),
                controller: _current,
                obscure: true,
                icon: PhosphorIconsRegular.lockKey,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                validator: (v) => (v ?? '').isEmpty ? tr('m_errRequired') : null,
              ),
              const SizedBox(height: EmsSpace.s7),
              EmsField(
                label: tr('pw_new'),
                controller: _next,
                obscure: true,
                icon: PhosphorIconsRegular.password,
                helper: tr('m_pwHelp'),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                validator: Validators.password,
              ),
              const SizedBox(height: EmsSpace.s3),
              PasswordStrength(password: _next.text),
              const SizedBox(height: EmsSpace.s6),
              EmsField(
                label: tr('pw_confirm'),
                controller: _confirm,
                obscure: true,
                icon: PhosphorIconsRegular.password,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => v != _next.text ? tr('pw_mismatch') : null,
                onSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
