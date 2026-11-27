import 'package:flutter/material.dart';

import '../../contexts/radiationmonitoring/domain/radiation_level.dart';
import '../../design_system/design_system.dart';
import '../../routes/app_routes.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_i18n.dart';
import '../shared/auth_scaffold.dart';
import '../shared/setup_guide.dart';

/// Bienvenida: primer contacto con EMSafe, sobre el cromo grafito de la marca.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageScope(builder: (context) {
      final c = context.ems;
      final points = [
        (PhosphorIconsRegular.waveSine, tr('m_welcome1')),
        (PhosphorIconsRegular.bellRinging, tr('m_welcome2')),
        (PhosphorIconsRegular.hardHat, tr('m_welcome3')),
      ];
      return Scaffold(
        backgroundColor: c.chrome,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(EmsSpace.s7, EmsSpace.s5, EmsSpace.s7, EmsSpace.s6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        EmsBrandMark(size: 26, wordmark: true, color: c.chromeText),
                        const Spacer(),
                        const LanguageSwitch(),
                      ],
                    ),
                    const Spacer(),
                    Text(tr('m_welcomeEyebrow').toUpperCase(), style: context.type.eyebrow.copyWith(color: c.chromeAccent)),
                    const SizedBox(height: EmsSpace.s4),
                    Text(tr('m_welcomeTitle'), style: context.type.display.copyWith(color: c.chromeText, fontSize: 40, height: 1.05)),
                    const SizedBox(height: EmsSpace.s5),
                    Text(tr('m_welcomeIntro'), style: context.type.bodyLg.copyWith(color: c.chromeTextMuted)),
                    const SizedBox(height: EmsSpace.s6),
                    EmsScaleRule(color: c.chromeTextMuted),
                    const SizedBox(height: EmsSpace.s6),
                    for (final (icon, text) in points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: EmsSpace.s4),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(EmsRadius.sm), border: Border.all(color: c.chromeBorder)),
                              child: Icon(icon, size: 18, color: c.chromeAccent),
                            ),
                            const SizedBox(width: EmsSpace.s4),
                            Expanded(child: Text(text, style: context.type.body.copyWith(color: c.chromeText))),
                          ],
                        ),
                      ),
                    const Spacer(),
                    EmsButton(
                      label: tr('m_getStarted'),
                      icon: PhosphorIconsRegular.arrowRight,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.onboardingSmartAlerts),
                    ),
                    const SizedBox(height: EmsSpace.s3),
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(EmsSize.touchMin)),
                      onPressed: () => Navigator.of(context).pushNamed(Etapa2Routes.login),
                      child: Text(tr('m_haveAccount'), style: context.type.label.copyWith(color: c.chromeText, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Presentación en tres láminas. Las ilustraciones usan el lenguaje del
/// sistema (escala, niveles, relé) sin cifras inventadas.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialPage = 0});

  final int initialPage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pages = PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;
  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _count - 1) {
      _pages.nextPage(duration: EmsDuration.slow, curve: Curves.easeOutCubic);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.onboardingFinalStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(builder: (context) {
      final c = context.ems;
      final slides = [
        _Slide(eyebrow: tr('m_ob1Eyebrow'), title: tr('m_ob1Title'), body: tr('m_ob1Body'), art: const _ArtLevels()),
        _Slide(eyebrow: tr('m_ob2Eyebrow'), title: tr('m_ob2Title'), body: tr('m_ob2Body'), art: const _ArtActuator()),
        _Slide(eyebrow: tr('m_ob3Eyebrow'), title: tr('m_ob3Title'), body: tr('m_ob3Body'), art: const _ArtSegments()),
      ];
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(EmsSpace.s3, EmsSpace.s3, EmsSpace.s5, 0),
                    child: SizedBox(
                      height: EmsSize.touchMin,
                      child: Row(
                        children: [
                          EmsIconButton(icon: PhosphorIconsRegular.arrowLeft, tooltip: MaterialLocalizations.of(context).backButtonTooltip, onPressed: () => Navigator.of(context).maybePop()),
                          Text('${(_page + 1).toString().padLeft(2, '0')} / ${_count.toString().padLeft(2, '0')}', style: context.type.monoSm),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.onboardingFinalStep),
                            child: Text(tr('m_skip')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (p) => setState(() => _page = p),
                      children: slides,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(EmsSpace.s7, EmsSpace.s4, EmsSpace.s7, EmsSpace.s6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < _count; i++) ...[
                              Expanded(
                                child: AnimatedContainer(
                                  duration: EmsDuration.base,
                                  height: 3,
                                  color: i <= _page ? c.primary : c.border,
                                ),
                              ),
                              if (i < _count - 1) const SizedBox(width: 4),
                            ],
                          ],
                        ),
                        const SizedBox(height: EmsSpace.s6),
                        EmsButton(
                          label: _page == _count - 1 ? tr('m_continue') : tr('m_next'),
                          icon: PhosphorIconsRegular.arrowRight,
                          onPressed: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.eyebrow, required this.title, required this.body, required this.art});

  final String eyebrow;
  final String title;
  final String body;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(EmsSpace.s7, EmsSpace.s6, EmsSpace.s7, EmsSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 250, child: art),
          const SizedBox(height: EmsSpace.s8),
          Text(eyebrow.toUpperCase(), style: context.type.eyebrow.copyWith(color: context.ems.primary)),
          const SizedBox(height: EmsSpace.s3),
          Text(title, style: context.type.h1),
          const SizedBox(height: EmsSpace.s4),
          Text(body, style: context.type.bodyLg.copyWith(color: context.ems.textSecondary)),
        ],
      ),
    );
  }
}

