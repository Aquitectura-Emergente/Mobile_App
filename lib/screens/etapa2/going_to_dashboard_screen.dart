import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../routes/home_route.dart';
import '../../services/app_i18n.dart';

/// Transición breve tras desbloquear la sesión: resuelve el segmento de la
/// cuenta (hogar u operario) y abre su inicio.
class GoingToDashboardScreen extends StatefulWidget {
  const GoingToDashboardScreen({super.key});

  @override
  State<GoingToDashboardScreen> createState() => _GoingToDashboardScreenState();
}

class _GoingToDashboardScreenState extends State<GoingToDashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () async {
      final route = await homeRoute();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Scaffold(
      backgroundColor: c.chrome,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(EmsSpace.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmsBrandMark(size: 56),
                const SizedBox(height: EmsSpace.s7),
                SizedBox(width: 160, child: EmsScaleRule(color: c.chromeTextMuted)),
                const SizedBox(height: EmsSpace.s5),
                Text(tr('m_preparing').toUpperCase(), style: context.type.monoSm.copyWith(color: c.chromeTextMuted)),
                const SizedBox(height: EmsSpace.s5),
                SizedBox(width: 160, child: LinearProgressIndicator(minHeight: 2, color: c.chromeAccent, backgroundColor: c.chromeBorder)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
