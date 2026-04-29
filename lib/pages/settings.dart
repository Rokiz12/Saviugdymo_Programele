import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'questionaire.dart';
import '../widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: "Nustatymai"),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // PROFILIS
          _SettingsCard(
            title: "Profilis",
            children: [
              _SettingsTile(
                icon: Icons.person,
                iconColor: Colors.yellow,
                title: "Vardas",
                subtitle: "Vartotojas",
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.email,
                iconColor: Colors.blue,
                title: "El. paštas",
                subtitle: FirebaseAuth.instance.currentUser?.email,
                onTap: () {},
              ),
            ],
          ),

          // TEMA
          _SettingsCard(
            title: "Tema",
            children: [
              _SettingsRadioTile(
                icon: Icons.light_mode,
                title: "Šviesi",
                isSelected: true,
                onTap: () {},
              ),
              _SettingsRadioTile(
                icon: Icons.dark_mode,
                title: "Tamsi",
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),

          // KALBA
          _SettingsCard(
            title: "Kalba",
            children: [
              _SettingsRadioTile(
                icon: Icons.translate,
                title: "Lietuvių",
                isSelected: true,
                onTap: () {},
              ),
              _SettingsRadioTile(
                icon: Icons.translate,
                title: "Anglų",
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),

          // PRENUMERATA
          _SettingsCard(
            title: "Prenumerata",
            children: [
              _SettingsTile(
                icon: Icons.star,
                iconColor: Colors.amber,
                title: "Premium",
                subtitle: "Neaktyvi",
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Aktyvuoti",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),

          // LOGOUT
          _SettingsCard(
            title: "Paskyra",
            children: [
              _SettingsTile(
                icon: Icons.quiz,
                iconColor: Colors.red,
                title: "Perdaryti norų klausimyną",
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
                title: "Atsijungti",
                onTap: () async {
                  await AuthService.signOut();

                  // optional redirect
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'Version 1.0.0',
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