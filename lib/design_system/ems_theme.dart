import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'ems_tokens.g.dart';

/// Acceso a los tokens del tema activo: `context.ems.primary`, `context.type.h2`.
class EmsTheme extends ThemeExtension<EmsTheme> {
  const EmsTheme(this.colors);

  final EmsColorSet colors;

  static EmsTheme of(BuildContext context) =>
      Theme.of(context).extension<EmsTheme>() ?? const EmsTheme(emsDark);

  @override
  EmsTheme copyWith({EmsColorSet? colors}) => EmsTheme(colors ?? this.colors);

  @override
  EmsTheme lerp(ThemeExtension<EmsTheme>? other, double t) =>
      (other is EmsTheme && t >= 0.5) ? other : this;
}

/// Estilos tipográficos de la escala compartida (Barlow SC / IBM Plex Sans / IBM Plex Mono).
class EmsType {
  const EmsType(this.c);
  final EmsColorSet c;

  TextStyle _s(EmsTypeSpec s, Color color) => TextStyle(
        fontFamily: s.font,
        fontSize: s.size,
        height: s.line / s.size,
        fontWeight: FontWeight.values[(s.weight ~/ 100) - 1],
        letterSpacing: s.tracking,
        color: color,
        fontFeatures: s.font == EmsFont.mono
            ? const [FontFeature.tabularFigures(), FontFeature.slashedZero()]
            : null,
      );

  TextStyle get display => _s(EmsTypeScale.display, c.text);
  TextStyle get h1 => _s(EmsTypeScale.h1, c.text);
  TextStyle get h2 => _s(EmsTypeScale.h2, c.text);
  TextStyle get h3 => _s(EmsTypeScale.h3, c.text);
  TextStyle get h4 => _s(EmsTypeScale.h4, c.text);

  /// Antetítulo: el texto se pasa en mayúsculas.
  TextStyle get eyebrow => _s(EmsTypeScale.eyebrow, c.textTertiary);
  TextStyle get label => _s(EmsTypeScale.label, c.textSecondary);
  TextStyle get bodyLg => _s(EmsTypeScale.bodyLg, c.text);
  TextStyle get body => _s(EmsTypeScale.body, c.text);
  TextStyle get bodySm => _s(EmsTypeScale.bodySm, c.textSecondary);
  TextStyle get caption => _s(EmsTypeScale.caption, c.textTertiary);
  TextStyle get metricXl => _s(EmsTypeScale.metricXl, c.text);
  TextStyle get metricLg => _s(EmsTypeScale.metricLg, c.text);
  TextStyle get metricMd => _s(EmsTypeScale.metricMd, c.text);
  TextStyle get mono => _s(EmsTypeScale.mono, c.textSecondary);
  TextStyle get monoSm => _s(EmsTypeScale.monoSm, c.textTertiary);
}

extension EmsContext on BuildContext {
  EmsColorSet get ems => EmsTheme.of(this).colors;
  EmsType get type => EmsType(ems);
}

/// Construye los ThemeData de Material 3 a partir de los tokens.
abstract final class EmsThemeData {
  static ThemeData light() => _build(emsLight, Brightness.light);
  static ThemeData dark() => _build(emsDark, Brightness.dark);

  static ThemeData _build(EmsColorSet c, Brightness b) {
    final t = EmsType(c);
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySubtle,
      onPrimaryContainer: c.primary,
      secondary: c.chrome,
      onSecondary: c.chromeText,
      tertiary: c.accent,
      onTertiary: c.textInverse,
      error: c.dangerSignal,
      onError: Colors.white,
      errorContainer: c.dangerSubtle,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceOverlay,
      outline: c.borderStrong,
      outlineVariant: c.border,
      shadow: Colors.black,
      scrim: c.scrim,
      inverseSurface: c.chrome,
      onInverseSurface: c.chromeText,
      inversePrimary: c.chromeAccent,
    );

    final shapeSm = RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.sm));
    const buttonText = TextStyle(fontFamily: EmsFont.body, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: EmsFont.body,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.border,
      splashFactory: InkSparkle.splashFactory,
      extensions: [EmsTheme(c)],
      textTheme: TextTheme(
        displayLarge: t.display,
        displayMedium: t.h1,
        displaySmall: t.h2,
        headlineLarge: t.h1,
        headlineMedium: t.h2,
        headlineSmall: t.h3,
        titleLarge: t.h3,
        titleMedium: t.h4,
        titleSmall: t.label.copyWith(color: c.text, fontWeight: FontWeight.w600),
        bodyLarge: t.bodyLg,
        bodyMedium: t.body,
        bodySmall: t.bodySm,
        labelLarge: t.label.copyWith(color: c.text),
        labelMedium: t.label,
        labelSmall: t.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t.h3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.borderSubtle,
          disabledForegroundColor: c.textDisabled,
          minimumSize: const Size(64, EmsSize.controlLg),
          padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s7),
          shape: shapeSm,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(64, EmsSize.controlLg),
          padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s7),
          side: BorderSide(color: c.borderStrong),
          shape: shapeSm,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(48, EmsSize.touchMin),
          shape: shapeSm,
          textStyle: buttonText.copyWith(fontSize: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: 0,
          minimumSize: const Size(64, EmsSize.controlLg),
          shape: shapeSm,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textSecondary,
          minimumSize: const Size(EmsSize.touchMin, EmsSize.touchMin),
          shape: shapeSm,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: EmsSpace.s5, vertical: EmsSpace.s5),
        hintStyle: t.body.copyWith(color: c.textTertiary),
        labelStyle: t.label,
        floatingLabelStyle: t.label.copyWith(color: c.primary),
        prefixIconColor: c.textTertiary,
        suffixIconColor: c.textTertiary,
        errorStyle: t.caption.copyWith(color: c.danger),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.borderStrong)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.borderStrong)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.dangerSignal)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.dangerSignal, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), borderSide: BorderSide(color: c.borderSubtle)),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmsRadius.md),
          side: BorderSide(color: c.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.md), side: BorderSide(color: c.border)),
        titleTextStyle: t.h3,
        contentTextStyle: t.body.copyWith(color: c.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(EmsRadius.lg))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: emsDark.chrome,
        contentTextStyle: t.bodySm.copyWith(color: emsDark.chromeText),
        actionTextColor: emsDark.chromeAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.sm), side: BorderSide(color: emsDark.chromeBorder)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimary : c.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.bgSunken),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.borderStrong),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.xs)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.bgSunken,
        circularTrackColor: c.bgSunken,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.text,
        titleTextStyle: t.body.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: t.caption,
        minVerticalPadding: EmsSpace.s4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primarySubtle,
        side: BorderSide(color: c.border),
        labelStyle: t.label.copyWith(color: c.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.sm)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: emsDark.chrome, borderRadius: BorderRadius.circular(EmsRadius.xs)),
        textStyle: t.caption.copyWith(color: emsDark.chromeText),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
