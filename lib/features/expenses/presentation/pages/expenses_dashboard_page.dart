import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_session.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/expense_session_card.dart';
import '../widgets/unified_budget_card.dart';

/// The expense tracker home.
///
/// A "session" in the data layer is, to the user, simply a **shopping list**:
/// a named batch of things to buy, ticked off as they are bought. Everything
/// on screen uses that plain wording — the entity keeps its old name so stored
/// data stays readable.
class ExpensesDashboardPage extends StatefulWidget {
  const ExpensesDashboardPage({super.key});

  @override
  State<ExpensesDashboardPage> createState() => _ExpensesDashboardPageState();
}

class _ExpensesDashboardPageState extends State<ExpensesDashboardPage>
    with TickerProviderStateMixin {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _brand = Color(0xFF2563EB);
  static const _brandLight = Color(0xFF3B82F6);

  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadSessions());

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<ExpenseBloc>().add(ClearSearch());
    } else {
      context.read<ExpenseBloc>().add(SearchSessionsEvent(query));
    }
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
    });
    context.read<ExpenseBloc>().add(ChangeSelectedMonth(newMonth));
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pick a month',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _onMonthChanged(DateTime(picked.year, picked.month));
    }
  }

  void _addShoppingList() {
    context.push('/expenses/add');
  }

  void _setBudget() {
    final state = context.read<ExpenseBloc>().state;
    final existingBudget = state is ExpenseLoaded ? state.currentBudget : null;
    final existingCategoryBudgets = state is ExpenseLoaded
        ? state.categoryBudgets
        : <CategoryBudget>[];
    final categorySpending = state is ExpenseLoaded
        ? state.getCategorySpending()
        : <String, double>{};
    context.push(
      '/expenses/budget',
      extra: {
        'selectedMonth': _selectedMonth,
        'existingBudget': existingBudget,
        'existingCategoryBudgets': existingCategoryBudgets,
        'categorySpending': categorySpending,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: '/expenses'),
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: _ink,
          ),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: _muted),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: BlocConsumer<ExpenseBloc, ExpenseState>(
          listener: (context, state) {
            if (state is ExpenseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          builder: (context, state) {
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              children: [
                _monthStrip(),
                const SizedBox(height: 16),
                ..._content(state),
              ],
            );
          },
        ),
      ),
      // Only one way to add a list is ever on screen: the empty state owns the
      // call to action when there is nothing yet, the button takes over once
      // there is a list to sit beside.
      floatingActionButton: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          final show =
              state is ExpenseLoaded &&
              (state.sessions.isNotEmpty || state.isSearching);
          if (!show) return const SizedBox.shrink();
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_brandLight, _brand]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _brand.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _addShoppingList,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text(
                'New list',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Month strip ────────────────────────────────────────────────────────
  // The month name is the button. There is no separate calendar action in the
  // app bar and no "tap to change" caption: the chevron next to the name says
  // it opens a picker, the arrows step one month at a time.
  Widget _monthStrip() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _monthArrow(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous month',
            onTap: () => _onMonthChanged(
              DateTime(_selectedMonth.year, _selectedMonth.month - 1),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showMonthPicker,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _formatMonthYear(_selectedMonth),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: _muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _monthArrow(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next month',
            onTap: () => _onMonthChanged(
              DateTime(_selectedMonth.year, _selectedMonth.month + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthArrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 24),
        style: IconButton.styleFrom(foregroundColor: const Color(0xFF475569)),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────
  List<Widget> _content(ExpenseState state) {
    if (state is ExpenseLoaded) return _loaded(state);
    if (state is ExpenseError) return [_errorCard(state.message)];
    return [
      const SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _brand),
              SizedBox(height: 16),
              Text(
                'Loading your expenses…',
                style: TextStyle(
                  color: _muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _loaded(ExpenseLoaded state) {
    final lists = state.isSearching ? state.searchResults : state.sessions;
    final hasAnyList = state.sessions.isNotEmpty;

    return [
      UnifiedBudgetCard(
        budget: state.currentBudget,
        actualSpent: state.monthlyPurchased,
        monthlyTotal: state.monthlyTotal,
        monthlyMissed: state.monthlyMissed,
        categoryBudgets: state.categoryBudgets,
        categorySpending: Map<String, double>.from(state.getCategorySpending()),
        onSetBudget: _setBudget,
        selectedMonth: state.selectedMonth,
        onDeleteCategory: (id) {
          context.read<ExpenseBloc>().add(DeleteCategoryBudgetEvent(id));
        },
      ),
      const SizedBox(height: 16),

      // Searching an empty month is pointless, so the field only appears once
      // there is something to search — or while a search is already running.
      if (hasAnyList || state.isSearching) ...[
        _searchField(),
        const SizedBox(height: 16),
      ],

      _listsHeader(state, lists),

      // The search use-case doesn't restrict to the selected month, so results
      // can come from any month. Without this note the budget card above would
      // show one month's totals while the list below silently mixed in others.
      if (state.isSearching && lists.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _notice(
            'Showing matches from every month — the summary above still '
            'covers ${_formatMonthYear(state.selectedMonth)} only.',
          ),
        ),

      const SizedBox(height: 16),

      if (lists.isEmpty)
        state.isSearching ? _noResultsCard() : _emptyCard()
      else
        ...lists.map(
          (session) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExpenseSessionCard(
              session: session,
              onTap: () => _openList(session),
              onEdit: () => _editList(session),
              onDelete: () => _confirmDelete(session),
              onToggleItem: (itemId) => _toggleItem(session.id, itemId),
            ),
          ),
        ),

      // Room for the floating button so it never covers the last row.
      const SizedBox(height: 88),
    ];
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search lists and items…',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search_rounded, color: _brand, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _listsHeader(ExpenseLoaded state, List<ExpenseSession> lists) {
    // The budget card above already reports the month's spend, so the
    // subtitle counts things instead of repeating a figure.
    final items = lists.fold<int>(0, (sum, s) => sum + s.items.length);
    final countLabel =
        '${lists.length} ${lists.length == 1 ? 'list' : 'lists'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.isSearching ? 'Search results' : 'Shopping lists',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        // With nothing to count, the card below already says so.
        if (lists.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '$countLabel · $items ${items == 1 ? 'item' : 'items'}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _notice(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _emptyCard() {
    return _card(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.shopping_basket_rounded,
            size: 34,
            color: _brand,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Start your first list',
          style: TextStyle(
            fontSize: 18,
            color: _ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Write down what you plan to buy with a price for each item, '
          'then tick things off as you shop. Whatever you skip is counted '
          'as money saved.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_brandLight, _brand]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: _addShoppingList,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a list'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _noResultsCard() {
    return _card(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.search_off_rounded,
            size: 34,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nothing matched',
          style: TextStyle(
            fontSize: 18,
            color: _ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try a shorter word — list names and item names are both searched.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.45),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.red[600], fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<ExpenseBloc>().add(LoadSessions()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────
  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _openList(ExpenseSession session) {
    context.push('/expenses/detail', extra: session);
  }

  void _editList(ExpenseSession session) {
    context.push('/expenses/edit', extra: session);
  }

  void _toggleItem(String sessionId, String itemId) {
    context.read<ExpenseBloc>().add(
      ToggleItemPurchasedEvent(sessionId, itemId),
    );
  }

  void _confirmDelete(ExpenseSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this list?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '“${session.title}” and its ${session.items.length} '
          '${session.items.length == 1 ? 'item' : 'items'} will be removed '
          'from your records. This can\'t be undone.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ExpenseBloc>().add(DeleteSessionEvent(session.id));
              Navigator.of(dialogContext).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
