import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../routes/home_route.dart';

/// Going to dashboard (Etapa 2)
/// Flujo: muestra un estado de progreso y redirige automáticamente.
/// Refactor clave:
/// - Sin artboard rígido
/// - Sin Positioned con `top`/`left` calculados a mano
/// - Layout 100% flexible (Column + SpaceBetween)
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
    _timer = Timer(const Duration(seconds: 3), () async {
      final route = await homeRoute();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double scale = (size.width / 390).clamp(0.85, 1.10);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1117), Color(0xFF0D1117)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 420 * scale,
                height: 420 * scale,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(101, 218, 255, 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            left: -140 * scale,
            top: 140 * scale,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(140 * scale),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 60 * scale,
                    sigmaY: 60 * scale,
                  ),
                  child: Container(
                    width: 300 * scale,
                    height: 300 * scale,
                    color: const Color.fromRGBO(101, 218, 255, 0.05),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -140 * scale,
            bottom: 120 * scale,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(140 * scale),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 50 * scale,
                    sigmaY: 50 * scale,
                  ),
                  child: Container(
                    width: 280 * scale,
                    height: 280 * scale,
                    color: const Color.fromRGBO(178, 197, 255, 0.06),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(scale),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMainCard(scale),
                              SizedBox(height: 18 * scale),
                              _ProtoLine(scale: scale),
                            ],
                          ),
                          _buildFooter(scale),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 8 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16 * scale,
                height: 20 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFB2C5FF),
                  borderRadius: BorderRadius.circular(4 * scale),
                ),
              ),
              SizedBox(width: 12 * scale),
              Text(
                'EmSafe',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 20 * scale,
                  color: const Color(0xFFB2C5FF),
                  letterSpacing: -0.5 * scale,
                ),
              ),
            ],
          ),
          SizedBox(width: 32.72 * scale, height: 24 * scale),
        ],
      ),
    );
  }

  Widget _buildMainCard(double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24 * scale),
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(22, 27, 34, 0.35),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: const Color.fromRGBO(140, 144, 161, 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 190 * scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18 * scale),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10 * scale,
                  sigmaY: 10 * scale,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromRGBO(0, 192, 233, 0.08),
                        const Color.fromRGBO(178, 197, 255, 0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.medical_services_outlined,
                      color: const Color(0xFF65DAFF),
                      size: 92 * scale,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 18 * scale),
          _StatusBox(scale: scale),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: 260 * scale,
            child: const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Color(0xFF32343E),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65DAFF)),
            ),
          ),
          SizedBox(height: 12 * scale),
          Text(
            'Opening dashboard...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16 * scale,
              color: const Color(0xFFC2C6D8).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double scale) {
    return SizedBox(
      height: 40 * scale,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: 0.6,
          child: Text(
            'Session authenticated',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 14 * scale,
              color: const Color(0xFFC2C6D8),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10 * scale, sigmaY: 10 * scale),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(22, 27, 34, 0.4),
            borderRadius: BorderRadius.circular(30 * scale),
            border: Border.all(
              color: const Color.fromRGBO(66, 70, 85, 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFF65DAFF),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12 * scale),
              Text(
                'AUTHENTICATED',
                style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontWeight: FontWeight.w600,
                  fontSize: 12 * scale,
                  letterSpacing: 1.2 * scale,
                  color: const Color(0xFF65DAFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtoLine extends StatelessWidget {
  const _ProtoLine({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(22, 27, 34, 0.35),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: const Color.fromRGBO(66, 70, 85, 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROTOCOL',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w500,
                fontSize: 11 * scale,
                letterSpacing: 1.0 * scale,
                color: const Color(0xFF8C90A1),
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              'Dashboard route ready',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w500,
                fontSize: 12 * scale,
                color: const Color(0xFFB2C5FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
