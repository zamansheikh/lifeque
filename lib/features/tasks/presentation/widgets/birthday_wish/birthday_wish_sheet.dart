import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/task.dart';
import 'birthday_wish_card.dart';
import 'birthday_wish_log.dart';
import 'wish_messages.dart';

/// Compose and send a birthday card: swipe between looks, pick a tone or
/// write your own words, add your name, share the picture.
class BirthdayWishSheet {
  static Future<void> show(BuildContext context, Task birthday) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WishSheet(birthday: birthday),
    );
  }
}

class _WishSheet extends StatefulWidget {
  final Task birthday;
  const _WishSheet({required this.birthday});

  @override
  State<_WishSheet> createState() => _WishSheetState();
}

class _WishSheetState extends State<_WishSheet> {
  static const _pink = Color(0xFFDB2777);
  static const _ink = Color(0xFF1E293B);

  final _pages = PageController(viewportFraction: 0.78);
  final _keys = {for (final s in WishCardStyle.values) s: GlobalKey()};
  final _message = TextEditingController();
  final _from = TextEditingController();

  var _style = WishCardStyle.values.first;
  WishTone? _tone = WishTone.warm;
  var _showAge = true;
  var _busy = false;
  var _seeded = false;

  String get _name => widget.birthday.title.trim();

  /// The age they turn on the coming birthday, or null when only a day and
  /// month were recorded.
  int? get _age {
    final born = widget.birthday.endDate;
    final next = widget.birthday.nextOccurrence;
    if (born.year >= DateTime.now().year) return null;
    final age = next.year - born.year;
    return age > 0 ? age : null;
  }

  @override
  void initState() {
    super.initState();
    _from.text = BirthdayWishLog.instance.from;
    _message.addListener(() => setState(() {}));
    _from.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The first message needs localisations, which are not there in initState.
    if (!_seeded) {
      _seeded = true;
      _message.text = _tone!.message(L.of(context), _name);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _message.dispose();
    _from.dispose();
    super.dispose();
  }

  void _pickTone(WishTone tone) {
    setState(() {
      _tone = tone;
      _message.text = tone.message(L.of(context), _name);
    });
  }

  Future<void> _share() async {
    final l = L.of(context);
    final caption = _message.text.trim().isEmpty
        ? l.wishCaption(_name)
        : _message.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final boundary =
          _keys[_style]!.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('encode');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/birthday-wish-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: caption),
      );
      await BirthdayWishLog.instance.rememberFrom(_from.text);
      await BirthdayWishLog.instance.markWished(widget.birthday.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l = L.of(context);
    await Clipboard.setData(ClipboardData(text: _message.text.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.wishCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final media = MediaQuery.of(context);
    final cardWidth = (media.size.width * 0.78) - 16;
    final wished = BirthdayWishLog.instance.wishedThisYear(widget.birthday.id);

    return Container(
      height: media.size.height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.wishSheetTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (wished)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.wishWishedThisYear,
                                style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 16 + media.viewInsets.bottom),
              children: [
                // ── Card carousel ──
                SizedBox(
                  height: cardWidth + 16,
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: WishCardStyle.values.length,
                    onPageChanged: (i) =>
                        setState(() => _style = WishCardStyle.values[i]),
                    itemBuilder: (context, i) {
                      final style = WishCardStyle.values[i];
                      return Center(
                        child: Container(
                          width: cardWidth,
                          height: cardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: cardWidth,
                              height: cardWidth,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: RepaintBoundary(
                                  key: _keys[style],
                                  child: BirthdayWishCard(
                                    style: style,
                                    name: _name,
                                    age: _showAge ? _age : null,
                                    message: _message.text,
                                    from: _from.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // ── Style pills ──
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (final s in WishCardStyle.values) ...[
                        _pill(
                          s.label(l),
                          selected: s == _style,
                          onTap: () => _pages.animateToPage(
                            s.index,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // ── Tone + message ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l.wishMessageLabel,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (final t in WishTone.values) ...[
                        _pill(
                          t.label(l),
                          selected: t == _tone,
                          onTap: () => _pickTone(t),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _message,
                    minLines: 2,
                    maxLines: 5,
                    onChanged: (_) => setState(() => _tone = null),
                    style: const TextStyle(fontSize: 14, height: 1.45),
                    decoration: _field(l.wishMessageHint),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _from,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 14),
                    decoration: _field(
                      l.wishFromLabel,
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                ),
                if (_age != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                    child: SwitchListTile.adaptive(
                      value: _showAge,
                      onChanged: (v) => setState(() => _showAge = v),
                      activeThumbColor: _pink,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      title: Text(
                        l.wishShowAge,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // ── Actions ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _share,
                          style: FilledButton.styleFrom(
                            backgroundColor: _pink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.ios_share_rounded, size: 18),
                          label: Text(
                            l.wishShareCard,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _copy,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _pink,
                            side: const BorderSide(color: _pink),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(
                            l.wishCopyText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!wished)
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        await BirthdayWishLog.instance.markWished(
                          widget.birthday.id,
                        );
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(l.wishMarkWished),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
    prefixIcon: icon == null ? null : Icon(icon, size: 20, color: _pink),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _pink, width: 1.5),
    ),
  );

  Widget _pill(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _pink : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _pink : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
