import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/expense_session.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/expense_session_card.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/budget_card.dart';

class ExpensesDashboardPage extends StatefulWidget {
  const ExpensesDashboardPage({super.key});

  @override
  State<ExpensesDashboardPage> createState() => _ExpensesDashboardPageState();
}

class _ExpensesDashboardPageState extends State<ExpensesDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadSessions());
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    final initialDate = _selectedMonth;
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      final month = DateTime(picked.year, picked.month);
      _onMonthChanged(month);
    }
  }

  void _addExpenseSession() {
    context.push('/expenses/add');
  }

  void _setBudget() {
    context.push('/expenses/budget', extra: _selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showMonthPicker,
            tooltip: 'Change Month',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search expense sessions...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Month Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    final prevMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                    _onMonthChanged(prevMonth);
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showMonthPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(
                        _formatMonthYear(_selectedMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final nextMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                    _onMonthChanged(nextMonth);
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Content
          Expanded(
            child: BlocConsumer<ExpenseBloc, ExpenseState>(
              listener: (context, state) {
                if (state is ExpenseError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is ExpenseOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ExpenseLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ExpenseLoaded) {
                  final sessions = state.isSearching
                      ? state.searchResults
                      : state.sessions;

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Monthly Summary Card
                      MonthlySummaryCard(
                        monthlyTotal: state.monthlyTotal,
                        monthlyPurchased: state.monthlyPurchased,
                        monthlyMissed: state.monthlyMissed,
                        selectedMonth: state.selectedMonth,
                      ),

                      const SizedBox(height: 16),

                      // Budget Card
                      BudgetCard(
                        budget: state.currentBudget,
                        actualSpent: state.monthlyPurchased,
                        onSetBudget: _setBudget,
                        selectedMonth: state.selectedMonth,
                      ),

                      const SizedBox(height: 16),

                      // Sessions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.isSearching
                                ? 'Search Results (${sessions.length})'
                                : 'Expense Sessions (${sessions.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!state.isSearching)
                            TextButton.icon(
                              onPressed: _addExpenseSession,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Session'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Sessions List
                      if (sessions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.isSearching
                                      ? 'No sessions found'
                                      : 'No expense sessions yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.isSearching
                                      ? 'Try adjusting your search query'
                                      : 'Add your first expense session to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...sessions.map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ExpenseSessionCard(
                              session: session,
                              onTap: () => _navigateToSessionDetail(session),
                              onEdit: () => _navigateToEditSession(session),
                              onDelete: () => _showDeleteConfirmation(session),
                              onToggleItem: (itemId) =>
                                  _toggleItemPurchased(session.id, itemId),
                            ),
                          ),
                        ),

                      const SizedBox(height: 80), // Space for FAB
                    ],
                  );
                } else {
                  return const Center(child: Text('Something went wrong'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpenseSession,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Session',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

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

  void _navigateToSessionDetail(ExpenseSession session) {
    context.push('/expenses/detail', extra: session);
  }

  void _navigateToEditSession(ExpenseSession session) {
    // For now, just show a message that edit is not implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality will be available soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _toggleItemPurchased(String sessionId, String itemId) {
    context.read<ExpenseBloc>().add(
      ToggleItemPurchasedEvent(sessionId, itemId),
    );
  }

  void _showDeleteConfirmation(ExpenseSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseBloc>().add(DeleteSessionEvent(session.id));
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
