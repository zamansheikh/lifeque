import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _svc = NavigationPreferencesService(di.sl<SharedPreferences>());
    _items = _svc.getOrderedItems();
  }

  Future<void> _save() async {
    await _svc.saveOrder(_items);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showAboutSheet(BuildContext ctx) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
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
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Nav Order ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Navigation Order',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag to reorder. The first item becomes your home page.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Info chip showing current home
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
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
                      'Home page:  ${_items.first.label}',
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                    _saved = false;
                  });
                },
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
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

          const SizedBox(height: 32),

          // ── Other options ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Other',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_lesson_rounded,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
              ),
              title: const Text(
                'View Onboarding Again',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'See the app introduction slides',
                style: TextStyle(fontSize: 13),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/onboarding');
              },
            ),
          ),

          const SizedBox(height: 8),

          // About tile
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'About LifeQue',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Version info, developer & links',
                style: TextStyle(fontSize: 13),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
              onTap: () => _showAboutSheet(context),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: isFirst
            ? colorScheme.primary.withValues(alpha: 0.04)
            : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: ListTile(
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
