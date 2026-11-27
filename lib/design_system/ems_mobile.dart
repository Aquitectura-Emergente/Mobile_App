import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ems_icons.g.dart';
import 'ems_theme.dart';
import 'ems_tokens.g.dart';
import 'ems_widgets.dart';

// Patrones móviles de EMSafe Calibre: misma piel que la web (filetes, mono
// para cifras, regla graduada), compuestos para el pulgar.

const double _kMaxWidth = 560;

/// Página empujada sobre las pestañas: volver, antetítulo, título grande y
/// zona de acción fija opcional.
class EmsPage extends StatelessWidget {
  const EmsPage({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.actions = const [],
    this.bottom,
    this.onRefresh,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s5, EmsSpace.s6, EmsSpace.s9),
    this.showBack = true,
  });

  final String title;
  final String? eyebrow;
  final Widget child;
  final List<Widget> actions;

  /// Acción principal fija sobre el borde inferior (respeta el área segura).
  final Widget? bottom;
  final Future<void> Function()? onRefresh;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    Widget body = scrollable
        ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: child,
          )
        : Padding(padding: padding, child: child);
    if (onRefresh != null && scrollable) {
      body = RefreshIndicator(onRefresh: onRefresh!, color: c.primary, backgroundColor: c.surface, child: body);
    }
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: bottom == null,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxWidth),
            child: Column(
              children: [
                EmsPageHeader(title: title, eyebrow: eyebrow, actions: actions, showBack: showBack),
                Expanded(child: body),
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
                    constraints: const BoxConstraints(maxWidth: _kMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s4, EmsSpace.s6, EmsSpace.s4),
                      child: bottom,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Encabezado de página: fila de navegación y título con regla graduada.
class EmsPageHeader extends StatelessWidget {
  const EmsPageHeader({super.key, required this.title, this.eyebrow, this.actions = const [], this.showBack = true});

  final String title;
  final String? eyebrow;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(EmsSpace.s3, EmsSpace.s3, EmsSpace.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
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
                  const SizedBox(width: EmsSpace.s3),
                const Spacer(),
                ...actions,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(EmsSpace.s4, EmsSpace.s2, EmsSpace.s3, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!.toUpperCase(), style: context.type.eyebrow),
                  const SizedBox(height: EmsSpace.s2),
                ],
                Semantics(
                  header: true,
                  child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.type.h1.copyWith(fontSize: 28, height: 1.1)),
                ),
                const SizedBox(height: EmsSpace.s4),
                const EmsScaleRule(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de icono cuadrado con filete (48 px de área táctil).
class EmsIconButton extends StatelessWidget {
  const EmsIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.color, this.bordered = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: EmsSize.touchMin, height: EmsSize.touchMin),
      style: IconButton.styleFrom(
        foregroundColor: color ?? c.text,
        side: bordered ? BorderSide(color: c.border) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.sm)),
      ),
      icon: Icon(icon, size: EmsSize.iconMd + 2),
    );
  }
}

enum EmsButtonKind { primary, secondary, ghost, danger }

/// Botón de acción. Con [loading] se bloquea y muestra progreso.
class EmsButton extends StatelessWidget {
  const EmsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = EmsButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final EmsButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final (bg, fg, border) = switch (kind) {
      EmsButtonKind.primary => (c.primary, c.onPrimary, c.primary),
      EmsButtonKind.secondary => (c.surface, c.text, c.borderStrong),
      EmsButtonKind.ghost => (Colors.transparent, c.primary, Colors.transparent),
      EmsButtonKind.danger => (c.dangerSubtle, c.danger, c.dangerBorder),
    };
    final enabled = onPressed != null && !loading;
    final height = compact ? EmsSize.controlMd : EmsSize.controlLg + 4;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: 18, color: fg),
        if (loading || icon != null) const SizedBox(width: EmsSpace.s3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: EmsFont.body, fontSize: compact ? 14 : 15, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || loading ? 1 : 0.45,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EmsRadius.sm),
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s6),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de formulario con etiqueta superior, ayuda de formato y error en
/// línea. Valida mientras se escribe tras el primer contacto.
class EmsField extends StatefulWidget {
  const EmsField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.optional = false,
    this.optionalLabel = 'Optional',
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.maxLength,
    this.focusNode,
    this.errorText,
    this.suffix,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final bool optional;
  final String optionalLabel;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final int? maxLength;
  final FocusNode? focusNode;

  /// Error que viene de fuera (p. ej. del backend).
  final String? errorText;
  final Widget? suffix;

  @override
  State<EmsField> createState() => _EmsFieldState();
}

