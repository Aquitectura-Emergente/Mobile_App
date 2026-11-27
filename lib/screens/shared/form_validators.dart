import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';

/// Validaciones de formulario alineadas con el backend (`RegisterRequest`,
/// `ChangePasswordRequest`): nombre y correo obligatorios, correo válido y
/// contraseña de al menos 6 caracteres. Lo demás es opcional y solo se revisa
/// el formato si se rellena.
abstract final class Validators {
  static const int minPassword = 6;
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? requiredName(String? v) => (v ?? '').trim().isEmpty ? tr('m_errNameRequired') : null;

  static String? required(String? v) => (v ?? '').trim().isEmpty ? tr('m_errRequired') : null;

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return tr('m_errEmailRequired');
    if (!_email.hasMatch(s)) return tr('m_errEmailFormat');
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return tr('m_errPwRequired');
    if (s.length < minPassword) return tr('m_errPwShort');
    return null;
  }

  /// Teléfono opcional: si se escribe, entre 6 y 15 dígitos.
  static String? optionalPhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^[+\d\s().-]+$').hasMatch(s)) return tr('m_errPhoneChars');
    final digits = s.replaceAll(RegExp(r'\D'), '').length;
    if (digits < 6 || digits > 15) return tr('m_errPhoneLength');
    return null;
  }
}

/// Indicador orientativo de la fortaleza de una contraseña. El backend solo
/// exige el mínimo de longitud; esto es una ayuda, no una regla.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});

  final String password;

  static int score(String p) {
    if (p.length < Validators.minPassword) return p.isEmpty ? 0 : 1;
    var s = 1;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final s = score(password);
    final (label, color) = switch (s) {
      0 => (tr('m_pwStrength0'), c.border),
      1 => (tr('m_pwStrength1'), c.dangerSignal),
      2 => (tr('m_pwStrength2'), c.warningSignal),
      3 => (tr('m_pwStrength3'), c.safeSignal),
      _ => (tr('m_pwStrength4'), c.safeSignal),
    };
    return Semantics(
      label: '${tr('m_pwStrength')}: $label',
      child: Row(
        children: [
          for (var i = 1; i <= 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: EmsDuration.base,
                height: 3,
                color: i <= s ? color : c.border,
              ),
            ),
            const SizedBox(width: 3),
          ],
          const SizedBox(width: EmsSpace.s3),
          SizedBox(width: 84, child: Text(label, textAlign: TextAlign.right, style: context.type.caption)),
        ],
      ),
    );
  }
}
