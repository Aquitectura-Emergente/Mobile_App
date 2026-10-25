import 'package:flutter/material.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../contexts/iam/domain/client_profile.dart';
import '../../core/http/api_client.dart';
import '../../services/app_i18n.dart';
import 'etapa3_components.dart';
import 'subpage_scaffold.dart';

/// Edit the client's own profile (name, phone, location, address).
/// Backed by PUT /api/client/profile.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();

  late Future<ClientProfile> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ClientProfile> _load() async {
    final profile = await AuthFacade.profile();
    _name.text = profile.name;
    _phone.text = profile.phone ?? '';
    _location.text = profile.location ?? '';
    _address.text = profile.address ?? '';
    _email.text = profile.email;
    return profile;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _toast(tr('prof_nameRequired'));
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthFacade.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        location: _location.text.trim(),
        address: _address.text.trim(),
      );
      if (!mounted) return;
      _toast(tr('prof_saved'));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: tr('prof_title'),
      subtitle: tr('prof_subtitle'),
      child: FutureBuilder<ClientProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Etapa3Loading();
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : tr('set_errLoad');
            return Etapa3Error(
              message: msg,
              onRetry: () => setState(() => _future = _load()),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassField(label: tr('prof_name'), controller: _name),
              const SizedBox(height: 16),
              GlassField(label: 'Email', controller: _email, enabled: false),
              const SizedBox(height: 16),
              GlassField(
                label: tr('prof_phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              GlassField(label: tr('prof_location'), controller: _location),
              const SizedBox(height: 16),
              GlassField(label: tr('prof_address'), controller: _address),
              const SizedBox(height: 26),
              GlassButton(
                label: tr('common_save'),
                busy: _saving,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _location.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }
}
