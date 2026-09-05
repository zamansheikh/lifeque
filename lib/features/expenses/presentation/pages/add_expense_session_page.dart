import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/custom_category_service.dart';
import '../../domain/entities/custom_category.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/expense_session.dart';
import '../../domain/entities/expense_category.dart';
import '../bloc/expense_bloc.dart';
import '../../../../injection_container.dart' as di;

class AddExpenseSessionPage extends StatefulWidget {
  final ExpenseSession? session; // For editing existing session

  const AddExpenseSessionPage({super.key, this.session});

  @override
  State<AddExpenseSessionPage> createState() => _AddExpenseSessionPageState();
}

class _AddExpenseSessionPageState extends State<AddExpenseSessionPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final List<ExpenseItemForm> _items = [];

  // The quick-add row at the top of the item list: type a name, tab to the
  // price, hit enter, and the keyboard never goes away. Everything optional —
  // category, "already bought", even the price — lives behind a tap on the
  // finished row instead of standing between you and the next item.
  final _quickNameController = TextEditingController();
  final _quickAmountController = TextEditingController();
  final _quickNameFocus = FocusNode();
  final _quickAmountFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  int? _expandedIndex; // which item is currently expanded
  bool _showNote = false;
  bool get _isEditing => widget.session != null;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    if (_isEditing) {
      _titleController.text = widget.session!.title;
      _notesController.text = widget.session!.notes ?? '';
      _showNote = _notesController.text.isNotEmpty;
      _selectedDate = widget.session!.date;

      // Load existing items — all collapsed in edit mode
      for (final item in widget.session!.items) {
        final itemForm = ExpenseItemForm();
        itemForm.originalId = item.id; // preserve identity across edits
        itemForm.nameController.text = item.name;
        itemForm.amountController.text = item.amount.toString();
        itemForm.isPurchased = item.isPurchased;
        itemForm.category = item.category;
        itemForm.customCategoryName = item.customCategoryName;
        _items.add(itemForm);
      }
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _quickNameController.dispose();
    _quickAmountController.dispose();
    _quickNameFocus.dispose();
    _quickAmountFocus.dispose();
    _animationController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  /// Takes whatever is in the quick-add row and turns it into an item.
  ///
  /// Only the name is required — a price you don't know yet can be filled in
  /// later by tapping the row, which is the point: you can rattle off a whole
  /// list first and price it afterwards.
  void _quickAdd() {
    final name = _quickNameController.text.trim();
    if (name.isEmpty) {
      _quickNameFocus.requestFocus();
      return;
    }

    final form = ExpenseItemForm()
      ..nameController.text = name
      ..amountController.text = _quickAmountController.text.trim();

    // Category is optional, so guess it from the name rather than asking.
    // The picker on the row can always correct it.
    final guess = _suggestCategoriesForName(name);
    if (guess.isNotEmpty) form.category = guess.first;

    setState(() {
      _items.add(form);
      _expandedIndex = null;
      _quickNameController.clear();
      _quickAmountController.clear();
    });
    _quickNameFocus.requestFocus();
  }

  void _confirmItem(int index) {
    setState(() => _expandedIndex = null);
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF2563EB),
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSession() {
    // Typing a name and hitting Save without pressing + is an easy mistake to
    // make, and losing that item would be a rotten reward for it.
    if (_quickNameController.text.trim().isNotEmpty) _quickAdd();

    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      // ID strategy:
      //   • Existing items (loaded with originalId) keep their original id
      //     so external references (analytics, dose history, etc.) stay valid
      //     even after deleting/reordering items in the form.
      //   • New items get a unique id from the timestamp + a counter, so two
      //     items added in the same millisecond don't collide.
      final nowMs = DateTime.now().millisecondsSinceEpoch.toString();
      int newCounter = 0;
      final items = <ExpenseItem>[];
      for (final itemForm in _items) {
        items.add(
          ExpenseItem(
            id: itemForm.originalId ?? '${nowMs}_${newCounter++}',
            name: itemForm.nameController.text.trim(),
            amount: double.tryParse(itemForm.amountController.text) ?? 0,
            isPurchased: itemForm.isPurchased,
            purchasedAt: itemForm.isPurchased ? DateTime.now() : null,
            category: itemForm.category,
            customCategoryName: itemForm.customCategoryName,
          ),
        );
      }

      final session = ExpenseSession(
        id: _isEditing
            ? widget.session!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        date: _selectedDate,
        items: items,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _isEditing ? widget.session!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        context.read<ExpenseBloc>().add(UpdateSessionEvent(session));
      } else {
        context.read<ExpenseBloc>().add(AddSessionEvent(session));
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'List updated' : 'List saved'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      context.pop();
    } else if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add at least one item before saving'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit list' : 'New shopping list',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF64748B),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: _saveSession,
              icon: Icon(
                _isEditing ? Icons.update_rounded : Icons.save_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                _isEditing ? 'Update' : 'Save',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _listCard(),
                const SizedBox(height: 12),
                _itemsCard(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── The list itself ────────────────────────────────────────────────────
  // Name and date only. The note is the one optional field here, so it stays
  // folded away behind a chip until somebody actually wants it.
  Widget _listCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnhancedTextField(
              controller: _titleController,
              label: 'List name',
              hint: 'e.g. Weekly bazar, Grocery run',
              icon: Icons.title_rounded,
              autofocus: !_isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Give this list a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip(
                  icon: Icons.calendar_today_rounded,
                  label: _formatDate(_selectedDate),
                  onTap: _selectDate,
                ),
                const SizedBox(width: 8),
                if (!_showNote)
                  _chip(
                    icon: Icons.add_rounded,
                    label: 'Note',
                    onTap: () => setState(() => _showNote = true),
                    subdued: true,
                  ),
              ],
            ),
            if (_showNote) ...[
              const SizedBox(height: 10),
              _buildEnhancedTextField(
                controller: _notesController,
                label: 'Note (optional)',
                hint: 'Anything worth remembering',
                icon: Icons.notes_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool subdued = false,
  }) {
    final color = subdued ? const Color(0xFF64748B) : const Color(0xFF2563EB);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Items ──────────────────────────────────────────────────────────────
  Widget _itemsCard() {
    final total = _calculateTotal();
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (_items.isNotEmpty)
                  Text(
                    '${_items.length} · ৳${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _quickAddRow(),
            if (_items.isEmpty) ...[
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Type a name, add a price if you know it, press +',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              const SizedBox(height: 10),
              ...List.generate(_items.length, (index) {
                final isExpanded = _expandedIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: isExpanded
                      ? _buildExpandedItemForm(index)
                      : _buildCollapsedItemRow(index),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Name → price → enter. The row clears itself and hands focus back to the
  /// name field, so a whole basket goes in without ever leaving the keyboard.
  Widget _quickAddRow() {
    final ready = _quickNameController.text.trim().isNotEmpty;
    return _entryRow(
      highlight: true,
      name: TextField(
        controller: _quickNameController,
        focusNode: _quickNameFocus,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _quickAmountFocus.requestFocus(),
        onChanged: (_) => setState(() {}),
        style: _entryNameStyle,
        decoration: _entryDecoration('Add an item'),
      ),
      price: TextField(
        controller: _quickAmountController,
        focusNode: _quickAmountFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.end,
        onSubmitted: (_) => _quickAdd(),
        style: _entryPriceStyle,
        decoration: _entryDecoration('0'),
      ),
      trailing: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _quickAdd,
          child: Container(
            width: _actionHeight,
            height: _actionHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ready
                    ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                    : [const Color(0xFFCBD5E1), const Color(0xFFCBD5E1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        autofocus: autofocus,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ── Collapsed compact row ────────────────────────────────────────────────
  /// Icon, colour and label for an item's *effective* category. A custom
  /// category carries its own three, so the collapsed row can't just read the
  /// enum — it used to, and every custom category showed up as "Other".
  ({IconData icon, Color color, String name}) _categoryLook(
    ExpenseItemForm item,
  ) {
    final customName = item.customCategoryName;
    if (customName == null) {
      return (
        icon: item.category.icon,
        color: item.category.color,
        name: item.category.displayName,
      );
    }
    final custom = di.sl<CustomCategoryService>().findByName(customName);
    return (
      icon: custom?.icon ?? Icons.label_rounded,
      color: custom?.color ?? const Color(0xFF7C3AED),
      name: customName,
    );
  }

  Widget _buildCollapsedItemRow(int index) {
    final item = _items[index];
    final look = _categoryLook(item);
    final hasName = item.nameController.text.trim().isNotEmpty;
    final amount = double.tryParse(item.amountController.text);

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isPurchased
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon bubble
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: look.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(look.icon, color: look.color, size: 17),
            ),
            const SizedBox(width: 10),

            // Name + category label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasName ? item.nameController.text.trim() : 'Untitled item',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasName
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                      decoration: item.isPurchased
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    look.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: look.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              amount != null ? '৳${amount.toStringAsFixed(0)}' : '৳—',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: amount != null
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 8),

            // Purchased check
            if (item.isPurchased)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),

            // Expand arrow
            const Icon(
              Icons.expand_more_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Expanded item form with category suggestions ─────────────────────────
  Widget _buildExpandedItemForm(int index) {
    final item = _items[index];
    // Anything already showing in the Category row below would be a chip that
    // repeats the control right under it, so drop it from the suggestions.
    final suggested = _suggestCategoriesForName(item.nameController.text)
        .where((c) => item.customCategoryName != null || c != item.category)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header. Both buttons are _actionHeight tall so they line up —
          // an icon button and a text button left to their own devices come
          // out different heights.
          Row(
            children: [
              const Text(
                'Editing item',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              _headerAction(
                icon: Icons.delete_rounded,
                color: const Color(0xFFDC2626),
                tooltip: 'Remove item',
                onTap: () => _removeItem(index),
              ),
              const SizedBox(width: 8),
              _headerAction(
                icon: Icons.check_rounded,
                color: const Color(0xFF059669),
                label: 'Done',
                onTap: () => _confirmItem(index),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Same row, same divider, same ৳ as the add row above it.
          _entryRow(
            name: TextFormField(
              controller: item.nameController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              style: _entryNameStyle,
              decoration: _entryDecoration('Item name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                return null;
              },
            ),
            price: TextFormField(
              controller: item.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.end,
              onChanged: (_) => setState(() {}),
              style: _entryPriceStyle,
              decoration: _entryDecoration('0'),
              // Blank is allowed and saves as ৳0: pricing the basket later is
              // the whole point of adding items this fast.
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                if (double.tryParse(value) == null) return 'Invalid';
                return null;
              },
            ),
          ),

          // ── Category suggestions ──
          if (suggested.isNotEmpty &&
              item.nameController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggested.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final cat = suggested[i];
                  final isSelected =
                      item.category == cat && item.customCategoryName == null;
                  return GestureDetector(
                    onTap: () => setState(() {
                      item.category = cat;
                      item.customCategoryName = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: 0.14)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? cat.color
                              : cat.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 13, color: cat.color),
                          const SizedBox(width: 5),
                          Text(
                            cat.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: cat.color,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 10),
          _buildCategoryPicker(item),
          const SizedBox(height: 8),

          // Already bought
          GestureDetector(
            onTap: () => setState(() => item.isPurchased = !item.isPurchased),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: item.isPurchased
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.isPurchased
                      ? const Color(0xFF10B981).withValues(alpha: 0.45)
                      : Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.isPurchased
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.isPurchased
                            ? const Color(0xFF10B981)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: item.isPurchased
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Already bought',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.isPurchased
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header buttons for the expanded item: one fixed height, so a bare icon
  /// and an icon-plus-label end up the same size as each other.
  static const double _actionHeight = 36;

  Widget _headerAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
    String? tooltip,
  }) {
    final button = Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: _actionHeight,
          constraints: BoxConstraints(minWidth: _actionHeight),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  // ── One shared name-and-price row ──────────────────────────────────────
  // The quick-add row and the expanded item both use this, so they read as
  // the same control: name on the left, a hairline divider, then ৳ and the
  // price. Without the divider the two values ran together.
  static const _entryNameStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B),
  );

  static const _entryPriceStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1E293B),
  );

  InputDecoration _entryDecoration(String hint) => InputDecoration(
    isDense: true,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
  );

  Widget _entryRow({
    required Widget name,
    required Widget price,
    Widget? trailing,
    bool highlight = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, trailing == null ? 12 : 5, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: name),
          const SizedBox(width: 10),
          Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 10),
          Text(
            '৳',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          SizedBox(width: 58, child: price),
          if (trailing != null) ...[const SizedBox(width: 5), trailing],
        ],
      ),
    );
  }

  /// Builds a tappable category picker that opens a bottom sheet
  /// with built-in categories + custom categories + create new option.
  Widget _buildCategoryPicker(ExpenseItemForm item) {
    final customCats = di.sl<CustomCategoryService>().getAll();
    final isCustom = item.customCategoryName != null;
    final displayColor = isCustom
        ? (customCats
                  .where((c) => c.name == item.customCategoryName)
                  .firstOrNull
                  ?.color ??
              const Color(0xFF7C3AED))
        : item.category.color;
    final displayIcon = isCustom
        ? (customCats
                  .where((c) => c.name == item.customCategoryName)
                  .firstOrNull
                  ?.icon ??
              Icons.label_rounded)
        : item.category.icon;
    final displayName = item.effectiveDisplayName;

    return GestureDetector(
      onTap: () => _showCategoryPickerSheet(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(displayIcon, color: displayColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: displayColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPickerSheet(ExpenseItemForm item) {
    final customCats = di.sl<CustomCategoryService>().getAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCreateCustomCategoryDialog(item);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'New',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: [
                  // Built-in categories
                  ...ExpenseCategory.values.map((cat) {
                    final isSelected =
                        item.category == cat && item.customCategoryName == null;
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 18),
                      ),
                      title: Text(
                        cat.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? cat.color
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: cat.color,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          item.category = cat;
                          item.customCategoryName = null;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }),

                  // Custom categories
                  if (customCats.isNotEmpty) ...[
                    const Divider(height: 1),
                    ...customCats.map((cc) {
                      final isSelected = item.customCategoryName == cc.name;
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cc.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cc.icon, color: cc.color, size: 18),
                        ),
                        title: Text(
                          cc.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? cc.color
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: cc.color,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            item.category = ExpenseCategory.other;
                            item.customCategoryName = cc.name;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCustomCategoryDialog(ExpenseItemForm item) {
    final nameCtrl = TextEditingController();
    int selectedIconIndex = 0;
    int selectedColorIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final icon = CustomCategory.availableIcons[selectedIconIndex];
          final color = CustomCategory.availableColors[selectedColorIndex];

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Create Custom Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Name
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Rent, Gym, Pet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Icons
                  const Text(
                    'Icon',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      CustomCategory.availableIcons.length,
                      (i) => GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedIconIndex = i),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selectedIconIndex == i
                                ? color.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: selectedIconIndex == i
                                ? Border.all(color: color, width: 2)
                                : null,
                          ),
                          child: Icon(
                            CustomCategory.availableIcons[i],
                            size: 18,
                            color: selectedIconIndex == i
                                ? color
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Colors
                  const Text(
                    'Color',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      CustomCategory.availableColors.length,
                      (i) => GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedColorIndex = i),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: CustomCategory.availableColors[i],
                            shape: BoxShape.circle,
                            border: selectedColorIndex == i
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: selectedColorIndex == i
                                ? [
                                    BoxShadow(
                                      color: CustomCategory.availableColors[i]
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: selectedColorIndex == i
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final custom = CustomCategory(
                    name: name,
                    iconIndex: selectedIconIndex,
                    // toARGB32 is the documented replacement for the
                    // deprecated Color.value, and round-trips exactly through
                    // the Color(colorValue) that reads it back.
                    colorValue: CustomCategory
                        .availableColors[selectedColorIndex]
                        .toARGB32(),
                  );
                  final added = await di.sl<CustomCategoryService>().add(
                    custom,
                  );
                  if (!added && ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Category name already exists'),
                      ),
                    );
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {
                    item.category = ExpenseCategory.other;
                    item.customCategoryName = name;
                  });
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Returns up to 3 suggested categories based on the item name keywords.
  List<ExpenseCategory> _suggestCategoriesForName(String name) {
    final lower = name.toLowerCase();
    if (lower.isEmpty) return [];
    final scores = <ExpenseCategory, int>{};

    void score(ExpenseCategory cat, List<String> keywords) {
      for (final kw in keywords) {
        if (lower.contains(kw)) scores[cat] = (scores[cat] ?? 0) + 1;
      }
    }

    score(ExpenseCategory.groceries, [
      'rice',
      'bread',
      'flour',
      'oil',
      'milk',
      'egg',
      'fish',
      'meat',
      'chicken',
      'vegetable',
      'salt',
      'sugar',
      'lentil',
      'dal',
      'potato',
      'onion',
      'garlic',
      'ginger',
      'spice',
      'maida',
      'atta',
      'mustard',
    ]);
    score(ExpenseCategory.food, [
      'restaurant',
      'food',
      'dinner',
      'lunch',
      'breakfast',
      'coffee',
      'tea',
      'snack',
      'burger',
      'pizza',
      'biryani',
      'cake',
      'juice',
      'ice cream',
    ]);
    score(ExpenseCategory.transport, [
      'bus',
      'rickshaw',
      'cng',
      'taxi',
      'uber',
      'fare',
      'fuel',
      'petrol',
      'train',
      'auto',
      'travel',
      'ferry',
      'bike',
    ]);
    score(ExpenseCategory.utilities, [
      'electricity',
      'water',
      'gas',
      'internet',
      'wifi',
      'phone',
      'mobile',
      'bill',
      'recharge',
      'sim',
      'data',
    ]);
    score(ExpenseCategory.entertainment, [
      'movie',
      'game',
      'book',
      'ticket',
      'concert',
      'netflix',
      'youtube',
      'cinema',
      'subscription',
      'club',
      'show',
    ]);
    score(ExpenseCategory.healthcare, [
      'medicine',
      'doctor',
      'clinic',
      'hospital',
      'health',
      'pharmacy',
      'drug',
      'capsule',
      'tablet',
      'syrup',
      'test',
      'checkup',
    ]);
    score(ExpenseCategory.education, [
      'tuition',
      'school',
      'college',
      'university',
      'course',
      'pen',
      'notebook',
      'pencil',
      'fees',
      'class',
      'stationary',
    ]);
    score(ExpenseCategory.shopping, [
      'shirt',
      'pants',
      'shoes',
      'dress',
      'clothes',
      'clothing',
      'fashion',
      'bag',
      'watch',
      'accessories',
    ]);
    score(ExpenseCategory.bills, [
      'rent',
      'emi',
      'loan',
      'mortgage',
      'insurance',
      'tax',
    ]);

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.where((e) => e.value > 0).take(3).map((e) => e.key).toList();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) {
      final amount = double.tryParse(item.amountController.text) ?? 0.0;
      return sum + amount;
    });
  }
}

class ExpenseItemForm {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool isPurchased = false;
  ExpenseCategory category = ExpenseCategory.other;
  String? customCategoryName;
  // Original id from the loaded session, kept so editing → saving doesn't
  // re-assign ids by list-position (which scrambles them on delete/reorder).
  // Null for newly-added items — those get a freshly-minted id on save.
  String? originalId;

  /// Display name for the effective category.
  String get effectiveDisplayName {
    if (customCategoryName != null) return customCategoryName!;
    return category.displayName;
  }

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}
