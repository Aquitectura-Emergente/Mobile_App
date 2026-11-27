import 'package:emsafe_app/design_system/ems_tokens.g.dart';
import 'package:emsafe_app/screens/etapa3/etapa3_components.dart';
import 'package:emsafe_app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Los alias de color (Etapa3Palette, AppTheme) deben seguir a los tokens del tema oscuro.
void main() {
  test('Etapa3Palette sigue a los tokens oscuros', () {
    expect(Etapa3Palette.bg, emsDark.bg);
    expect(Etapa3Palette.panel, emsDark.surface);
    expect(Etapa3Palette.panelSoft, emsDark.surfaceRaised);
    expect(Etapa3Palette.stroke, emsDark.border);
    expect(Etapa3Palette.cyan, emsDark.primary);
    expect(Etapa3Palette.blue, emsDark.info);
    expect(Etapa3Palette.text, emsDark.text);
    expect(Etapa3Palette.muted, emsDark.textSecondary);
    expect(Etapa3Palette.quiet, emsDark.textTertiary);
    expect(Etapa3Palette.green, emsDark.safeSignal);
    expect(Etapa3Palette.amber, emsDark.warningSignal);
    expect(Etapa3Palette.red, emsDark.dangerSignal);
  });

  test('AppTheme sigue a los tokens oscuros', () {
    expect(AppTheme.primaryCyan, emsDark.primary);
    expect(AppTheme.darkNavy, emsDark.bg);
    expect(AppTheme.darkBg, emsDark.chrome);
    expect(AppTheme.cardBg, emsDark.surface);
    expect(AppTheme.cardBorder, emsDark.border);
    expect(AppTheme.accentCyan, emsDark.live);
    expect(AppTheme.successGreen, emsDark.safeSignal);
    expect(AppTheme.warningOrange, emsDark.warningSignal);
    expect(AppTheme.errorRed, emsDark.dangerSignal);
  });
}
