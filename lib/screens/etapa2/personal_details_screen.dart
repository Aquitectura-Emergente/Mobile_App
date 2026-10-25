import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../routes/etapa2_routes.dart';
import '../../services/onboarding_flow_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/emsafe_page_indicator.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  ClientType _clientType = ClientType.individual;

  final _companyNameController = TextEditingController();
  final _rucController = TextEditingController();
  final _industryController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController(text: 'Peru');

  @override
  void dispose() {
    _companyNameController.dispose();
    _rucController.dispose();
    _industryController.dispose();
    _fullNameController.dispose();
    _dniController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _continueToCreateAccount() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final displayName = _clientType == ClientType.company
        ? _companyNameController.text.trim()
        : _fullNameController.text.trim();

    final draft = PersonalDetailsDraft(
      clientType: _clientType,
      displayName: displayName,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      documentId: _clientType == ClientType.company
          ? _rucController.text.trim()
          : _dniController.text.trim(),
      companyName: _clientType == ClientType.company
          ? _companyNameController.text.trim()
          : null,
      industry: _clientType == ClientType.company
          ? _industryController.text.trim()
          : null,
      contactName: _contactNameController.text.trim(),
    );

    OnboardingFlowStore.personalDetailsDraft = draft;
    Navigator.of(context).pushNamed(Etapa2Routes.createAccount);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / 390).clamp(0.86, 1.14);
    final sidePadding = (22 * scale).clamp(16, 28).toDouble();

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    14,
                    sidePadding,
                    10,
                  ),
                  child: const _PersonalHeader(),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        sidePadding,
                        6,
                        sidePadding,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ClientTypePicker(
                            selected: _clientType,
                            onChanged: (value) {
                              setState(() {
                                _clientType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          if (_clientType == ClientType.company)
                            _CompanyFields(
                              companyNameController: _companyNameController,
                              rucController: _rucController,
                              industryController: _industryController,
                            )
                          else
                            _IndividualFields(
                              fullNameController: _fullNameController,
                              dniController: _dniController,
                            ),
                          const SizedBox(height: 18),
                          _FormSection(
                            title: 'Primary Contact',
                            children: [
                              _InputField(
                                controller: _contactNameController,
                                label: 'Contact Name',
                                icon: Icons.badge_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              _InputField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                                textInputAction: TextInputAction.next,
                              ),
                              _InputField(
                                controller: _phoneController,
                                label: 'Phone',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: _numericValidator,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _FormSection(
                            title: 'Location',
                            children: [
                              _InputField(
                                controller: _addressController,
                                label: 'Address',
                                icon: Icons.location_on_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              _InputField(
                                controller: _cityController,
                                label: 'City',
                                icon: Icons.apartment_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              _InputField(
                                controller: _countryController,
                                label: 'Country',
                                icon: Icons.public_outlined,
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _DetailsFooter(onContinue: _continueToCreateAccount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required field';
    if (!text.contains('@') || !text.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }
}

class _PersonalHeader extends StatelessWidget {
  const _PersonalHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tell us who will own this monitoring setup.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClientTypePicker extends StatelessWidget {
  const _ClientTypePicker({required this.selected, required this.onChanged});

  final ClientType selected;
  final ValueChanged<ClientType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: SegmentedButton<ClientType>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ClientType.individual,
            label: Text('Individual'),
            icon: Icon(Icons.person_outline),
          ),
          ButtonSegment(
            value: ClientType.company,
            label: Text('Company'),
            icon: Icon(Icons.business_outlined),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (values) => onChanged(values.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppTheme.primaryBlue
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? const Color(0xFF002B73)
                : Colors.white70;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: Colors.white10)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

class _CompanyFields extends StatelessWidget {
  const _CompanyFields({
    required this.companyNameController,
    required this.rucController,
    required this.industryController,
  });

  final TextEditingController companyNameController;
  final TextEditingController rucController;
  final TextEditingController industryController;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Company Information',
      children: [
        _InputField(
          controller: companyNameController,
          label: 'Company Name',
          icon: Icons.business_center_outlined,
          textInputAction: TextInputAction.next,
        ),
        _InputField(
          controller: rucController,
          label: 'RUC',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: _numericValidator,
          textInputAction: TextInputAction.next,
        ),
        _InputField(
          controller: industryController,
          label: 'Industry',
          icon: Icons.factory_outlined,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

class _IndividualFields extends StatelessWidget {
  const _IndividualFields({
    required this.fullNameController,
    required this.dniController,
  });

  final TextEditingController fullNameController;
  final TextEditingController dniController;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Personal Information',
      children: [
        _InputField(
          controller: fullNameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        _InputField(
          controller: dniController,
          label: 'DNI',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: _numericValidator,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          for (final child in children) ...[child, const SizedBox(height: 12)],
        ]..removeLast(),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator ?? _requiredValidator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: AppTheme.primaryCyan, size: 20),
        filled: true,
        fillColor: const Color(0xFF0B0E16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        errorMaxLines: 2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.2),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'Required field' : null;
  }
}

String? _numericValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Required field';
  if (!RegExp(r'^\d+$').hasMatch(text)) return 'Use numbers only';
  return null;
}

class _DetailsFooter extends StatelessWidget {
  const _DetailsFooter({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmsafePageIndicator(count: 2, activeIndex: 0),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: const Color(0xFF002B73),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Continue to Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}
