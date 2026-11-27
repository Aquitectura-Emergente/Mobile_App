import 'dart:async';

import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../routes/etapa2_routes.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';

class SplashOfficialBrandScreen extends StatelessWidget {
  const SplashOfficialBrandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SplashContent();
  }
}

class _SplashContent extends StatefulWidget {
  const _SplashContent();

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _connectionController;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;

  bool _hasNavigated = false;
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Auto navegación: se cancela si el usuario toca el footer.
    _autoNavTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed(AppRoutes.splashUpdated);
    });
  }

  void _skipOnboardingAndGoToStage2() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _autoNavTimer?.cancel();
    Navigator.of(context).pushNamed(Etapa2Routes.login);
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _connectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Scaffold(
      backgroundColor: c.chrome,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(EmsSpace.s7, EmsSpace.s7, EmsSpace.s7, EmsSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: _logoScale,
                alignment: Alignment.centerLeft,
                child: const EmsBrandMark(size: 40, wordmark: true, color: EmsDarkColors.chromeText),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: EmsSpace.s4),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: EmsDarkColors.chromeAccent, width: EmsBorder.rail)),
                      ),
                      child: Text(tr('m_splashEyebrow').toUpperCase(), style: context.type.eyebrow.copyWith(color: c.chromeTextMuted)),
                    ),
                    const SizedBox(height: EmsSpace.s6),
                    Text(
                      tr('m_splash1').toUpperCase(),
                      style: context.type.display.copyWith(color: c.chromeText, fontSize: 38, height: 1.05),
                    ),
                    Text(
                      tr('m_splash2').toUpperCase(),
                      style: context.type.display.copyWith(color: c.chromeTextMuted, fontSize: 38, height: 1.05),
                    ),
                    const SizedBox(height: EmsSpace.s8),
                    _ExposureScale(controller: _connectionController),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.35, end: 1).animate(_connectionController),
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: EmsDarkColors.liveSignal)),
                  ),
                  const SizedBox(width: EmsSpace.s3),
                  Text(tr('m_splashLoading').toUpperCase(), style: context.type.monoSm.copyWith(color: c.chromeTextMuted)),
                ],
              ),
              const SizedBox(height: EmsSpace.s5),
              Divider(color: c.chromeBorder, height: 1),
              const SizedBox(height: EmsSpace.s3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text('${tr('m_haveAccountQ')} ', style: context.type.bodySm.copyWith(color: c.chromeTextMuted)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.chromeAccent),
                    onPressed: _skipOnboardingAndGoToStage2,
                    child: Text(tr('m_signIn')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Escala de exposición animada: zonas segura / advertencia / límite.
class _ExposureScale extends StatelessWidget {
  const _ExposureScale({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 14, child: CustomPaint(painter: EmsScalePainter(c.chromeTextMuted, major: 4, minor: 40))),
        const SizedBox(height: EmsSpace.s2),
        SizedBox(
          height: 4,
          child: Row(
            children: [
              Expanded(flex: 60, child: Container(color: c.safeSignal)),
              Expanded(flex: 25, child: Container(color: c.warningSignal)),
              Expanded(flex: 15, child: Container(color: c.dangerSignal)),
            ],
          ),
        ),
        const SizedBox(height: EmsSpace.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in const ['0', '25', '50', '75', '100%'])
              Text(l, style: context.type.monoSm.copyWith(color: c.chromeTextMuted)),
          ],
        ),
      ],
    );
  }
}
