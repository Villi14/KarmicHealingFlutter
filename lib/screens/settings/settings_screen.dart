import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/disclosure_cell.dart';
import '../../widgets/gradient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      leading: IconButton(
        onPressed: Get.back,
        icon: const AuraIcon(Icons.chevron_left, level: AuraLevel.brow),
      ),
    ),
    body: GradientBackground(
      tone: AppColors.peace,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AuraCard(
                level: AuraLevel.brow,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DisclosureCell(
                      title: 'About',
                      onTap: () => _show(
                        context,
                        'About',
                        'Karmic Healing\nVersion 1.0',
                      ),
                    ),
                    DisclosureCell(
                      title: 'Theme',
                      onTap: () => _show(context, 'Theme', 'System appearance'),
                    ),
                    DisclosureCell(
                      title: 'Session Duration',
                      onTap: () => _show(
                        context,
                        'Session Duration',
                        '5 minutes per step',
                      ),
                    ),
                    DisclosureCell(
                      title: 'Change Language',
                      onTap: () => _show(context, 'Language', 'English'),
                    ),
                    DisclosureCell(
                      title: 'Privacy Policy',
                      onTap: () => _show(
                        context,
                        'Privacy Policy',
                        'Your information stays private.',
                      ),
                    ),
                    DisclosureCell(
                      title: 'Write to Us',
                      onTap: () => _show(
                        context,
                        'Write to Us',
                        'We would love to hear from you.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _show(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontFamily: 'Inter')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
