import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/in_app_update_service.dart';
import '../../../../core/services/language_preference_service.dart';
import '../../../../core/services/navigation_preferences_service.dart';
import '../../../../injection_container.dart' as di;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late NavigationPreferencesService _svc;
  late List<NavItem> _items;

  final _languageService = LanguagePreferenceService.instance;
  AppLanguage _language = AppLanguage.english;

  static const _privacyPolicyUrl =
      'https://zamansheikh.github.io/lifeque/privacy-policy.html';
  static const _termsUrl =
      'https://zamansheikh.github.io/lifeque/privacy-policy.html';

  @override
  void initState() {
    super.initState();
    _svc = NavigationPreferencesService(di.sl<SharedPreferences>());
    _items = _svc.getOrderedItems();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await _languageService.getLanguage();
    if (!mounted) return;
    setState(() => _language = language);
  }

  // ── Navigation Order Bottom Sheet ──────────────────────────────
  void _showNavigationOrderSheet() {
    // Work on a copy so we can discard on cancel
    var tempItems = List<NavItem>.from(_items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // A Material, not a white Container: the sheet is transparent, so
            // a plain DecoratedBox here would be the nearest painted surface
            // above the tiles and would swallow their ink.
            return Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.72,
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.swap_vert_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Navigation Order',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Drag to reorder. First item = home page.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Home chip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.home_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Home page:  ${tempItems.first.label}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Reorderable list
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: tempItems.length,
                          // onReorderItem already accounts for the removed
                          // item, so the old `if (newIndex > oldIndex)` fix-up
                          // that onReorder needed would now be off by one.
                          onReorderItem: (oldIndex, newIndex) {
                            setSheetState(() {
                              final item = tempItems.removeAt(oldIndex);
                              tempItems.insert(newIndex, item);
                            });
                          },
                          proxyDecorator: (child, index, animation) => Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            color: colorScheme.primary.withValues(alpha: 0.05),
                            child: child,
                          ),
                          itemBuilder: (context, index) {
                            final item = tempItems[index];
                            final isFirst = index == 0;
                            return _OrderTile(
                              key: ValueKey(item.route),
                              item: item,
                              isFirst: isFirst,
                              colorScheme: colorScheme,
                            );
                          },
                        ),
                      ),
                    ),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: () async {
                                // Apply order
                                setState(() => _items = tempItems);
                                await _svc.saveOrder(_items);
                                // Two different contexts, so two guards: `ctx`
                                // belongs to the sheet being popped, `context`
                                // to this State.
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Navigation order saved',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Save Order'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Language ───────────────────────────────────────────────────

  /// Pick the app language.
  ///
  /// English is the only translated one today. Bangla is offered because the
  /// choice is being collected ahead of the strings landing — picking it saves
  /// the preference and says plainly that the UI stays in English until then,
  /// rather than switching to a half-translated screen.
  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.translate_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final language in AppLanguage.values)
                  _languageOption(ctx, language, colorScheme),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageOption(
    BuildContext sheetContext,
    AppLanguage language,
    ColorScheme colorScheme,
  ) {
    final selected = _language == language;

    return ListTile(
      onTap: () => _selectLanguage(sheetContext, language),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? colorScheme.primary : Colors.grey.shade400,
      ),
      title: Text(
        language.nativeLabel,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: selected ? colorScheme.primary : Colors.grey.shade900,
        ),
      ),
      subtitle: Text(
        language.isTranslated
            ? language.label
            : '${language.label} · coming soon',
        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
      ),
    );
  }

  Future<void> _selectLanguage(
    BuildContext sheetContext,
    AppLanguage language,
  ) async {
    await _languageService.setLanguage(language);
    if (!sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    if (!mounted) return;

    setState(() => _language = language);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          language.isTranslated
              ? 'Language set to ${language.nativeLabel}'
              : '${language.nativeLabel} is saved. The app stays in English '
                    'until the translation ships.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Check for Updates ──────────────────────────────────────────
  Future<void> _checkForUpdates() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking for updates...',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );

      final updateInfo = await InAppUpdateService.checkForUpdates();
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      if (updateInfo == null) {
        _showUpToDateDialog();
      } else {
        await InAppUpdateService.showUpdateDialog(context, updateInfo);
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showUpdateErrorDialog();
    }
  }

  void _showUpToDateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text("You're Up to Date!"),
          ],
        ),
        content: Text(
          'You have the latest version of LifeQue.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUpdateErrorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Update Check Failed'),
          ],
        ),
        content: Text(
          'Unable to check for updates. Please ensure you have an active internet connection and try again.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── About Dialog ───────────────────────────────────────────────
  Future<void> _showAboutSheet(BuildContext ctx) async {
    final packageInfo = await PackageInfo.fromPlatform();
    // `ctx` is a parameter, so this State's `mounted` says nothing about
    // whether it is still in the tree.
    if (!ctx.mounted) return;
    final colorScheme = Theme.of(ctx).colorScheme;

    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LifeQue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Version ${packageInfo.version}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A beautiful and intuitive app to manage your daily tasks and medicine reminders.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developed by',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Zaman Sheikh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSocialButton(
                          icon: Icons.code_rounded,
                          label: 'GitHub',
                          url: 'https://github.com/zamansheikh/',
                          color: Colors.grey.shade800,
                        ),
                        const SizedBox(width: 12),
                        _buildSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          url: 'https://www.facebook.com/zamansheikh.404',
                          color: const Color(0xFF1877F2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── URL Launcher Helper ────────────────────────────────────────
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── General section ─────────────────────────────────────
          _SectionHeader(label: 'General', color: colorScheme.primary),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.swap_vert_rounded,
                iconColor: colorScheme.primary,
                iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
                title: 'Navigation Order',
                subtitle: 'Home: ${_items.first.label}',
                onTap: _showNavigationOrderSheet,
              ),
              _SettingsTile(
                icon: Icons.translate_rounded,
                iconColor: Colors.purple.shade600,
                iconBgColor: Colors.purple.withValues(alpha: 0.1),
                title: 'Language',
                subtitle: _language.nativeLabel,
                onTap: _showLanguageSheet,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── App section ─────────────────────────────────────────
          _SectionHeader(label: 'App', color: colorScheme.primary),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.system_update_rounded,
                iconColor: Colors.teal.shade600,
                iconBgColor: Colors.teal.withValues(alpha: 0.1),
                title: 'Check for Updates',
                subtitle: 'See if a newer version is available',
                onTap: _checkForUpdates,
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: colorScheme.primary,
                iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
                title: 'About LifeQue',
                subtitle: 'Version info, developer & links',
                onTap: () => _showAboutSheet(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Legal section ───────────────────────────────────────
          _SectionHeader(label: 'Legal', color: colorScheme.primary),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.indigo.shade600,
                iconBgColor: Colors.indigo.withValues(alpha: 0.1),
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => _launchUrl(_privacyPolicyUrl),
                isExternal: true,
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: Colors.orange.shade700,
                iconBgColor: Colors.orange.withValues(alpha: 0.1),
                title: 'Terms & Conditions',
                subtitle: 'Usage terms of the app',
                onTap: () => _launchUrl(_termsUrl),
                isExternal: true,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ── Footer ──────────────────────────────────────────────
          Center(
            child: Text(
              'Made with ❤️ by Zaman Sheikh',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Reusable settings widgets
// ═════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    // The white fill lives on the Material, not on the Container: a
    // DecoratedBox between a ListTile and its nearest Material swallows the
    // tile's ink splash, which is what Flutter's assertion was reporting.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(children.length, (i) {
            return Column(
              children: [
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 60,
                    color: Colors.grey.shade100,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isExternal;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isExternal = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: Icon(
        isExternal ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _OrderTile extends StatelessWidget {
  final NavItem item;
  final bool isFirst;
  final ColorScheme colorScheme;

  const _OrderTile({
    super.key,
    required this.item,
    required this.isFirst,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    // The fill rides on the tile, not on a DecoratedBox around it: anything
    // opaque between a ListTile and its Material hides the tile's ink splash.
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: ListTile(
        tileColor: isFirst
            ? colorScheme.primary.withValues(alpha: 0.04)
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFirst
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.iconData,
            color: isFirst ? colorScheme.primary : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
            color: isFirst ? colorScheme.primary : Colors.grey.shade800,
          ),
        ),
        subtitle: isFirst
            ? Text(
                'Home page',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.drag_handle_rounded,
          color: Color(0xFFBBBBBB),
          size: 22,
        ),
      ),
    );
  }
}
