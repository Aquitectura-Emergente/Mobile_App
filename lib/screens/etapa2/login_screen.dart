import 'package:flutter/material.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../routes/etapa2_routes.dart';
import '../../routes/home_route.dart';
import '../../services/app_i18n.dart';
import '../shared/auth_scaffold.dart';
import '../shared/form_validators.dart';

/// Acceso con correo y contraseña (`POST /api/auth/login`). Explica los
/// rechazos que da el backend: cuenta pendiente, desactivada o bloqueada por
/// intentos, y cuentas que no son de cliente.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginIssue { pending, locked, other }

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  _LoginIssue _issue = _LoginIssue.other;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthFacade.login(_emailController.text.trim(), _passwordController.text);
      final route = await homeRoute();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      final m = e.message.toLowerCase();
      setState(() {
        if (m.contains('pending')) {
          _issue = _LoginIssue.pending;
          _error = tr('m_loginPending');
        } else if (m.contains('locked')) {
          _issue = _LoginIssue.locked;
          _error = e.message;
        } else if (m.contains('web portal')) {
          // Admin de pruebas aparte, el responsable de SSO y el técnico usan el portal web.
          _issue = _LoginIssue.other;
          _error = tr('m_loginPortalOnly');
        } else {
          _issue = _LoginIssue.other;
          _error = e.statusCode == 401 || m.contains('invalid') ? tr('m_loginInvalid') : (e.statusCode == null ? tr('m_errNetwork') : e.message);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _issue = _LoginIssue.other;
        _error = tr('m_errNetwork');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      builder: (context) {
        final c = context.ems;
        return AuthScaffold(
          showBack: false,
          showLanguage: true,
          eyebrow: tr('m_loginEyebrow'),
          title: tr('m_loginTitle'),
          intro: tr('m_loginIntro'),
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EmsField(
                    label: tr('m_email'),
                    hint: tr('m_emailHint'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    icon: PhosphorIconsRegular.envelopeSimple,
                    autofillHints: const [AutofillHints.email, AutofillHints.username],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: EmsSpace.s6),
                  EmsField(
                    label: tr('m_password'),
                    controller: _passwordController,
                    obscure: true,
                    icon: PhosphorIconsRegular.lockSimple,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v ?? '').isEmpty ? tr('m_errPwRequired') : null,
                    onSubmitted: (_) => _signIn(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(0, EmsSize.touchMin)),
                      onPressed: () => Navigator.of(context).pushNamed(Etapa2Routes.resetPassword),
                      child: Text(tr('m_forgot'), style: context.type.label.copyWith(color: c.primary)),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: EmsSpace.s3),
                    EmsBanner(
                      tone: _issue == _LoginIssue.pending ? EmsTone.info : (_issue == _LoginIssue.locked ? EmsTone.warning : EmsTone.danger),
                      icon: _issue == _LoginIssue.pending
                          ? PhosphorIconsRegular.hourglassMedium
                          : (_issue == _LoginIssue.locked ? PhosphorIconsRegular.lockKey : PhosphorIconsRegular.warningCircle),
                      title: _issue == _LoginIssue.pending ? tr('m_pendingTitle') : null,
                      message: _error!,
                      action: _issue == _LoginIssue.pending
                          ? TextButton(
                              onPressed: () => Navigator.of(context).pushNamed(Etapa2Routes.verifyIdentity),
                              child: Text(tr('m_whatNext')),
                            )
                          : null,
                    ),
                  ],
                  const SizedBox(height: EmsSpace.s6),
                  EmsButton(label: tr('m_signIn'), icon: PhosphorIconsRegular.signIn, loading: _loading, onPressed: _signIn),
                  const SizedBox(height: EmsSpace.s9),
                  Divider(color: c.border, height: 1),
                  const SizedBox(height: EmsSpace.s6),
                  Text(tr('m_newHere').toUpperCase(), style: context.type.eyebrow),
                  const SizedBox(height: EmsSpace.s3),
                  EmsButton(
                    label: tr('m_createAccount'),
                    icon: PhosphorIconsRegular.userPlus,
                    kind: EmsButtonKind.ghost,
                    onPressed: () => Navigator.of(context).pushNamed(Etapa2Routes.personalDetails),
                  ),
                  const SizedBox(height: EmsSpace.s4),
                  Text(tr('m_operatorLoginNote'), textAlign: TextAlign.center, style: context.type.caption),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
