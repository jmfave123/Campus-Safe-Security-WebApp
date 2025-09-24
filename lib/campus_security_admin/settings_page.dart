import 'package:flutter/material.dart';
import '../widgets/settings_page_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: SettingsPageUI.buildBackgroundDecoration(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsPageUI.buildHeader(),
                const SizedBox(height: 40),

                // Profile Management Section
                SettingsPageUI.buildSettingsSection(
                  title: 'Profile Management',
                  icon: Icons.person,
                  child: const ProfileManagementWidget(),
                ),

                const SizedBox(height: 24),

                // Account Security Section
                SettingsPageUI.buildSettingsSection(
                  title: 'Account Security',
                  icon: Icons.security,
                  child: const AccountSecurityWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
