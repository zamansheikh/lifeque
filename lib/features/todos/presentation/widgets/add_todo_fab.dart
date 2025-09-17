import 'package:flutter/material.dart';

class AddTodoFab extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddTodoFab({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add),
      label: const Text(
        'Add Todo',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
