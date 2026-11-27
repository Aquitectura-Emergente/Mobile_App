import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../contexts/devicemanagement/application/device_facade.dart';
import '../../contexts/devicemanagement/domain/client_device.dart';
import '../../contexts/iam/application/auth_facade.dart';
import '../../contexts/iam/domain/client_profile.dart';
import '../../contexts/iam/infrastructure/session_store.dart';
import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../core/http/api_client.dart';
import '../../design_system/design_system.dart';
import '../../routes/etapa2_routes.dart';
import '../../services/app_i18n.dart';
import '../../services/app_settings_store.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'etapa3_components.dart';

class _SettingsData {
  _SettingsData(this.profile, this.devices);
  final ClientProfile profile;
  final List<ClientDevice> devices;
}

/// Ajustes: perfil, preferencias locales, cuenta y sesión. Compartido por el
/// hogar y el operario (el operario no tiene sensores ni exportación).
class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool pushAlerts = AppSettingsStore.pushAlerts;
  bool biometricLock = AppSettingsStore.biometricLock;
  late Future<_SettingsData> _future = _load();
  bool _busy = false;

  Future<_SettingsData> _load() async {
    final profile = await AuthFacade.profile();
    final devices = SessionStore.isOperator ? const <ClientDevice>[] : await DeviceFacade.all();
    return _SettingsData(profile, devices);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() { _future = future; });
    try {
      await future;
    } catch (_) {}
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signOut() async {
    final ok = await showEmsConfirm(
      context,
      title: tr('set_signOut'),
      message: tr('m_signOutMsg'),
      confirmLabel: tr('set_signOut'),
      cancelLabel: tr('common_cancel'),
      icon: PhosphorIconsRegular.signOut,
    );
    if (!ok) return;
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Etapa2Routes.login, (route) => false);
  }

  Future<void> _openSubPage(Widget page) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => page));
    if (changed == true) _reload();
  }

  Future<void> _exportCsv() async {
    setState(() => _busy = true);
    try {
      final readings = await MonitoringFacade.allReadings();
      if (readings.isEmpty) {
        _toast(tr('set_exportEmpty'));
        return;
      }
      final buf = StringBuffer('id,device,value_uT,level,date\n');
      for (final r in readings) {
        final device = (r.deviceName ?? '').replaceAll('"', '""');
        buf.writeln('${r.id},"$device",${r.value ?? ''},${r.level ?? ''},${r.readingDate ?? ''}');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/emsafe_readings.csv');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'EMSafe readings (µT)'));
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showDeviceInfo(List<ClientDevice> devices) {
    showEmsSheet<void>(
      context,
      eyebrow: tr('set_maintenance'),
      title: tr('set_deviceInfo'),
      builder: (ctx) => devices.isEmpty
          ? EmsEmptyState(icon: PhosphorIconsRegular.broadcast, title: tr('set_noSensors'))
          : Column(
              children: [
                for (final d in devices) ...[
                  EmsGroup(
                    title: d.name,
                    children: [
                      EmsKeyValue(label: tr('m_kind'), value: d.isPlug ? tr('m_smartPlugKind') : tr('m_fixedSensorKind')),
                      EmsKeyValue(label: tr('set_serial'), value: d.serialNumber ?? '—', mono: true),
                      EmsKeyValue(label: tr('set_installed'), value: d.installDate ?? '—', mono: true),
                      EmsKeyValue(label: tr('set_status'), value: d.status, mono: true),
                    ],
                  ),
                  const SizedBox(height: EmsSpace.s5),
                ],
              ],
            ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final pw = TextEditingController();
    final confirmed = await showEmsSheet<bool>(
      context,
      eyebrow: tr('set_account'),
      title: tr('del_title'),
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmsBanner(tone: EmsTone.danger, icon: PhosphorIconsRegular.warningOctagon, message: tr('del_warning')),
          const SizedBox(height: EmsSpace.s5),
          EmsField(label: tr('del_confirmPw'), controller: pw, obscure: true, icon: PhosphorIconsRegular.lockKey, autofillHints: const [AutofillHints.password]),
          const SizedBox(height: EmsSpace.s6),
          EmsButton(label: tr('del_button'), kind: EmsButtonKind.danger, icon: PhosphorIconsRegular.trash, onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: EmsSpace.s3),
          EmsButton(label: tr('common_cancel'), kind: EmsButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
        ],
      ),
    );
    if (confirmed != true || pw.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await AuthFacade.deleteAccount(pw.text);
      if (!mounted) return;
      _toast(tr('del_done'));
      Navigator.of(context).pushNamedAndRemoveUntil(Etapa2Routes.login, (route) => false);
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SettingsData>(
      future: _future,
      builder: (context, snapshot) {
        final Widget? pill = snapshot.connectionState == ConnectionState.waiting
            ? null
            : snapshot.hasError
                ? EmsSignal(state: EmsSignalState.offline, label: tr('set_offline'))
                : EmsSignal(state: EmsSignalState.online, label: tr('set_syncOk'));
        return Etapa3Shell(
          title: tr('set_title'),
          subtitle: tr('set_subtitle'),
          selectedIndex: 4,
          onRefresh: _reload,
          trailing: pill,
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_SettingsData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Etapa3Loading();
    final data = snapshot.data;
    final operator = SessionStore.isOperator;
    final c = context.ems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data != null)
          _ProfileCard(profile: data.profile, operator: operator)
        else
          Etapa3Error(
            message: snapshot.error is ApiException ? (snapshot.error as ApiException).message : tr('set_errLoad'),
            onRetry: _reload,
          ),
        const SizedBox(height: EmsSpace.s7),
        EmsGroup(
          footer: tr('m_prefsLocal'),
          title: tr('set_preferences'),
          children: [
            EmsRow(
              icon: PhosphorIconsRegular.bellRinging,
              title: tr('set_push'),
              subtitle: tr('set_pushSub'),
              trailing: Switch(
                value: pushAlerts,
                onChanged: (value) {
                  AppSettingsStore.pushAlerts = value;
                  setState(() => pushAlerts = value);
                },
              ),
            ),
            if (!kIsWeb)
              EmsRow(
                icon: PhosphorIconsRegular.fingerprint,
                title: tr('m_bioLock'),
                subtitle: tr('m_bioLockSub'),
                trailing: Switch(
                  value: biometricLock,
                  onChanged: (value) {
                    AppSettingsStore.biometricLock = value;
                    setState(() => biometricLock = value);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(EmsSpace.s5, EmsSpace.s4, EmsSpace.s5, EmsSpace.s4),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: c.bgSunken, borderRadius: BorderRadius.circular(EmsRadius.sm), border: Border.all(color: c.border)),
                    child: Icon(PhosphorIconsRegular.translate, size: 18, color: c.textSecondary),
                  ),
                  const SizedBox(width: EmsSpace.s4),
                  Expanded(child: Text(tr('set_language'), style: context.type.body.copyWith(fontWeight: FontWeight.w500))),
                  SizedBox(
                    width: 132,
                    child: EmsSegmented<String>(
                      dense: true,
                      value: I18n.lang.value,
                      segments: const [('es', 'ES'), ('en', 'EN')],
                      onChanged: (v) => setState(() => I18n.set(v)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EmsSpace.s7),
        EmsGroup(
          title: tr('set_account'),
          children: [
            EmsRow(icon: PhosphorIconsRegular.user, title: tr('set_editProfile'), subtitle: tr('set_editProfileSub'), onTap: data == null ? null : () => _openSubPage(EditProfileScreen(profile: data.profile))),
            EmsRow(icon: PhosphorIconsRegular.password, title: tr('set_changePw'), subtitle: tr('set_changePwSub'), onTap: () => _openSubPage(const ChangePasswordScreen())),
          ],
        ),
        if (!operator) ...[
          const SizedBox(height: EmsSpace.s7),
          EmsGroup(
            title: tr('m_homeData'),
            children: [
              EmsRow(
                icon: PhosphorIconsRegular.cpu,
                title: tr('set_deviceInfo'),
                subtitle: tr('set_deviceInfoSub'),
                value: data == null ? null : '${data.devices.length}',
                mono: true,
                onTap: data == null ? null : () => _showDeviceInfo(data.devices),
              ),
              EmsRow(
                icon: PhosphorIconsRegular.export,
                title: tr('set_export'),
                subtitle: tr('set_exportSub'),
                trailing: _busy ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)) : null,
                onTap: _busy ? null : _exportCsv,
              ),
            ],
          ),
        ],
        const SizedBox(height: EmsSpace.s7),
        EmsGroup(
          title: tr('m_session'),
          children: [
            EmsRow(icon: PhosphorIconsRegular.signOut, title: tr('set_signOut'), subtitle: tr('set_signOutSub'), onTap: _signOut),
            EmsRow(icon: PhosphorIconsRegular.trash, title: tr('set_deleteAccount'), subtitle: tr('set_deleteAccountSub'), destructive: true, onTap: _busy ? null : _confirmDeleteAccount),
          ],
        ),
        const SizedBox(height: EmsSpace.s7),
        Center(child: Text('EMSafe · ${tr('ds_notMetrology')}', textAlign: TextAlign.center, style: context.type.caption)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.operator});

  final ClientProfile profile;
  final bool operator;

  @override
  Widget build(BuildContext context) {
    final c = context.ems;
    final initials = (profile.initials?.isNotEmpty == true
            ? profile.initials!
            : profile.name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join())
        .toUpperCase();
    return EmsPanel(
      padding: const EdgeInsets.all(EmsSpace.s5),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.chrome, borderRadius: BorderRadius.circular(EmsRadius.md), border: Border.all(color: c.chromeBorder)),
            child: Text(initials, style: context.type.h3.copyWith(color: c.chromeText)),
          ),
          const SizedBox(width: EmsSpace.s5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.h4),
                const SizedBox(height: 2),
                Text(profile.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.bodySm),
                const SizedBox(height: EmsSpace.s3),
                Wrap(
                  spacing: EmsSpace.s3,
                  runSpacing: EmsSpace.s2,
                  children: [
                    EmsTag(tr(operator ? 'm_segOperator' : 'm_segHome'), tone: EmsTone.primary, icon: operator ? PhosphorIconsRegular.hardHat : PhosphorIconsRegular.house),
                    if (profile.joinDate != null) EmsTag('${tr('m_since')} ${profile.joinDate}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
