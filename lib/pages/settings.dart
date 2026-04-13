import 'package:flutter/material.dart';
import '../services/auth_service.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Nustatymai',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
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
                subtitle: "vartotojas@email.com",
                onTap: () {},
              ),
            ],
          ),

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

          _SettingsCard(
            title: "Paskyra",
            children: [
              _SettingsTile(
                icon: Icons.logout,
                iconColor: Colors.red,
                title: "Atsijungti",
                subtitle: null,
                onTap: () async {
                  await AuthService.signOut();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                await AuthService.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}