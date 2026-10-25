import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../contexts/iam/application/auth_facade.dart';
import '../../contexts/iam/domain/client_profile.dart';
import '../../contexts/iam/infrastructure/session_store.dart';
import '../../contexts/iottelemetry/application/device_facade.dart';
import '../../contexts/iottelemetry/domain/client_device.dart';
import '../../contexts/radiationmonitoring/application/monitoring_facade.dart';
import '../../core/http/api_client.dart';
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

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool pushAlerts = AppSettingsStore.pushAlerts;

  late Future<_SettingsData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SettingsData> _load() async {
    final profile = await AuthFacade.profile();
    final devices = await DeviceFacade.all();
    return _SettingsData(profile, devices);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signOut() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Etapa2Routes.login, (route) => false);
  }

  Future<void> _openSubPage(Widget page) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => page));
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
        buf.writeln(
            '${r.id},"$device",${r.value ?? ''},${r.level ?? ''},${r.readingDate ?? ''}');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/emsafe_readings.csv');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'EMSafe readings (µT)'),
      );
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showDeviceInfo(List<ClientDevice> devices) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Etapa3Palette.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('set_deviceInfo'),
                style: const TextStyle(
                  color: Etapa3Palette.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              if (devices.isEmpty)
                Text(
                  tr('set_noSensors'),
                  style: const TextStyle(
                      color: Etapa3Palette.muted, fontSize: 13),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Etapa3Palette.stroke, height: 18),
                    itemBuilder: (context, i) {
                      final d = devices[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(
                              color: Etapa3Palette.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${tr('set_serial')}: ${d.serialNumber ?? '--'}'
                            '  ·  ${tr('set_type')}: ${d.type}\n'
                            '${tr('set_installed')}: ${d.installDate ?? '--'}'
                            '  ·  ${tr('set_status')}: ${d.status}',
                            style: const TextStyle(
                              color: Etapa3Palette.muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final pw = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Etapa3Palette.panel,
        title: Text(
          tr('del_title'),
          style: const TextStyle(
              color: Etapa3Palette.red, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('del_warning'),
              style: const TextStyle(
                  color: Etapa3Palette.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pw,
              obscureText: true,
              style: const TextStyle(color: Etapa3Palette.text),
              decoration: InputDecoration(
                hintText: tr('del_confirmPw'),
                hintStyle: const TextStyle(
                    color: Etapa3Palette.quiet, fontSize: 13),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Etapa3Palette.stroke),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Etapa3Palette.red),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('common_cancel'),
                style: const TextStyle(color: Etapa3Palette.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('del_button'),
                style: const TextStyle(
                    color: Etapa3Palette.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true || pw.text.isEmpty) return;

    setState(() => _busy = true);
    try {
      await AuthFacade.deleteAccount(pw.text);
      if (!mounted) return;
      _toast(tr('del_done'));
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Etapa2Routes.login, (route) => false);
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
        // Honest sync pill: green when the backend answered, red when it failed.
        final Widget? pill = snapshot.connectionState == ConnectionState.waiting
            ? null
            : snapshot.hasError
                ? StatusPill(
                    label: tr('set_offline'),
                    color: Etapa3Palette.red,
                    icon: Icons.cloud_off_outlined,
                  )
                : StatusPill(
                    label: tr('set_syncOk'),
                    color: Etapa3Palette.green,
                    icon: Icons.cloud_done_outlined,
                  );

        return Etapa3Shell(
          title: tr('set_title'),
          subtitle: tr('set_subtitle'),
          selectedIndex: 4,
          trailing: pill,
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_SettingsData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Etapa3Loading();
    }
    if (snapshot.hasError) {
      final msg = snapshot.error is ApiException
          ? (snapshot.error as ApiException).message
          : tr('set_errLoad');
      return Etapa3Error(message: msg, onRetry: _reload);
    }
    final data = snapshot.data!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileCard(profile: data.profile, deviceCount: data.devices.length),
        const SizedBox(height: 20),
        SectionLabel(tr('set_preferences')),
        const SizedBox(height: 10),
        _SettingsSwitch(
          icon: Icons.notifications_active_outlined,
          title: tr('set_push'),
          subtitle: tr('set_pushSub'),
          value: pushAlerts,
          onChanged: (value) {
            AppSettingsStore.pushAlerts = value;
            setState(() => pushAlerts = value);
          },
        ),
        const SizedBox(height: 10),
        _SettingsSwitch(
          icon: Icons.translate,
          title: tr('set_language'),
          subtitle: tr('set_langSub'),
          value: I18n.lang.value == 'es',
          onChanged: (value) {
            I18n.set(value ? 'es' : 'en');
            setState(() {});
          },
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('set_account')),
        const SizedBox(height: 10),
        GlassPanel(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.person_outline,
                title: tr('set_editProfile'),
                subtitle: tr('set_editProfileSub'),
                onTap: () => _openSubPage(const EditProfileScreen()),
              ),
              const Divider(color: Etapa3Palette.stroke, height: 1),
              _ActionRow(
                icon: Icons.lock_outline,
                title: tr('set_changePw'),
                subtitle: tr('set_changePwSub'),
                onTap: () => _openSubPage(const ChangePasswordScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('set_maintenance')),
        const SizedBox(height: 10),
        GlassPanel(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.memory_outlined,
                title: tr('set_deviceInfo'),
                subtitle: tr('set_deviceInfoSub'),
                onTap: () => _showDeviceInfo(data.devices),
              ),
              const Divider(color: Etapa3Palette.stroke, height: 1),
              _ActionRow(
                icon: Icons.history_toggle_off,
                title: tr('set_export'),
                subtitle: tr('set_exportSub'),
                onTap: _busy ? null : _exportCsv,
              ),
              const Divider(color: Etapa3Palette.stroke, height: 1),
              _ActionRow(
                icon: Icons.logout,
                title: tr('set_signOut'),
                subtitle: tr('set_signOutSub'),
                destructive: true,
                onTap: _signOut,
              ),
              const Divider(color: Etapa3Palette.stroke, height: 1),
              _ActionRow(
                icon: Icons.delete_forever_outlined,
                title: tr('set_deleteAccount'),
                subtitle: tr('set_deleteAccountSub'),
                destructive: true,
                onTap: _busy ? null : _confirmDeleteAccount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.deviceCount});

  final ClientProfile profile;
  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    final sensorsWord =
        deviceCount == 1 ? tr('set_sensor') : tr('set_sensors_lc');
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Etapa3Palette.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Etapa3Palette.blue.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              (profile.initials?.isNotEmpty == true
                  ? profile.initials!
                  : (profile.name.isNotEmpty ? profile.name[0] : '?')),
              style: const TextStyle(
                color: Etapa3Palette.blue,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? tr('set_myAccount') : profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$deviceCount $sensorsWord ${tr('set_monitored')}'
                  '${profile.address != null ? ' · ${profile.address}' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Etapa3Palette.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Etapa3Palette.cyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Etapa3Palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Etapa3Palette.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Etapa3Palette.cyan,
            activeTrackColor: Etapa3Palette.cyan.withValues(alpha: 0.28),
            inactiveThumbColor: Etapa3Palette.quiet,
            inactiveTrackColor: Etapa3Palette.stroke,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Etapa3Palette.red : Etapa3Palette.blue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: destructive
                          ? Etapa3Palette.red
                          : Etapa3Palette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Etapa3Palette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Etapa3Palette.quiet,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