/// Lámina 1: escala de niveles con los umbrales reales.
class _ArtLevels extends StatelessWidget {
  const _ArtLevels();

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final rows = [
      (c.safeSignal, tr('m_lvSafe'), '< ${cautionThresholdUT.toStringAsFixed(0)} µT', PhosphorIconsRegular.checkCircle),
      (c.warningSignal, tr('m_lvCaution'), '${cautionThresholdUT.toStringAsFixed(0)}–${dangerThresholdUT.toStringAsFixed(0)} µT', PhosphorIconsRegular.warning),
      (c.dangerSignal, tr('m_lvDanger'), '≥ ${dangerThresholdUT.toStringAsFixed(0)} µT', PhosphorIconsRegular.warningOctagon),
    ];
    return Container(
      padding: const EdgeInsets.all(EmsSpace.s6),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.lg)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.waveSine, color: c.primary, size: 20),
              const SizedBox(width: EmsSpace.s3),
              Text(tr('m_artField').toUpperCase(), style: context.type.eyebrow),
            ],
          ),
          for (final (color, label, range, icon) in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s4, vertical: EmsSpace.s3),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: EmsBorder.rail)), color: c.bgSunken),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: EmsSpace.s3),
                  Expanded(child: Text(label, style: context.type.body.copyWith(fontWeight: FontWeight.w600))),
                  Text(range, style: context.type.mono),
                ],
              ),
            ),
          const EmsScaleRule(height: 9),
        ],
      ),
    );
  }
}

/// Lámina 2: del aviso de peligro a la orden al enchufe y su confirmación.
class _ArtActuator extends StatelessWidget {
  const _ArtActuator();

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    Widget node(IconData icon, String label, Color color) => Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: c.bgSunken, borderRadius: BorderRadius.circular(EmsRadius.md), border: Border.all(color: color, width: 1.5)),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: EmsSpace.s3),
              Text(label, textAlign: TextAlign.center, maxLines: 2, style: context.type.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        );
    Widget link() => Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Icon(PhosphorIconsRegular.arrowRight, size: 18, color: c.textTertiary),
        );
    return Container(
      padding: const EdgeInsets.all(EmsSpace.s5),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.lg)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                node(PhosphorIconsRegular.broadcast, tr('m_artSensor'), c.dangerSignal),
                link(),
                node(PhosphorIconsRegular.deviceMobile, tr('m_artYouDecide'), c.primary),
                link(),
                node(PhosphorIconsRegular.plug, tr('m_artPlug'), c.safeSignal),
              ],
            ),
          ),
          EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.hourglassMedium, message: tr('m_artPending')),
        ],
      ),
    );
  }
}

