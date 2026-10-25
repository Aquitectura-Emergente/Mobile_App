import 'package:flutter/material.dart';

import 'etapa3_components.dart';

/// Scaffold for pages pushed on top of the main tabs (edit profile, change
/// password, chat...). Same glass look as Etapa3Shell but with a back button
/// and no bottom navigation.
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.scrollable = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
      child: child,
    );
    return Scaffold(
      backgroundColor: Etapa3Palette.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 18, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back,
                            color: Etapa3Palette.text),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        // Title only — header descriptions removed app-wide.
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Etapa3Palette.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        trailing!,
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: scrollable
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: body,
                        )
                      : body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark glass text field used across the etapa3 sub-pages.
class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Etapa3Palette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(color: Etapa3Palette.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Etapa3Palette.quiet, fontSize: 14),
            filled: true,
            fillColor: Etapa3Palette.panelSoft,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Etapa3Palette.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Etapa3Palette.cyan),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Etapa3Palette.stroke),
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary action button for etapa3 sub-pages (cyan, full width).
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Etapa3Palette.red : Etapa3Palette.cyan;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
