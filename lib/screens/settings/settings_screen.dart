import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
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
                    AuraDisclosure(
                      label: 'About',
                      level: AuraLevel.crown,
                      onTap: () => _show(
                        context,
                        'About',
                        'Karmic Healing\nVersion 1.0',
                      ),
                    ),
                    AuraDisclosure(
                      label: 'Theme',
                      level: AuraLevel.brow,
                      onTap: () => _show(context, 'Theme', 'System appearance'),
                    ),
                    AuraDisclosure(
                      label: 'Session Duration',
                      level: AuraLevel.brow,
                      onTap: () => _show(
                        context,
                        'Session Duration',
                        '5 minutes per step',
                      ),
                    ),
                    AuraDisclosure(
                      label: 'Change Language',
                      level: AuraLevel.brow,
                      onTap: () => _show(context, 'Language', 'English'),
                    ),
                    AuraDisclosure(
                      label: 'Privacy Policy',
                      level: AuraLevel.crown,
                      onTap: () => _show(
                        context,
                        'Privacy Policy',
                        'Your information stays private.',
                      ),
                    ),
                    AuraDisclosure(
                      label: 'Write to Us',
                      level: AuraLevel.brow,
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
        title: Text(
          title,
          style: const TextStyle(fontFamily: '.SF Pro Display'),
        ),
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