/// Lámina 3: hogar, operario industrial y el asistente ASTRA (IA, cobre).
class _ArtSegments extends StatelessWidget {
  const _ArtSegments();

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    Widget card(IconData icon, String title, String body, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(EmsSpace.s4),
            decoration: BoxDecoration(color: c.bgSunken, borderRadius: BorderRadius.circular(EmsRadius.md), border: Border.all(color: c.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(title, style: context.type.h4),
                const SizedBox(height: EmsSpace.s2),
                Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.type.caption),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(EmsSpace.s5),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(EmsRadius.lg)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                card(PhosphorIconsRegular.house, tr('m_segHome'), tr('m_artHome'), c.primary),
                const SizedBox(width: EmsSpace.s4),
                card(PhosphorIconsRegular.hardHat, tr('m_segOperator'), tr('m_artOperator'), c.live),
              ],
            ),
          ),
          const SizedBox(height: EmsSpace.s4),
          EmsRailBox(
            color: c.accentSubtle,
            borderColor: c.border,
            railColor: c.accent,
            padding: const EdgeInsets.all(EmsSpace.s4),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.sparkle, color: c.accent, size: 18),
                const SizedBox(width: EmsSpace.s3),
                Expanded(child: Text(tr('m_artAstra'), style: context.type.bodySm.copyWith(color: c.text))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Último paso: cómo seguir según quién eres.
class OnboardingChoiceScreen extends StatelessWidget {
  const OnboardingChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageScope(builder: (context) {
      return AuthScaffold(
        eyebrow: tr('m_choiceEyebrow'),
        title: tr('m_choiceTitle'),
        intro: tr('m_choiceIntro'),
        showLanguage: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Choice(
              icon: PhosphorIconsRegular.userPlus,
              title: tr('m_choiceNew'),
              body: tr('m_choiceNewMsg'),
              primary: true,
              onTap: () => Navigator.of(context).pushNamed(Etapa2Routes.personalDetails),
            ),
            const SizedBox(height: EmsSpace.s4),
            _Choice(
              icon: PhosphorIconsRegular.signIn,
              title: tr('m_choiceLogin'),
              body: tr('m_choiceLoginMsg'),
              onTap: () => Navigator.of(context).pushNamed(Etapa2Routes.login),
            ),
            const SizedBox(height: EmsSpace.s4),
            _Choice(
              icon: PhosphorIconsRegular.hardHat,
              title: tr('m_choiceOperator'),
              body: tr('m_choiceOperatorMsg'),
              onTap: () => Navigator.of(context).pushNamed(Etapa2Routes.login),
            ),
            const SizedBox(height: EmsSpace.s7),
            EmsDrillLink(label: tr('m_howInstall'), onTap: () => Navigator.of(context).pushNamed(AppRoutes.pairingSensors)),
          ],
        ),
      );
    });
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.title, required this.body, required this.onTap, this.primary = false});

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Material(
      color: primary ? c.primarySubtle : c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.md), side: BorderSide(color: primary ? c.primaryBorder : c.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(EmsRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(EmsSpace.s5),
          child: Row(
            children: [
              Icon(icon, size: 24, color: primary ? c.primary : c.textSecondary),
              const SizedBox(width: EmsSpace.s5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.type.h4),
                    const SizedBox(height: EmsSpace.s2),
                    Text(body, style: context.type.bodySm),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guía de instalación previa al alta (antes "emparejar sensores").
class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: tr('m_setupEyebrow'),
      title: tr('m_howInstall'),
      intro: tr('m_setupIntro'),
      bottom: EmsButton(
        label: tr('m_createAccount'),
        icon: PhosphorIconsRegular.userPlus,
        onPressed: () => Navigator.of(context).pushNamed(Etapa2Routes.personalDetails),
      ),
      child: const SetupGuideContent(),
    );
  }
}
