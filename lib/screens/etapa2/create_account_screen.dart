import 'dart:ui';

import 'package:flutter/material.dart';

import '../../routes/etapa2_routes.dart';
import '../../contexts/iam/application/auth_facade.dart';
import '../../core/http/api_client.dart';
import '../../services/onboarding_flow_store.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Real sign-up against POST /api/auth/register. The account is created in
  /// "pending" state — an EMSafe admin must activate it before the first login.
  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _submitting) return;

    final draft = OnboardingFlowStore.personalDetailsDraft;
    if (draft == null) return;

    setState(() => _submitting = true);
    try {
      await AuthFacade.register(
        name: draft.displayName,
        email: draft.email,
        password: _passwordController.text,
        phone: draft.phone,
        address: [draft.address, draft.city, draft.country]
            .where((s) => s.trim().isNotEmpty)
            .join(', '),
        clientType: draft.clientTypeValue,
        contactName: draft.contactName,
        taxId: draft.documentId,
        industry: draft.industry,
      );
      await OnboardingFlowStore.markAccountCreated();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          title: const Text(
            'Account created',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Your account was created and is pending approval. An EMSafe '
            'administrator will activate it shortly — then you can sign in.',
            style: TextStyle(color: Color(0xFFC2C6D8), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFF65DAFF))),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Etapa2Routes.login, (route) => false);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = OnboardingFlowStore.personalDetailsDraft;
    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / 390).clamp(0.85, 1.15);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Stack(
        children: [
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16 * scale),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: EdgeInsets.all(24 * scale),
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 32 * scale,
                                      height: 1.25,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.8 * scale,
                                      color: const Color(0xFFB2C5FF),
                                      fontFamily: 'Sora',
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Text(
                                    'Set your password before connecting monitoring hardware.',
                                    style: TextStyle(
                                      fontSize: 16 * scale,
                                      height: 1.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFFC2C6D8),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  SizedBox(height: 24 * scale),
                                  if (draft == null)
                                    _MissingDetailsCard(scale: scale)
                                  else
                                    _PersonalDetailsSummary(
                                      draft: draft,
                                      scale: scale,
                                    ),
                                  SizedBox(height: 18 * scale),
                                  _PasswordBlock(
                                    controller: _passwordController,
                                    label: 'PASSWORD',
                                    hintText: 'Minimum 8 characters',
                                    scale: scale,
                                    showStrength: true,
                                    validator: (value) {
                                      if ((value ?? '').length < 8) {
                                        return 'Use at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16 * scale),
                                  _PasswordBlock(
                                    controller: _confirmPasswordController,
                                    label: 'CONFIRM PASSWORD',
                                    hintText: 'Repeat password',
                                    scale: scale,
                                    showStrength: false,
                                    validator: (value) {
                                      if ((value ?? '').isEmpty) {
                                        return 'Confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 24 * scale),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56 * scale,
                                    child: ElevatedButton(
                                      onPressed: draft == null
                                          ? () {
                                              Navigator.of(context).pushNamed(
                                                Etapa2Routes.personalDetails,
                                              );
                                            }
                                          : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF5B8CFF,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8 * scale,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        draft == null
                                            ? 'Add Personal Details'
                                            : 'Continue to Sensors',
                                        style: TextStyle(
                                          fontFamily: 'Sora',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16 * scale,
                                          color: const Color(0xFF002565),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 14 * scale),
                                  _TermsAndFooter(scale: scale),
                                ],
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
}

class _PersonalDetailsSummary extends StatelessWidget {
  const _PersonalDetailsSummary({required this.draft, required this.scale});

  final PersonalDetailsDraft draft;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E16),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: const Color.fromRGBO(101, 218, 255, 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42 * scale,
            height: 42 * scale,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(101, 218, 255, 0.12),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF65DAFF),
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  '${draft.clientTypeLabel} - ${draft.email}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFC2C6D8),
                    fontSize: 12 * scale,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingDetailsCard extends StatelessWidget {
  const _MissingDetailsCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(245, 158, 11, 0.08),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: const Color.fromRGBO(245, 158, 11, 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              'Complete Personal Details before creating your password.',
              style: TextStyle(
                color: const Color(0xFFC2C6D8),
                fontSize: 13 * scale,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordBlock extends StatefulWidget {
  const _PasswordBlock({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.scale,
    required this.showStrength,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final double scale;
  final bool showStrength;
  final String? Function(String?)? validator;

  @override
  State<_PasswordBlock> createState() => _PasswordBlockState();
}

class _PasswordBlockState extends State<_PasswordBlock> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w500,
            fontSize: 12 * widget.scale,
            height: 16 / 12,
            color: const Color(0xFFC2C6D8),
          ),
        ),
        SizedBox(height: 4 * widget.scale),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscurePassword,
          validator: widget.validator,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: const Color(0xFF8C90A1),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16 * widget.scale,
            ),
            filled: true,
            fillColor: const Color(0xFF0B0E16),
            contentPadding: EdgeInsets.symmetric(
              vertical: 18 * widget.scale,
              horizontal: 16 * widget.scale,
            ),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF8C90A1),
                size: 20 * widget.scale,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * widget.scale),
              borderSide: const BorderSide(
                color: Color.fromRGBO(66, 70, 85, 0.35),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * widget.scale),
              borderSide: const BorderSide(
                color: Color.fromRGBO(91, 140, 255, 1),
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * widget.scale),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * widget.scale),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.2,
              ),
            ),
          ),
        ),
        if (widget.showStrength) ...[
          SizedBox(height: 8 * widget.scale),
          SizedBox(
            height: 6 * widget.scale,
            child: Row(
              children: [
                _StrengthPill(color: const Color(0xFF65DAFF), radius: 12),
                SizedBox(width: 6 * widget.scale),
                _StrengthPill(color: const Color(0xFF65DAFF), radius: 12),
                SizedBox(width: 6 * widget.scale),
                _StrengthPill(color: const Color(0xFF65DAFF), radius: 12),
                SizedBox(width: 6 * widget.scale),
                _StrengthPill(
                  color: const Color.fromRGBO(101, 218, 255, 0.2),
                  radius: 12,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StrengthPill extends StatelessWidget {
  const _StrengthPill({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _TermsAndFooter extends StatelessWidget {
  const _TermsAndFooter({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Secure setup - Privacy Protocol',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12 * scale,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB2C5FF),
          ),
        ),
        SizedBox(height: 16 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 14 * scale,
                color: const Color(0xFFC2C6D8),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Etapa2Routes.login),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFFB2C5FF),
              ),
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
