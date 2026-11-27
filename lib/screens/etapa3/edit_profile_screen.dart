import 'package:flutter/material.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../contexts/iam/domain/client_profile.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../services/app_i18n.dart';
import '../shared/form_validators.dart';

/// Edita el perfil propio (PUT /api/client/profile: nombre, teléfono,
/// ubicación y dirección). El correo es el identificador y no se edita.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.profile});

  /// Perfil ya cargado; si falta, se pide al backend.
  final ClientProfile? profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  late Future<ClientProfile> _future = _load();
  String? _error;
  bool _saving = false;

  Future<ClientProfile> _load() async {
    final profile = widget.profile ?? await AuthFacade.profile();
    _name.text = profile.name;
    _phone.text = profile.phone ?? '';
    _location.text = profile.location ?? '';
    _address.text = profile.address ?? '';
    return profile;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _location, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthFacade.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        location: _location.text.trim(),
        address: _address.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('prof_saved'))));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmsPage(
      eyebrow: tr('set_account'),
      title: tr('prof_title'),
      bottom: EmsButton(label: tr('common_save'), icon: PhosphorIconsRegular.check, loading: _saving, onPressed: _save),
      child: FutureBuilder<ClientProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const EmsLoadingBlock(lines: 3);
          if (snapshot.hasError) {
            return EmsPanel(
              child: EmsEmptyState(
                kind: EmsEmptyKind.offline,
                title: snapshot.error is ApiException ? (snapshot.error as ApiException).message : tr('set_errLoad'),
                action: EmsButton(label: tr('common_retry'), kind: EmsButtonKind.secondary, expand: false, onPressed: () => setState(() { _future = _load(); })),
              ),
            );
          }
          final p = snapshot.data!;
          return Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  EmsBanner(tone: EmsTone.danger, icon: PhosphorIconsRegular.warningCircle, message: _error!),
                  const SizedBox(height: EmsSpace.s5),
                ],
                EmsGroup(children: [EmsKeyValue(label: tr('m_email'), value: p.email, note: tr('m_emailFixed'))]),
                const SizedBox(height: EmsSpace.s7),
                EmsField(
                  label: tr('prof_name'),
                  controller: _name,
                  icon: PhosphorIconsRegular.user,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.requiredName,
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
                const SizedBox(height: EmsSpace.s6),
                EmsField(
                  label: tr('prof_location'),
                  controller: _location,
                  icon: PhosphorIconsRegular.mapPin,
                  hint: tr('m_locationHint'),
                  optional: true,
                  optionalLabel: tr('m_optional'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: EmsSpace.s6),
                EmsField(
                  label: tr('prof_address'),
                  controller: _address,
                  icon: PhosphorIconsRegular.houseLine,
                  optional: true,
                  optionalLabel: tr('m_optional'),
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  onSubmitted: (_) => _save(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
