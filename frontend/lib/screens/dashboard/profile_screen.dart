import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final stats = context.watch<ComplaintProvider>().stats;

    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen],
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (user?.isVerified == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified,
                                color: AppTheme.primaryGreen, size: 18),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.roleLabel ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (user?.mtaa != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${user!.mtaa}, ${user.ward}, ${user.district}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Stats Row
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _StatItem(
                    label: l.totalComplaints,
                    value: stats['total'].toString(),
                    color: AppTheme.primaryGreen,
                  ),
                  _Divider(),
                  _StatItem(
                    label: l.statusResolved,
                    value: stats['resolved'].toString(),
                    color: AppTheme.statusResolved,
                  ),
                  _Divider(),
                  _StatItem(
                    label: l.statusPending,
                    value: stats['pending'].toString(),
                    color: AppTheme.statusPending,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Settings Sections
            _SectionCard(
              children: [
                _SettingTile(
                  icon: Icons.language_outlined,
                  title: l.language,
                  trailing: GestureDetector(
                    onTap: localeProvider.toggleLocale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localeProvider.isSwahili ? '🇹🇿' : '🇬🇧',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            localeProvider.isSwahili ? 'Kiswahili' : 'English',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _SettingTile(
                  icon: Icons.dark_mode_outlined,
                  title: l.darkMode,
                  trailing: Switch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeThumbColor: AppTheme.primaryGreen,
                  ),
                ),
                _SettingTile(
                  icon: Icons.notifications_outlined,
                  title: l.notifications2,
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                  onTap: () => _showNotificationSettings(context, l),
                ),
              ],
            ),

            _SectionCard(
              children: [
                _SettingTile(
                  icon: Icons.help_outline_rounded,
                  title: l.aboutApp,
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                  onTap: () => _showAboutDialog(context, l),
                ),
                _SettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l.privacyPolicy,
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                  onTap: () => _showPrivacyPolicy(context, l),
                ),
                _SettingTile(
                  icon: Icons.support_agent_outlined,
                  title: l.contactSupport,
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                  onTap: () => _showContactSupport(context, l),
                ),
              ],
            ),

            _SectionCard(
              children: [
                _SettingTile(
                  icon: Icons.logout_rounded,
                  title: l.logout,
                  titleColor: Colors.red.shade600,
                  iconColor: Colors.red.shade400,
                  onTap: () => _confirmLogout(context, auth, l),
                ),
              ],
            ),

            // Version
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${l.version} 1.0.0 · Sauti ya Raia',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.isSwahili
                ? 'Mfumo wa Malalamiko ya Raia wa Tanzania\n\nRaia wanaweza kuwasilisha malalamiko yao kuanzia ngazi ya Mtaa, na kama hayashughulikiwa, yanakuwa yanapandishwa kiotomatiki hadi ngazi ya juu.'
                : 'Tanzania Citizen Complaint & Escalation Platform\n\nCitizens can submit complaints at the Mtaa level. If unaddressed within set timeframes, complaints automatically escalate to Ward → District → Region → National level.'),
            const SizedBox(height: 12),
            Text('${l.version}: 1.0.0',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, AppLocalizations l) {
    bool enabled = true;
    bool escalation = true;
    bool resolved = true;
    bool comments = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l.notificationSettings),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(l.notificationsEnabled),
                value: enabled,
                onChanged: (v) => setS(() => enabled = v),
                activeThumbColor: AppTheme.primaryGreen,
                dense: true,
              ),
              if (enabled) ...[
                SwitchListTile(
                  title: Text(l.notificationsEscalation),
                  value: escalation,
                  onChanged: (v) => setS(() => escalation = v),
                  activeThumbColor: AppTheme.primaryGreen,
                  dense: true,
                ),
                SwitchListTile(
                  title: Text(l.notificationsResolved),
                  value: resolved,
                  onChanged: (v) => setS(() => resolved = v),
                  activeThumbColor: AppTheme.primaryGreen,
                  dense: true,
                ),
                SwitchListTile(
                  title: Text(l.notificationsComments),
                  value: comments,
                  onChanged: (v) => setS(() => comments = v),
                  activeThumbColor: AppTheme.primaryGreen,
                  dense: true,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.done),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.privacyPolicyTitle),
        content: SingleChildScrollView(child: Text(l.privacyPolicyBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.contactSupportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryGreen),
              title: Text(l.contactPhone),
              subtitle: const Text('+255 800 000 000'),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
              title: Text(l.contactEmail),
              subtitle: const Text('support@sautiyaraia.go.tz'),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.access_time_outlined, color: AppTheme.primaryGreen),
              title: Text(l.isSwahili ? 'Masaa ya Kazi' : 'Office Hours'),
              subtitle: Text(l.contactHours),
              dense: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(
      BuildContext context, AuthProvider auth, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.logout),
        content: Text(l.isSwahili
            ? 'Una uhakika unataka kutoka?'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              context.read<ComplaintProvider>().clearComplaints();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text(l.logout,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.divider);
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: children
            .expand((w) => [
                  w,
                  if (w != children.last)
                    const Divider(height: 1, indent: 52),
                ])
            .toList(),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryGreen).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: iconColor ?? AppTheme.primaryGreen, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: titleColor),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
