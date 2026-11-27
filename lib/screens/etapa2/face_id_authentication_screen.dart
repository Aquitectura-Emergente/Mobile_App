import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../contexts/iam/infrastructure/session_store.dart';
import '../../design_system/design_system.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_i18n.dart';
import '../shared/auth_scaffold.dart';

enum _BioState { checking, ready, unavailable, authenticating, failed, noSession }

/// Desbloqueo biométrico de una sesión ya iniciada en este dispositivo.
///
/// La biometría no sustituye al login: solo abre la sesión guardada cuando el
/// usuario activó el bloqueo en Ajustes. Sin sesión, remite al acceso con
/// correo y contraseña.
class FaceIdAuthenticationScreen extends StatefulWidget {
  const FaceIdAuthenticationScreen({super.key});

  @override
  State<FaceIdAuthenticationScreen> createState() => _FaceIdAuthenticationScreenState();
}

class _FaceIdAuthenticationScreenState extends State<FaceIdAuthenticationScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  _BioState _state = _BioState.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (!await SessionStore.isLoggedIn()) {
      if (mounted) setState(() => _state = _BioState.noSession);
      return;
    }
    if (kIsWeb) {
      if (mounted) setState(() => _state = _BioState.unavailable);
      return;
    }
    try {
      final ok = await _auth.canCheckBiometrics && await _auth.isDeviceSupported() && (await _auth.getAvailableBiometrics()).isNotEmpty;
      if (!mounted) return;
      setState(() => _state = ok ? _BioState.ready : _BioState.unavailable);
      if (ok) _authenticate();
    } catch (_) {
      if (mounted) setState(() => _state = _BioState.unavailable);
    }
  }

  Future<void> _authenticate() async {
    setState(() => _state = _BioState.authenticating);
    try {
      final ok = await _auth.authenticate(
        localizedReason: tr('m_bioReason'),
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacementNamed(Etapa2Routes.goingToDashboard);
      } else {
        setState(() => _state = _BioState.failed);
      }
    } catch (_) {
      if (mounted) setState(() => _state = _BioState.failed);
    }
  }

  /// Entrar con contraseña cierra la sesión guardada.
  Future<void> _usePassword() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Etapa2Routes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final (icon, tone, title, msg) = switch (_state) {
      _BioState.checking => (PhosphorIconsRegular.fingerprint, EmsTone.neutral, tr('m_bioChecking'), tr('m_bioCheckingMsg')),
      _BioState.ready || _BioState.authenticating => (PhosphorIconsRegular.fingerprint, EmsTone.primary, tr('m_bioReady'), tr('m_bioReadyMsg')),
      _BioState.failed => (PhosphorIconsRegular.xCircle, EmsTone.danger, tr('m_bioFailed'), tr('m_bioFailedMsg')),
      _BioState.unavailable => (PhosphorIconsRegular.warningCircle, EmsTone.warning, tr('m_bioUnavailable'), tr('m_bioUnavailableMsg')),
      _BioState.noSession => (PhosphorIconsRegular.lockKey, EmsTone.info, tr('m_bioNoSession'), tr('m_bioNoSessionMsg')),
    };
    final t = emsTone(context, tone);
    return AuthScaffold(
      showBack: _state == _BioState.noSession,
      eyebrow: tr('m_bioEyebrow'),
      title: tr('m_bioTitle'),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_state == _BioState.failed || _state == _BioState.ready)
            EmsButton(label: tr('m_bioRetry'), icon: PhosphorIconsRegular.fingerprint, onPressed: _authenticate),
          if (_state == _BioState.failed || _state == _BioState.ready) const SizedBox(height: EmsSpace.s3),
          EmsButton(
            label: _state == _BioState.noSession ? tr('m_goToLogin') : tr('m_usePassword'),
            kind: _state == _BioState.noSession || _state == _BioState.unavailable ? EmsButtonKind.primary : EmsButtonKind.secondary,
            icon: PhosphorIconsRegular.password,
            onPressed: _state == _BioState.checking || _state == _BioState.authenticating ? null : _usePassword,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: EmsSpace.s5),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(EmsRadius.lg),
              border: Border.all(color: t.border, width: 1.5),
            ),
            child: _state == _BioState.authenticating || _state == _BioState.checking
                ? Padding(padding: const EdgeInsets.all(44), child: CircularProgressIndicator(strokeWidth: 2, color: t.fg))
                : Icon(icon, size: 60, color: t.fg),
          ),
          const SizedBox(height: EmsSpace.s7),
          Text(title, textAlign: TextAlign.center, style: context.type.h3),
          const SizedBox(height: EmsSpace.s3),
          Text(msg, textAlign: TextAlign.center, style: context.type.body.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