class _EmsFieldState extends State<EmsField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    OutlineInputBorder border(Color color, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(EmsRadius.sm),
          borderSide: BorderSide(color: color, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: context.type.label.copyWith(color: c.text))),
            if (widget.optional) Text(widget.optionalLabel, style: context.type.caption),
          ],
        ),
        const SizedBox(height: EmsSpace.s3),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _hidden,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          maxLength: widget.maxLength,
          style: context.type.body.copyWith(fontSize: 15, color: c.text),
          cursorColor: c.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: context.type.body.copyWith(fontSize: 15, color: c.textDisabled),
            errorText: widget.errorText,
            errorMaxLines: 3,
            helperText: widget.helper,
            helperMaxLines: 3,
            helperStyle: context.type.caption,
            errorStyle: context.type.caption.copyWith(color: c.danger),
            counterText: '',
            filled: true,
            fillColor: widget.enabled ? c.surface : c.bgSunken,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: EmsSpace.s5, vertical: 15),
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 19, color: c.textTertiary),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show' : 'Hide',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(_hidden ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash, size: 19, color: c.textTertiary),
                  )
                : widget.suffix,
            enabledBorder: border(c.borderStrong),
            disabledBorder: border(c.border),
            focusedBorder: border(c.focus, 2),
            errorBorder: border(c.dangerSignal),
            focusedErrorBorder: border(c.dangerSignal, 2),
          ),
        ),
      ],
    );
  }
}

/// Control segmentado (rangos, filtros, tipos).
class EmsSegmented<T> extends StatelessWidget {
  const EmsSegmented({super.key, required this.segments, required this.value, required this.onChanged, this.dense = false});

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.bgSunken,
        borderRadius: BorderRadius.circular(EmsRadius.sm),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final (v, label) in segments)
            Expanded(
              child: Semantics(
                selected: v == value,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (v != value) {
                      HapticFeedback.selectionClick();
                      onChanged(v);
                    }
                  },
                  child: AnimatedContainer(
                    duration: EmsDuration.fast,
                    height: dense ? 32 : 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == value ? c.surfaceRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(EmsRadius.xs),
                      border: Border.all(color: v == value ? c.borderStrong : Colors.transparent),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.monoSm.copyWith(
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: v == value ? c.text : c.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Progreso de un flujo por pasos: "PASO 2 / 4" y tramos graduados.
class EmsStepProgress extends StatelessWidget {
  const EmsStepProgress({super.key, required this.step, required this.total, required this.label, this.stepWord = 'Step'});

  /// 1-based.
  final int step;
  final int total;
  final String label;
  final String stepWord;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Semantics(
      label: '$stepWord $step / $total. $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${stepWord.toUpperCase()} ${step.toString().padLeft(2, '0')}', style: context.type.monoSm.copyWith(color: c.primary)),
              Text(' / ${total.toString().padLeft(2, '0')}', style: context.type.monoSm),
              const SizedBox(width: EmsSpace.s4),
              Expanded(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.eyebrow)),
            ],
          ),
          const SizedBox(height: EmsSpace.s3),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: EmsDuration.base,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < step ? c.primary.withValues(alpha: 0.55) : (i == step ? c.primary : c.border),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                if (i < total) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Grupo de filas con filete, al estilo de una ficha técnica.
class EmsGroup extends StatelessWidget {
  const EmsGroup({super.key, required this.children, this.title, this.trailing, this.footer, this.index});

  final List<Widget> children;
  final String? title;
  final String? index;
  final Widget? trailing;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) EmsSectionHeader(title: title!, index: index, trailing: trailing),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(EmsRadius.md),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) Divider(height: 1, thickness: 1, color: c.borderSubtle, indent: EmsSpace.s5),
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(EmsSpace.s2, EmsSpace.s3, EmsSpace.s2, 0),
            child: Text(footer!, style: context.type.caption),
          ),
      ],
    );
  }
}

/// Fila de lista: icono, título, detalle, valor y cheurón si navega.
class EmsRow extends StatelessWidget {
  const EmsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconTone,
    this.value,
    this.trailing,
    this.onTap,
    this.rail,
    this.destructive = false,
    this.mono = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final EmsTone? iconTone;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Riel lateral de estado.
  final Color? rail;
  final bool destructive;

