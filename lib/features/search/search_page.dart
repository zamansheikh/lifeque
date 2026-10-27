import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'search_index.dart';

/// One box that finds anything in the app.
class SearchPage extends StatefulWidget {
  /// For tests: what to search instead of reading the stores.
  final Future<List<SearchHit>> Function(L l)? index;
  const SearchPage({super.key, this.index});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  List<SearchHit>? _all;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    (widget.index ?? buildSearchIndex)(L.of(context)).then((all) {
      if (mounted) setState(() => _all = all);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _section(L l, SearchKind k) => switch (k) {
    SearchKind.page => l.searchPages,
    SearchKind.task => l.navTasks,
    SearchKind.birthday => l.navBirthdays,
    SearchKind.habit => l.navHabits,
    SearchKind.expense => l.navExpenses,
    SearchKind.subscription => l.navSubscriptions,
    SearchKind.debt => l.navDebts,
    SearchKind.medicine => l.navMedicines,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final q = _query.text;
    final all = _all;
    final hits = all == null ? const <SearchHit>[] : searchHits(all, q);

    final children = <Widget>[];
    SearchKind? last;
    for (final h in hits.take(200)) {
      if (h.kind != last) {
        last = h.kind;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(
              _section(l, h.kind),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        );
      }
      children.add(
        ListTile(
          leading: CircleAvatar(
            backgroundColor: h.color.withValues(alpha: 0.12),
            child: Icon(h.icon, color: h.color, size: 20),
          ),
          title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: h.subtitle == null
              ? null
              : Text(h.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            FocusScope.of(context).unfocus();
            context.push(h.route, extra: h.extra);
          },
        ),
      );
    }

    Widget message(IconData icon, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 0),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: TextField(
          key: const Key('search-field'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (q.isNotEmpty)
            IconButton(
              tooltip: l.commonCancel,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(_query.clear),
            ),
        ],
      ),
      body: all == null
          ? const LinearProgressIndicator(minHeight: 2)
          : q.trim().isEmpty
          ? ListView(children: [message(Icons.search_rounded, l.searchStart)])
          : hits.isEmpty
          ? ListView(
              children: [
                message(Icons.search_off_rounded, l.searchNothing(q.trim())),
              ],
            )
          : ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 24),
              children: children,
            ),
    );
  }
}
