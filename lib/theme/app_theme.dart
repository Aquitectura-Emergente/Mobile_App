import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Tema de la app: delega en el sistema de diseño EMSafe Calibre.
///
/// Las constantes de color se conservan como alias de los tokens del tema oscuro
/// (el tema por defecto de la app) para el código que pinta fuera de un contexto.
class AppTheme {
  static const Color primaryCyan = Color(0xFF9C96FF); // emsDark.primary
  static const Color primaryBlue = Color(0xFF9C96FF); // emsDark.primary
  static const Color darkNavy = Color(0xFF0D0F13); // emsDark.bg
  static const Color darkBg = Color(0xFF090B0E); // emsDark.chrome
  static const Color surfaceDark = Color(0xFF14171C); // emsDark.surface
  static const Color cardBg = Color(0xFF14171C); // emsDark.surface
  static const Color cardBorder = Color(0xFF272C34); // emsDark.border
  static const Color accentCyan = Color(0xFF4FD0E2); // emsDark.live
  static const Color successGreen = Color(0xFF3DB878); // emsDark.safeSignal
  static const Color warningOrange = Color(0xFFE8B21C); // emsDark.warningSignal
  static const Color errorRed = Color(0xFFF0544A); // emsDark.dangerSignal

  static ThemeData light() => EmsThemeData.light();

  static ThemeData dark() => EmsThemeData.dark();
}
