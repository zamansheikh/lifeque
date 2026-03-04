import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo_bloc.dart';
import '../widgets/todo_card.dart';
import '../widgets/add_todo_fab.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TextEditingController _searchController = TextEditingController();
  TodoCategory? _selectedCategory;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Completed',
    'Due Today',
    'Overdue',
  ];

  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(LoadTodos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<TodoBloc>().add(SearchTodosEvent(query));
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    final bloc = context.read<TodoBloc>();
    switch (filter) {
      case 'All':
        bloc.add(ClearFilters());
        break;
      case 'Pending':
        bloc.add(GetPendingTodosEvent());
        break;
      case 'Completed':
        bloc.add(GetCompletedTodosEvent());
        break;
      case 'Due Today':
        bloc.add(GetTodosDueTodayEvent());
        break;
      case 'Overdue':
        bloc.add(GetOverdueTodosEvent());
        break;
    }
  }

  void _onCategorySelected(TodoCategory? category) {
    setState(() {
      _selectedCategory = category;
    });

    if (category != null) {
      context.read<TodoBloc>().add(FilterTodosByCategory(category));
    } else {
      context.read<TodoBloc>().add(ClearFilters());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: '/todos'),
      appBar: AppBar(
        title: const Text(
          'My To-Dos',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
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
                  color: Colors.grey.withValues(alpha: 0.1),
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
                hintText: 'Search todos...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._filterOptions.map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (_) => _onFilterSelected(filter),
                      backgroundColor: Colors.white,
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                      side: BorderSide(
                        color: _selectedFilter == filter
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Category Filter with Clear Option
                Row(
                  children: [
                    PopupMenuButton<TodoCategory?>(
                      itemBuilder: (context) => [
                        PopupMenuItem<TodoCategory?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.clear, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              const Text('All Categories'),
                            ],
                          ),
                        ),
                        ...TodoCategory.values.map(
                          (category) => PopupMenuItem<TodoCategory?>(
                            value: category,
                            child: Row(
                              children: [
                                Icon(category.icon, color: category.color),
                                const SizedBox(width: 8),
                                Text(category.displayName),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onSelected: _onCategorySelected,
                      child: Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedCategory?.icon ??
                                  Icons.category_outlined,
                              size: 16,
                              color:
                                  _selectedCategory?.color ?? Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCategory?.displayName ??
                                  'All Categories',
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                        backgroundColor: _selectedCategory != null
                            ? _selectedCategory!.color.withValues(alpha: 0.2)
                            : Colors.white,
                        side: BorderSide(
                          color:
                              _selectedCategory?.color ??
                              Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Clear Filter Button (only show when category is selected)
                    if (_selectedCategory != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _onCategorySelected(null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Todo List
          Expanded(
            child: BlocConsumer<TodoBloc, TodoState>(
              listener: (context, state) {
                if (state is TodoError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is TodoOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Reload todos after successful operation
                  context.read<TodoBloc>().add(LoadTodos());
                }
              },
              builder: (context, state) {
                if (state is TodoLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TodoLoaded) {
                  final todos = state.isFiltered
                      ? state.filteredTodos
                      : state.todos;

                  if (todos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.isFiltered
                                ? 'No todos found'
                                : 'No todos yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.isFiltered
                                ? 'Try adjusting your filters'
                                : 'Add your first todo to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      return TodoCard(
                        todo: todos[index],
                        onTap: () => _navigateToTodoDetail(todos[index]),
                        onToggleComplete: (todo) {
                          if (todo.isCompleted) {
                            context.read<TodoBloc>().add(
                              UncompleteTodoEvent(todo.id),
                            );
                          } else {
                            context.read<TodoBloc>().add(
                              CompleteTodoEvent(todo.id),
                            );
                          }
                        },
                        onDelete: (todo) => _showDeleteConfirmation(todo),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('Something went wrong'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AddTodoFab(onPressed: () => _navigateToAddTodo()),
    );
  }

  void _navigateToTodoDetail(Todo todo) {
    context.push('/todos/detail', extra: todo);
  }

  void _navigateToAddTodo() {
    context.push('/todos/add');
  }

  void _showDeleteConfirmation(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TodoBloc>().add(DeleteTodoEvent(todo.id));
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

class TodoSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      context.read<TodoBloc>().add(SearchTodosEvent(query));
    }

    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodoLoaded && state.isFiltered) {
          final todos = state.filteredTodos;

          if (todos.isEmpty) {
            return const Center(child: Text('No todos found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              return TodoCard(
                todo: todos[index],
                onTap: () {
                  close(context, todos[index].title);
                  context.push('/todos/detail', extra: todos[index]);
                },
                onToggleComplete: (todo) {
                  if (todo.isCompleted) {
                    context.read<TodoBloc>().add(UncompleteTodoEvent(todo.id));
                  } else {
                    context.read<TodoBloc>().add(CompleteTodoEvent(todo.id));
                  }
                },
                onDelete: (todo) {
                  context.read<TodoBloc>().add(DeleteTodoEvent(todo.id));
                },
              );
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Enter a search term to find todos'));
  }
}
