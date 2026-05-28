import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'questionaire.dart';
import '../widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/language_notifier.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.read<ThemeNotifier>();
    final lang = context.watch<LanguageNotifier>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(title: lang.t('settings_title')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // PROFILIS
          _SettingsCard(
            title: lang.t('profile_title'),
            children: [
              _SettingsTile(
                icon: Icons.email,
                iconColor: Colors.blue,
                title: lang.t('email_label'),
                subtitle: FirebaseAuth.instance.currentUser?.email,
                onTap: () {},
              ),
            ],
          ),

          // TEMA
          _SettingsCard(
            title: lang.t('theme_title'),
            children: [
              _SettingsRadioTile(
                icon: Icons.light_mode,
                title: lang.t('theme_light'),
                isSelected: themeNotifier.mode == AppMode.light,
                onTap: () => themeNotifier.setMode(AppMode.light),
              ),
              _SettingsRadioTile(
                icon: Icons.dark_mode,
                title: lang.t('theme_dark'),
                isSelected: themeNotifier.mode == AppMode.dark,
                onTap: () => themeNotifier.setMode(AppMode.dark),
              ),
            ],
          ),

          // KALBA
          _SettingsCard(
            title: lang.t('language_title'),
            children: [
              _SettingsRadioTile(
                icon: Icons.translate,
                title: lang.t('lang_lt'),
                isSelected: lang.language == AppLanguage.lt,
                onTap: () => lang.setLanguage(AppLanguage.lt),
              ),
              _SettingsRadioTile(
                icon: Icons.translate,
                title: lang.t('lang_en'),
                isSelected: lang.language == AppLanguage.en,
                onTap: () => lang.setLanguage(AppLanguage.en),
              ),
            ],
          ),

          // PRENUMERATA
          _SettingsCard(
            title: lang.t('premium_title'),
            children: [
              _SettingsTile(
                icon: Icons.star,
                iconColor: Colors.amber,
                title: 'Premium',
                subtitle: lang.t('premium_activated_false'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    lang.t('premium_activate'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),

          // LOGOUT
          _SettingsCard(
            title: lang.t('account_title'),
            children: [
              _SettingsTile(
                icon: Icons.quiz,
                iconColor: Colors.red,
                title: lang.t('redo_questionnaire'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuestionnaireScreen(),
                    ),
                  );
                },
              ),

              _SettingsTile(
                icon: Icons.logout,
                iconColor: Colors.red,
                title: lang.t('logout'),
                onTap: () async {
                  await AuthService.signOut();
                  Navigator.pop(context);
                },
              ),

              _SettingsTile(
                icon: Icons.delete_forever,
                iconColor: Colors.red,
                title: lang.t('delete_account'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(lang.t('delete_confirm_title')),
                      content: Text(lang.t('delete_confirm_text')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(lang.t('cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            lang.t('delete'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {
                    await FirebaseAuth.instance.currentUser?.delete();
                    Navigator.pushReplacementNamed(context, '/login');
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'requires-recent-login') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(lang.t('recent_login_required')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              '${lang.t('version')} 1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ================= UI COMPONENTAI =================

// Kortelė
class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// Paprastas tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// Radio tile
class _SettingsRadioTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SettingsRadioTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.grey[600], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.yellow[700]!
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.yellow[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}