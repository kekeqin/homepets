import 'package:flutter/material.dart';

Future<String?> showAddMemberDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const AddMemberDialog(),
  );
}

class AddMemberDialog extends StatefulWidget {
  const AddMemberDialog({super.key});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF8EED8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '添加成员',
        style: TextStyle(
          color: Color(0xFF5A3A21),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: TextField(
        controller: _controller,
        maxLength: 20,
        autofocus: true,
        onChanged: (_) {
          if (_validationMessage != null) {
            setState(() => _validationMessage = null);
          }
        },
        decoration: InputDecoration(
          labelText: '成员昵称',
          hintText: '例如：小宝',
          errorText: _validationMessage,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF7A5733).withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF7A5733).withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFF7A5733), width: 1.3),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7A5733),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final nickname = _controller.text.trim();
            if (nickname.isEmpty) {
              setState(() {
                _validationMessage = '成员昵称不能为空';
              });
              return;
            }
            Navigator.of(context).pop(nickname);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}
