import 'package:flutter/material.dart';

import '../../models/todo.dart';

class TodoListTile extends StatefulWidget {
  const TodoListTile({
    super.key,
    required this.todo,
    required this.reorderIndex,
    required this.onRename,
    required this.onDelete,
  });

  final Todo todo;
  final int reorderIndex;
  final Future<void> Function(String nextTitle) onRename;
  final VoidCallback onDelete;

  @override
  State<TodoListTile> createState() => _TodoListTileState();
}

class _TodoListTileState extends State<TodoListTile> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.todo.title);
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;
  bool _saving = false;

  @override
  void didUpdateWidget(TodoListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.todo.title != oldWidget.todo.title) {
      _controller.text = widget.todo.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _beginEditing() {
    setState(() {
      _editing = true;
      _controller.text = widget.todo.title;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _saving = false;
      _controller.text = widget.todo.title;
    });
  }

  Future<void> _submitEditing() async {
    final next = _controller.text.trim();
    if (next.isEmpty || next == widget.todo.title) {
      _cancelEditing();
      return;
    }
    setState(() {
      _saving = true;
    });
    await widget.onRename(next);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trailing = <Widget>[
      if (_editing)
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel edit',
          onPressed: _saving ? null : _cancelEditing,
        )
      else
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit task',
          onPressed: _beginEditing,
        ),
      if (_editing)
        IconButton(
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          tooltip: 'Save changes',
          onPressed: _saving ? null : _submitEditing,
        )
      else
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete task',
          onPressed: widget.onDelete,
        ),
      ReorderableDragStartListener(
        index: widget.reorderIndex,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.drag_indicator),
        ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: _editing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: 140,
                autofocus: true,
                onSubmitted: (_) => _submitEditing(),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              )
            : Text(widget.todo.title),
        trailing: Wrap(
          spacing: 4,
          children: trailing,
        ),
      ),
    );
  }
}
