import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Everything the settings screen reaches for outside the app: the bundle's own
/// version, the author's site, a mail composer.
///
/// The screen knows only this much of it, so a test can hand it one that
/// records what was asked for instead of opening anything on the machine
/// running the test.
abstract class SettingsActions {
  const SettingsActions();

  /// The version to show in About, as the store shows it — `1.0.0 (1)`.
  Future<String> appVersion();

  /// Opens [url] outside the app. Returns false if nothing on the device would
  /// take it — a phone with no mail account set up, say.
  Future<bool> openUrl(Uri url);

  Future<void> copyToClipboard(String text);
}

/// The actions the running app gets.
class PlatformSettingsActions extends SettingsActions {
  const PlatformSettingsActions();

  @override
  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  @override
  Future<bool> openUrl(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on PlatformException catch (error) {
      // A device with no mail app at all throws rather than answering false.
      debugPrint('Could not open $url: ${error.message}');
      return false;
    }
  }

  @override
  Future<void> copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
