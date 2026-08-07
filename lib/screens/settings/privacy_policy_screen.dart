import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'Introduction',
      'Karmic Healing works on iPhone, iPad, and Apple Watch and is designed to work offline. We do not operate servers that collect, store, or process your personal information.',
    ),
    (
      'Data Collection',
      'The app does not require an account and does not send your reminders, requests, notes, or app activity to us. Information you enter is kept on your device for the app to function. We do not use analytics, advertising identifiers, or usage-tracking services.',
    ),
    (
      'Data Storage',
      'Your reminders, requests, notes, and preferences are stored locally in the app’s storage on your Apple device. The app does not provide cloud sync. Depending on your iOS backup settings, app data may be included in a device backup. Any backup or restore service is governed by the policies and settings of Apple or the service you choose.',
    ),
    (
      'Local Notifications',
      'If you grant permission, Karmic Healing schedules local notifications for reminders. Notification titles, text, and identifiers are used by the operating system to display and open those reminders; they are not sent to our servers. You can change notification access at any time in your device settings.',
    ),
    (
      'Third-Party Services',
      'The app contains no third-party analytics, advertising, tracking pixels, cookies, or data-collection SDKs. It does use open-source software libraries to provide app functionality. If you choose to open an external website or contact us by email, that interaction is handled by the relevant website, App Store, or email provider under its own privacy policy. The app does not send your stored app data along with those actions.',
    ),
    (
      'Contact Us',
      'If you contact us, we receive the information you choose to include so that we can respond to your request.',
    ),
  ];

  @override
  Widget build(BuildContext context) => ScrollBlur(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: const ScrollBlurBackdrop(),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const AuraIcon(SFSymbols.xmark, level: AuraLevel.crown),
          ),
        ],
      ),
      body: GradientBackground(
        tone: AppColors.wisdom,
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  12,
                  DesignConstants.navigationBarInset(context) + 8,
                  12,
                  32,
                ),
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontFamily: 'Source Serif 4',
                      fontSize: 28,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AuraLabel('Last updated: August 6, 2026'),
                  const SizedBox(height: 32),
                  for (final section in _sections) ...[
                    Text(
                      section.$1,
                      style: const TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      section.$2,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 17,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
