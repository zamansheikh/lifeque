// ==========================================
// GITHUB UPDATE SERVICE (DEPRECATED)
// ==========================================
// This service has been replaced with Google Play Store in-app updates
// Using in_app_update package for better user experience
// Keeping this code commented for reference and potential future use

/*
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UpdateService {
  static const String _githubRepo = 'zamansheikh/lifeque';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';

  /// Check if an update is available
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      debugPrint('🔄 Checking for app updates...');

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      debugPrint('📱 Current app version: $currentVersion+$currentBuildNumber');

      // Fetch latest release from GitHub
      final response = await http
          .get(
            Uri.parse(_githubApiUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'LifeQue-App',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTag = data['tag_name'] as String;
        final releaseUrl = data['html_url'] as String;
        final releaseNotes = data['body'] as String? ?? '';
        final publishedAt = data['published_at'] as String;

        debugPrint('🆕 Latest GitHub version: $latestTag');

        // Parse version from tag
        // Handles both: "v1.0.4" (old) and "v1.0.0+5" (new workflow)
        final versionMatch = RegExp(
          r'v?(\d+\.\d+\.\d+)(?:\+(\d+))?',
        ).firstMatch(latestTag);
        if (versionMatch != null) {
          final latestVersion = versionMatch.group(1) ?? '1.0.0';
          final latestBuildNumber =
              int.tryParse(versionMatch.group(2) ?? '1') ?? 1;

          debugPrint('🔍 Parsed latest: $latestVersion+$latestBuildNumber');
          debugPrint('🔍 Current: $currentVersion+$currentBuildNumber');

          // Compare only version numbers (ignore build numbers)
          final latestVersionParts = latestVersion
              .split('.')
              .map(int.parse)
              .toList();
          final currentVersionParts = currentVersion
              .split('.')
              .map(int.parse)
              .toList();

          bool isUpdateAvailable = false;
          for (int i = 0; i < 3; i++) {
            if (latestVersionParts[i] > currentVersionParts[i]) {
              isUpdateAvailable = true;
              break;
            } else if (latestVersionParts[i] < currentVersionParts[i]) {
              break;
            }
          }

          // Check if update is available (compare version numbers only)
          if (isUpdateAvailable) {
            debugPrint('✅ Update available!');

            // Find APK download URL
            String? downloadUrl;
            final assets = data['assets'] as List<dynamic>?;
            if (assets != null) {
              for (final asset in assets) {
                final name = asset['name'] as String;
                if (name.endsWith('.apk')) {
                  downloadUrl = asset['browser_download_url'] as String;
                  break;
                }
              }
            }

            return UpdateInfo(
              currentVersion: '$currentVersion+$currentBuildNumber',
              latestVersion: '$latestVersion+$latestBuildNumber',
              releaseUrl: releaseUrl,
              downloadUrl: downloadUrl,
              releaseNotes: releaseNotes,
              publishedAt: DateTime.parse(publishedAt),
              isUpdateAvailable: true,
            );
          } else {
            debugPrint(
              '✅ App is up to date. Both versions: $currentVersion vs $latestVersion',
            );
            return UpdateInfo(
              currentVersion: '$currentVersion+$currentBuildNumber',
              latestVersion: '$latestVersion+$latestBuildNumber',
              releaseUrl: releaseUrl,
              downloadUrl: null,
              releaseNotes: releaseNotes,
              publishedAt: DateTime.parse(publishedAt),
              isUpdateAvailable: false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
    }

    return null;
  }

  /// Show update dialog to user
  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    if (!updateInfo.isUpdateAvailable) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Update Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'A new version of LifeQue is available!\n\n',
                      ),
                      const TextSpan(
                        text: 'Current Version: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: '${updateInfo.currentVersion}\n'),
                      const TextSpan(
                        text: 'Latest Version: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: updateInfo.latestVersion,
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFFFD700)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFFA000),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Important: To avoid conflicts, please uninstall the previous version of RemindMe before installing LifeQue.',
                          style: TextStyle(
                            color: Color(0xFF856404),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (updateInfo.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'What\'s New:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: MarkdownBody(
                      data: updateInfo.releaseNotes,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        h1: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: TextStyle(
                          color: Colors.purple.shade400,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        strong: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        blockquote: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade200,
                          fontFamily: 'monospace',
                        ),
                        listBullet: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Later',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _downloadUpdate(context, updateInfo);
              },
              style:
                  ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Download and install update
  static Future<void> _downloadUpdate(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    try {
      String urlToOpen = updateInfo.downloadUrl ?? updateInfo.releaseUrl;

      if (Platform.isAndroid) {
        // For Android, prefer direct APK download if available
        if (updateInfo.downloadUrl != null) {
          urlToOpen = updateInfo.downloadUrl!;

          // Show download instructions
          _showDownloadInstructions(context);
        }
      }

      final uri = Uri.parse(urlToOpen);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlToOpen';
      }
    } catch (e) {
      debugPrint('❌ Error downloading update: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show download instructions
  static void _showDownloadInstructions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download started!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Please install the APK when download completes.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Check for updates silently (for background checks)
  static Future<UpdateInfo?> checkForUpdateSilently() async {
    try {
      return await checkForUpdate();
    } catch (e) {
      debugPrint('❌ Silent update check failed: $e');
      return null;
    }
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String? downloadUrl;
  final String releaseNotes;
  final DateTime publishedAt;
  final bool isUpdateAvailable;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
    required this.isUpdateAvailable,
  });

  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion, latest: $latestVersion, available: $isUpdateAvailable)';
  }
}
*/

// ==========================================
// END OF DEPRECATED GITHUB UPDATE SERVICE
// ==========================================
