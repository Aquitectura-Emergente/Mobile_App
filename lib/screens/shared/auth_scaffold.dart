import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';

/// Estructura de las pantallas de acceso: marca, antetítulo, título, texto
/// de apoyo, regla graduada, contenido y acción fija abajo.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.intro,
    this.bottom,
    this.showBack = true,
    this.top,
    this.showLanguage = false,
  });

  final String title;
  final String? eyebrow;
  final String? intro;
  final Widget child;
  final Widget? bottom;
  final bool showBack;

  /// Sustituye la cabecera de marca (p. ej. un indicador de pasos).
  final Widget? top;
  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final canPop = showBack && Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: bottom == null,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(EmsSpace.s3, EmsSpace.s3, EmsSpace.s5, 0),
                  child: SizedBox(
                    height: EmsSize.touchMin,
                    child: Row(
                      children: [
                        if (canPop)
                          EmsIconButton(
                            icon: PhosphorIconsRegular.arrowLeft,
                            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                            onPressed: () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(width: EmsSpace.s4),
                        const EmsBrandMark(size: 24, wordmark: true),
                        const Spacer(),
                        if (showLanguage) const LanguageSwitch(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(EmsSpace.s7, EmsSpace.s6, EmsSpace.s7, EmsSpace.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (top != null) ...[top!, const SizedBox(height: EmsSpace.s7)],
                        if (eyebrow != null) ...[
                          Text(eyebrow!.toUpperCase(), style: context.type.eyebrow),
                          const SizedBox(height: EmsSpace.s3),
                        ],
                        Semantics(header: true, child: Text(title, style: context.type.h1)),
                        if (intro != null) ...[
                          const SizedBox(height: EmsSpace.s3),
                          Text(intro!, style: context.type.body.copyWith(color: c.textSecondary)),
                        ],
                        const SizedBox(height: EmsSpace.s5),
                        const EmsScaleRule(),
                        const SizedBox(height: EmsSpace.s7),
                        child,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : Container(
              decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.borderSubtle))),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(padding: const EdgeInsets.fromLTRB(EmsSpace.s7, EmsSpace.s4, EmsSpace.s7, EmsSpace.s4), child: bottom),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Conmutador ES / EN para las pantallas previas al acceso.
class LanguageSwitch extends StatefulWidget {
  const LanguageSwitch({super.key});

  @override
  State<LanguageSwitch> createState() => _LanguageSwitchState();
}

class _LanguageSwitchState extends State<LanguageSwitch> {
  @override
  void initState() {
    super.initState();
    I18n.lang.addListener(_onLang);
  }

  @override
  void dispose() {
    I18n.lang.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 104,
        child: EmsSegmented<String>(
          dense: true,
          value: I18n.lang.value,
          segments: const [('es', 'ES'), ('en', 'EN')],
          onChanged: I18n.set,
        ),
      );
}

/// Reconstruye su contenido cuando cambia el idioma.
class LanguageScope extends StatelessWidget {
  const LanguageScope({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: I18n.lang,
        builder: (context, _, _) => builder(context),
      );
}