  /// Valor en mono (cifras, identificadores).
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final tone = iconTone == null ? null : emsTone(context, iconTone!);
    final titleColor = destructive ? c.danger : c.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: rail == null ? null : BoxDecoration(border: Border(left: BorderSide(color: rail!, width: EmsBorder.rail))),
          padding: EdgeInsets.fromLTRB(rail == null ? EmsSpace.s5 : EmsSpace.s5 - EmsBorder.rail, EmsSpace.s4, EmsSpace.s4, EmsSpace.s4),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tone?.bg ?? c.bgSunken,
                    borderRadius: BorderRadius.circular(EmsRadius.sm),
                    border: Border.all(color: tone?.border ?? c.border),
                  ),
                  child: Icon(icon, size: 18, color: destructive ? c.danger : (tone?.fg ?? c.textSecondary)),
                ),
                const SizedBox(width: EmsSpace.s4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.type.body.copyWith(fontWeight: FontWeight.w500, color: titleColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.type.caption),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: EmsSpace.s3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Text(
                    value!,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: mono ? context.type.mono.copyWith(color: c.text) : context.type.bodySm,
                  ),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: EmsSpace.s3), trailing!],
              if (onTap != null) ...[
                const SizedBox(width: EmsSpace.s2),
                Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Par etiqueta / valor de una ficha de detalle.
class EmsKeyValue extends StatelessWidget {
  const EmsKeyValue({super.key, required this.label, required this.value, this.mono = false, this.note, this.valueColor});

  final String label;
  final String value;
  final bool mono;
  final String? note;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EmsSpace.s5, vertical: EmsSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: context.type.bodySm)),
          const SizedBox(width: EmsSpace.s4),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SelectableText(
                  value,
                  textAlign: TextAlign.right,
                  style: (mono ? context.type.mono : context.type.body).copyWith(color: valueColor ?? c.text),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(note!, textAlign: TextAlign.right, style: context.type.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección plegable para metadatos secundarios.
class EmsExpandable extends StatefulWidget {
  const EmsExpandable({super.key, required this.title, required this.child, this.initiallyOpen = false, this.icon});

  final String title;
  final Widget child;
  final bool initiallyOpen;
  final IconData? icon;

  @override
  State<EmsExpandable> createState() => _EmsExpandableState();
}

class _EmsExpandableState extends State<EmsExpandable> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(EmsRadius.md),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s4, EmsSpace.s4),
                child: Row(
                  children: [
                    Icon(widget.icon ?? PhosphorIconsRegular.listBullets, size: 18, color: c.textTertiary),
                    const SizedBox(width: EmsSpace.s4),
                    Expanded(child: Text(widget.title.toUpperCase(), style: context.type.eyebrow)),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: EmsDuration.base,
                      child: Icon(PhosphorIconsRegular.caretDown, size: 16, color: c.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: EmsDuration.base,
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, thickness: 1, color: c.borderSubtle),
                widget.child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Enlace de profundización ("Ver todos los datos").
class EmsDrillLink extends StatelessWidget {
  const EmsDrillLink({super.key, required this.label, required this.onTap, this.detail});

  final String label;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EmsRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: EmsSize.touchMin),
          child: Row(
            children: [
              Expanded(child: Text(label, style: context.type.body.copyWith(color: c.primary, fontWeight: FontWeight.w600))),
              if (detail != null) Text(detail!, style: context.type.monoSm),
              const SizedBox(width: EmsSpace.s2),
              Icon(PhosphorIconsRegular.arrowRight, size: 16, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior con asa, título y contenido.
Future<T?> showEmsSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder, String? eyebrow}) {
  final c = context.ems;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.surface,
    barrierColor: c.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(EmsRadius.lg))),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: EmsSpace.s3),
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.borderStrong, borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(EmsSpace.s6, EmsSpace.s5, EmsSpace.s6, EmsSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null) ...[
                    Text(eyebrow.toUpperCase(), style: ctx.type.eyebrow),
                    const SizedBox(height: EmsSpace.s2),
                  ],
                  Text(title, style: ctx.type.h3),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(EmsSpace.s6, 0, EmsSpace.s6, EmsSpace.s7),
                child: SafeArea(top: false, child: builder(ctx)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Confirmación con tono (p. ej. danger para acciones irreversibles).
Future<bool> showEmsConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  EmsTone tone = EmsTone.primary,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: context.ems.scrim,
    builder: (ctx) {
      final c = ctx.ems;
      final t = emsTone(ctx, tone);
      return Dialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: EmsSpace.s7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmsRadius.lg), side: BorderSide(color: c.border)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(EmsSpace.s7, EmsSpace.s7, EmsSpace.s7, EmsSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(EmsRadius.md), border: Border.all(color: t.border)),
                  child: Icon(icon, color: t.fg, size: 22),
                ),
                const SizedBox(height: EmsSpace.s5),
              ],
              Text(title, style: ctx.type.h3),
              const SizedBox(height: EmsSpace.s3),
              Text(message, style: ctx.type.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: EmsSpace.s7),
              EmsButton(
                label: confirmLabel,
                kind: tone == EmsTone.danger ? EmsButtonKind.danger : EmsButtonKind.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: EmsSpace.s3),
              EmsButton(label: cancelLabel, kind: EmsButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Bloque de carga con la forma del contenido.
class EmsLoadingBlock extends StatelessWidget {
  const EmsLoadingBlock({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EmsSkeleton(height: 180, radius: EmsRadius.md),
        for (var i = 0; i < lines; i++) ...[
          const SizedBox(height: EmsSpace.s4),
          EmsSkeleton(height: 56, radius: EmsRadius.md, width: i.isEven ? double.infinity : 280),
        ],
      ],
    );
  }
}

/// Valor protagonista: cifra mono, unidad y nota.
class EmsHeroValue extends StatelessWidget {
  const EmsHeroValue({super.key, required this.value, required this.unit, this.label, this.color, this.size = 56});

  final String value;
  final String unit;
  final String? label;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: context.type.eyebrow),
          const SizedBox(height: EmsSpace.s2),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: context.type.metricXl.copyWith(fontSize: size, height: 1, color: color ?? c.text)),
              ),
            ),
            const SizedBox(width: EmsSpace.s3),
            Text(unit, style: context.type.mono.copyWith(fontSize: 15, color: c.textTertiary)),
          ],
        ),
      ],
    );
  }
}
