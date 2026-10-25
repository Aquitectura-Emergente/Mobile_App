import 'dart:ui';

import 'package:flutter/material.dart';

import '../../routes/etapa2_routes.dart';
import '../../routes/etapa3_routes.dart';
import '../../contexts/iam/application/auth_facade.dart';
import '../../core/http/api_client.dart';

/// Login (Etapa 2) — now wired to the real backend (/api/auth/login).
/// Responsive + compacto y fiel a Figma (sin alturas rígidas).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthFacade.login(email, password);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Etapa3Routes.dashboardOverview, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double scale = (size.width / 390).clamp(0.85, 1.15);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Stack(
        children: [
          // 1) Fondo ambiental
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 450 * scale,
                height: 450 * scale,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(178, 197, 255, 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // 2) Contenido con scroll adaptable (evita overflows con teclado)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24 * scale,
                    vertical: 24 * scale,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (48 * scale),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16 * scale),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x0D161B22),
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(
                                  color: const Color.fromRGBO(
                                    140,
                                    144,
                                    161,
                                    0.15,
                                  ),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 40 * scale,
                                    offset: Offset(0, 20 * scale),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24 * scale),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Encabezado
                                    Text(
                                      'Secure Access',
                                      style: TextStyle(
                                        fontSize: 28 * scale,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                        color: const Color(0xFFB2C5FF),
                                        fontFamily: 'Sora',
                                      ),
                                    ),
                                    SizedBox(height: 10 * scale),
                                    Text(
                                      'Identify yourself to manage secure protocols and hardware.',
                                      style: TextStyle(
                                        fontSize: 14 * scale,
                                        height: 1.4,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFFC2C6D8),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    SizedBox(height: 28 * scale),

                                    // --- Inputs reales ---
                                    _FieldBlock(
                                      label: 'EMAIL ADDRESS',
                                      hintText: 'ops@quantumdyn.com',
                                      suffixIcon: Icons.mail_outline,
                                      isEmail: true,
                                      controller: _emailController,
                                    ),
                                    SizedBox(height: 20 * scale),
                                    _FieldBlock(
                                      label: 'PASSWORD',
                                      hintText: '••••••••••••••',
                                      suffixIcon: Icons.lock_outline,
                                      isPassword: true,
                                      controller: _passwordController,
                                      onSubmitted: (_) => _signIn(),
                                    ),

                                    // Mensaje de error
                                    if (_error != null) ...[
                                      SizedBox(height: 16 * scale),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(12 * scale),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              255, 91, 110, 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8 * scale),
                                          border: Border.all(
                                            color: const Color.fromRGBO(
                                                255, 91, 110, 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Color(0xFFFF5B6E),
                                              size: 18,
                                            ),
                                            SizedBox(width: 10 * scale),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: TextStyle(
                                                  color: const Color(0xFFFFB3BC),
                                                  fontFamily: 'Inter',
                                                  fontSize: 13 * scale,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 24 * scale),

                                    // Botón principal -> login real
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56 * scale,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _signIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF5B8CFF,
                                          ),
                                          disabledBackgroundColor:
                                              const Color(0xFF35527F),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8 * scale,
                                            ),
                                          ),
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Color(0xFF002565),
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontFamily: 'Sora',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16 * scale,
                                                  color: const Color(0xFF002565),
                                                ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(height: 20 * scale),

                                    // Alternativas: Face ID / Reset Password
                                    _buildAlternativePaths(context, scale),
                                    SizedBox(height: 24 * scale),

                                    // Footer
                                    _buildFooter(context, scale),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildAlternativePaths(BuildContext context, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Face ID
        SizedBox(
          height: 56 * scale,
          child: InkWell(
            onTap: () {
              Navigator.of(
                context,
              ).pushNamed(Etapa2Routes.faceIdAuthentication);
            },
            borderRadius: BorderRadius.circular(8 * scale),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 14 * scale,
                horizontal: 16 * scale,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromRGBO(66, 70, 85, 0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8 * scale),
                color: const Color(0x0AFFFFFF),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    color: const Color(0xFFB2C5FF),
                    size: 22 * scale,
                  ),
                  SizedBox(width: 12 * scale),
                  Text(
                    'Authentication with Face ID',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14 * scale,
                      color: const Color(0xFFE1E2EE),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12 * scale),

        // Reset Password
        SizedBox(
          height: 48 * scale,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed(Etapa2Routes.resetPassword);
            },
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6 * scale),
                side: const BorderSide(color: Color.fromRGBO(66, 70, 85, 0.5)),
              ),
            ),
            child: Text(
              'Reset Password',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w500,
                fontSize: 13 * scale,
                color: const Color(0xFF65DAFF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, double scale) {
    return Column(
      children: [
        const Divider(color: Color.fromRGBO(66, 70, 85, 0.3), height: 1),
        SizedBox(height: 20 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14 * scale,
                color: const Color(0xFFC2C6D8),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed(Etapa2Routes.personalDetails),
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14 * scale,
                  color: const Color(0xFF5B8CFF),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldBlock extends StatefulWidget {
  const _FieldBlock({
    required this.label,
    required this.hintText,
    required this.suffixIcon,
    required this.controller,
    this.isEmail = false,
    this.isPassword = false,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final IconData suffixIcon;
  final TextEditingController controller;
  final bool isEmail;
  final bool isPassword;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_FieldBlock> createState() => _FieldBlockState();
}

class _FieldBlockState extends State<_FieldBlock> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Color(0xFF8C90A1),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscurePassword,
          keyboardType: widget.isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
          textInputAction:
              widget.isPassword ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: const Color(0xFF424655),
              letterSpacing: widget.isPassword && _obscurePassword ? 2 : 0,
            ),
            filled: true,
            fillColor: const Color(0xFF0B0E16),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF424655),
                      size: 20,
                    ),
                  )
                : Icon(
                    widget.suffixIcon,
                    color: const Color(0xFF424655),
                    size: 20,
                  ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color.fromRGBO(66, 70, 85, 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF5B8CFF)),
            ),
          ),
        ),
      ],
    );
  }
}
