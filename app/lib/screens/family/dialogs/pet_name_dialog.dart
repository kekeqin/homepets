import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';

Future<String?> showPetNameDialog(
  BuildContext context, {
  required String memberNickname,
  required String petType,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        PetNameDialog(memberNickname: memberNickname, petType: petType),
  );
}

class PetNameDialog extends StatefulWidget {
  const PetNameDialog({
    super.key,
    required this.memberNickname,
    required this.petType,
  });

  final String memberNickname;
  final String petType;

  @override
  State<PetNameDialog> createState() => _PetNameDialogState();
}

class _PetNameDialogState extends State<PetNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: petTypeLabel(widget.petType));
  }

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
        '给宠物起名',
        style: TextStyle(
          color: Color(0xFF5A3A21),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '现在为 ${widget.memberNickname} 的${petTypeLabel(widget.petType)}取一个名字吧。',
            style: const TextStyle(
              color: Color(0xFF6C4C33),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: InputDecoration(
              labelText: '宠物名字',
              hintText: '例如：团团',
              errorText: _errorText,
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
        ],
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
            final name = _controller.text.trim();
            if (name.isEmpty) {
              setState(() => _errorText = '宠物名字不能为空');
              return;
            }
            Navigator.of(context).pop(name);
          },
          child: const Text('完成命名'),
        ),
      ],
    );
  }
}
