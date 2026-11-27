import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_i18n.dart';
import '../../services/onboarding_flow_store.dart';
import '../shared/auth_scaffold.dart';
import '../shared/form_validators.dart';

/// Alta de cliente en cuatro pasos, ajustada a `POST /api/auth/register`:
/// solo nombre, correo y contraseña son obligatorios; el resto es opcional.
/// La cuenta nace pendiente y un administrador la activa.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _steps = 4;
  late int _step = widget.initialStep.clamp(0, _steps - 1);
  final _forms = List.generate(_steps, (_) => GlobalKey<FormState>());

  ClientType _type = ClientType.individual;
  final _name = TextEditingController();
  final _doc = TextEditingController();
  final _industry = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    final d = OnboardingFlowStore.personalDetailsDraft;
    if (d != null) {
      _type = d.clientType;
      _name.text = d.companyName ?? d.displayName;
      _doc.text = d.documentId ?? '';
      _industry.text = d.industry ?? '';
      _contact.text = d.contactName ?? '';
      _email.text = d.email;
      _phone.text = d.phone;
      _address.text = d.address;
      _city.text = d.city;
      _country.text = d.country;
    } else {
      _step = 0;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _doc, _industry, _contact, _email, _phone, _address, _city, _country, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _company => _type == ClientType.company;

  String get _stepLabel => switch (_step) {
        0 => tr('m_regStepType'),
        1 => tr('m_regStepIdentity'),
        2 => tr('m_regStepContact'),
        _ => tr('m_regStepSecurity'),
      };

  void _saveDraft() {
    OnboardingFlowStore.personalDetailsDraft = PersonalDetailsDraft(
      clientType: _type,
      displayName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim(),
      documentId: _doc.text.trim(),
      companyName: _company ? _name.text.trim() : null,
      industry: _company ? _industry.text.trim() : null,
      contactName: _company ? _contact.text.trim() : null,
    );
  }

  void _next() {
    final form = _forms[_step].currentState;
    if (form != null && !form.validate()) return;
    FocusScope.of(context).unfocus();
    _saveDraft();
    if (_step < _steps - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<bool> _back() async {
    if (_step == 0) return true;
    setState(() => _step--);
    return false;
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
      _emailError = null;
    });
    try {
      final address = [_address.text, _city.text, _country.text].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
      await AuthFacade.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
        address: address,
        clientType: _company ? 'company' : 'individual',
        contactName: _company ? _contact.text.trim() : null,
        taxId: _doc.text.trim(),
        industry: _company ? _industry.text.trim() : null,
      );
      await OnboardingFlowStore.markAccountCreated();
      OnboardingFlowStore.personalDetailsDraft = null;
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        Etapa2Routes.verificationSuccess,
        (r) => r.isFirst,
        arguments: _email.text.trim(),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.message;
      if (msg.toLowerCase().contains('email already')) {
        // El correo es lo único que el backend rechaza por duplicado: se vuelve a su paso.
        setState(() {
          _emailError = tr('m_errEmailTaken');
          _step = 2;
        });
      } else {
        setState(() => _error = e.statusCode == null ? tr('m_errNetwork') : msg);
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr('m_errNetwork'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthScaffold(
        eyebrow: tr('m_regEyebrow'),
        title: switch (_step) {
          0 => tr('m_regTitleType'),
          1 => _company ? tr('m_regTitleCompany') : tr('m_regTitlePerson'),
          2 => tr('m_regTitleContact'),
          _ => tr('m_regTitleSecurity'),
        },
        top: EmsStepProgress(step: _step + 1, total: _steps, label: _stepLabel, stepWord: tr('m_step')),
        bottom: Row(
          children: [
            if (_step > 0) ...[
              SizedBox(
                width: 120,
                child: EmsButton(label: tr('m_back'), kind: EmsButtonKind.secondary, onPressed: _submitting ? null : _back),
              ),
              const SizedBox(width: EmsSpace.s4),
            ],
            Expanded(
              child: EmsButton(
                label: _step == _steps - 1 ? tr('m_regSubmit') : tr('m_continue'),
                icon: _step == _steps - 1 ? PhosphorIconsRegular.check : PhosphorIconsRegular.arrowRight,
                loading: _submitting,
                onPressed: _next,
              ),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: EmsDuration.base,
          child: KeyedSubtree(key: ValueKey(_step), child: _stepBody(context)),
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('m_regTypeIntro'), style: context.type.body.copyWith(color: context.ems.textSecondary)),
            const SizedBox(height: EmsSpace.s6),
            _TypeCard(
              icon: PhosphorIconsRegular.house,
              title: tr('m_typeIndividual'),
              body: tr('m_typeIndividualMsg'),
              selected: _type == ClientType.individual,
              onTap: () => setState(() => _type = ClientType.individual),
            ),
            const SizedBox(height: EmsSpace.s4),
            _TypeCard(
              icon: PhosphorIconsRegular.buildingOffice,
              title: tr('m_typeCompany'),
              body: tr('m_typeCompanyMsg'),
              selected: _type == ClientType.company,
              onTap: () => setState(() => _type = ClientType.company),
            ),
            const SizedBox(height: EmsSpace.s6),
            EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.hardHat, title: tr('m_operatorQ'), message: tr('m_operatorA')),
          ],
        );
      case 1:
        return Form(
          key: _forms[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmsField(
                label: _company ? tr('m_companyName') : tr('m_fullName'),
                controller: _name,
                icon: _company ? PhosphorIconsRegular.buildingOffice : PhosphorIconsRegular.user,
                hint: _company ? tr('m_companyNameHint') : tr('m_fullNameHint'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: _company ? const [AutofillHints.organizationName] : const [AutofillHints.name],
                validator: Validators.requiredName,
              ),
              const SizedBox(height: EmsSpace.s6),
              EmsField(
                label: _company ? 'RUC' : 'DNI',
                controller: _doc,
                icon: PhosphorIconsRegular.identificationBadge,
                hint: _company ? '20123456789' : '12345678',
                helper: _company ? tr('m_rucHelp') : tr('m_dniHelp'),
                optional: true,
                optionalLabel: tr('m_optional'),
                keyboardType: TextInputType.number,
                inputFormatters: digitsOnly,
                maxLength: _company ? 11 : 8,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null;
                  final n = _company ? 11 : 8;
                  return s.length != n ? tr('m_errDocLength').replaceAll('{n}', '$n') : null;
                },
              ),
              if (_company) ...[
                const SizedBox(height: EmsSpace.s6),
                EmsField(
                  label: tr('m_industry'),
                  controller: _industry,
                  icon: PhosphorIconsRegular.factory,
                  hint: tr('m_industryHint'),
                  optional: true,
                  optionalLabel: tr('m_optional'),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: EmsSpace.s6),
                EmsField(
                  label: tr('m_contactName'),
                  controller: _contact,
                  icon: PhosphorIconsRegular.userCircle,
                  helper: tr('m_contactHelp'),
                  optional: true,
                  optionalLabel: tr('m_optional'),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ],
          ),
        );
      case 2:
        return Form(
          key: _forms[2],
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmsField(
                  label: tr('m_email'),
                  controller: _email,
                  icon: PhosphorIconsRegular.envelopeSimple,
                  hint: tr('m_emailHint'),
                  helper: tr('m_emailHelp'),
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  validator: Validators.email,
                ),
                const SizedBox(height: EmsSpace.s6),
                EmsField(
                  label: tr('prof_phone'),
                  controller: _phone,
                  icon: PhosphorIconsRegular.phone,
                  hint: '+51 987 654 321',
                  helper: tr('m_phoneHelp'),
                  optional: true,
                  optionalLabel: tr('m_optional'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: Validators.optionalPhone,
                ),
                const SizedBox(height: EmsSpace.s7),
                EmsSectionHeader(title: tr('m_installAddress')),
                Text(tr('m_installAddressHelp'), style: context.type.caption),
                const SizedBox(height: EmsSpace.s5),
                EmsField(
                  label: tr('prof_address'),
                  controller: _address,
                  icon: PhosphorIconsRegular.houseLine,
                  optional: true,
                  optionalLabel: tr('m_optional'),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.streetAddressLine1],
                ),
                const SizedBox(height: EmsSpace.s6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: EmsField(
                        label: tr('m_city'),
                        controller: _city,
                        optional: true,
                        optionalLabel: tr('m_optional'),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.addressCity],
                      ),
                    ),
                    const SizedBox(width: EmsSpace.s4),
                    Expanded(
                      child: EmsField(
                        label: tr('m_country'),
                        controller: _country,
                        hint: tr('m_countryHint'),
                        optional: true,
                        optionalLabel: tr('m_optional'),
                        autofillHints: const [AutofillHints.countryName],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      default:
        return Form(
          key: _forms[3],
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  EmsBanner(tone: EmsTone.danger, icon: PhosphorIconsRegular.warningCircle, title: tr('m_regFailed'), message: _error!),
                  const SizedBox(height: EmsSpace.s5),
                ],
                EmsField(
                  label: tr('m_password'),
                  controller: _password,
                  obscure: true,
                  icon: PhosphorIconsRegular.lockKey,
                  helper: tr('m_pwHelp'),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  validator: Validators.password,
                ),
                const SizedBox(height: EmsSpace.s3),
                PasswordStrength(password: _password.text),
                const SizedBox(height: EmsSpace.s6),
                EmsField(
                  label: tr('m_confirmPw'),
                  controller: _confirm,
                  obscure: true,
                  icon: PhosphorIconsRegular.password,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => v != _password.text ? tr('pw_mismatch') : null,
                  onSubmitted: (_) => _next(),
                ),
                const SizedBox(height: EmsSpace.s7),
                EmsGroup(
                  title: tr('m_review'),
                  children: [
                    EmsKeyValue(label: tr('m_accountType'), value: _company ? tr('m_typeCompany') : tr('m_typeIndividual')),
                    EmsKeyValue(label: _company ? tr('m_companyName') : tr('m_fullName'), value: _name.text.trim()),
                    EmsKeyValue(label: tr('m_email'), value: _email.text.trim(), mono: true),
                    if (_phone.text.trim().isNotEmpty) EmsKeyValue(label: tr('prof_phone'), value: _phone.text.trim(), mono: true),
                    if (_doc.text.trim().isNotEmpty) EmsKeyValue(label: _company ? 'RUC' : 'DNI', value: _doc.text.trim(), mono: true),
                    EmsRow(icon: PhosphorIconsRegular.pencilSimple, title: tr('m_editData'), onTap: () => setState(() => _step = 1)),
                  ],
                ),
                const SizedBox(height: EmsSpace.s5),
                EmsBanner(tone: EmsTone.info, icon: PhosphorIconsRegular.sealCheck, title: tr('m_pendingTitle'), message: tr('m_pendingMsg')),
              ],
            ),
          ),
        );
    }
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.icon, required this.title, required this.body, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.primarySubtle : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmsRadius.md),
          side: BorderSide(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(EmsRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(EmsSpace.s5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 26, color: selected ? c.primary : c.textSecondary),
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
                const SizedBox(width: EmsSpace.s3),
                Icon(selected ? PhosphorIconsRegular.radioButton : PhosphorIconsRegular.circle, size: 20, color: selected ? c.primary : c.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
