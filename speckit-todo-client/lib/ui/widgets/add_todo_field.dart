import 'dart:async';

import 'package:flutter/material.dart';

class AddTodoField extends StatefulWidget {
  const AddTodoField({
    super.key,
    required this.onSubmitted,
  });

  final Future<void> Function(String) onSubmitted;

  @override
  State<AddTodoField> createState() => _AddTodoFieldState();
}

class _AddTodoFieldState extends State<AddTodoField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    await widget.onSubmitted(value);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (value) {
        unawaited(_submit(value));
      },
      decoration: const InputDecoration(
        hintText: 'Add a todo and press enter',
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
