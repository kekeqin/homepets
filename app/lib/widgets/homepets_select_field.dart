import 'package:flutter/material.dart';

class HomePetsSelectOption<T> {
  const HomePetsSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

class HomePetsSelectField<T> extends StatelessWidget {
  const HomePetsSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = '请选择',
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<HomePetsSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String placeholder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = options.any((option) => option.value == value)
        ? value
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B4A31),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9B7953), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E5E3A20),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: effectiveValue,
              isExpanded: true,
              borderRadius: BorderRadius.circular(18),
              dropdownColor: const Color(0xFFFFF4E7),
              icon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF7A5839),
                  size: 26,
                ),
              ),
              hint: Text(
                placeholder,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0x9A7A5839),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              selectedItemBuilder: (context) => options
                  .map(
                    (option) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4D3623),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              style: const TextStyle(
                color: Color(0xFF4D3623),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
              padding: const EdgeInsets.only(left: 16),
              menuMaxHeight: 260,
              items: options
                  .map(
                    (option) => DropdownMenuItem<T>(
                      value: option.value,
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
