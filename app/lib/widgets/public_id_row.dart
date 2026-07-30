import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Read-only public user ID row with one-tap copy.
class PublicIdRow extends StatelessWidget {
  const PublicIdRow({
    super.key,
    required this.publicId,
    this.onCopied,
    this.labelColor = const Color(0xFF7C634C),
    this.valueColor = const Color(0xFF5C3E29),
  });

  final String publicId;
  final VoidCallback? onCopied;
  final Color labelColor;
  final Color valueColor;

  Future<void> _copy() async {
    if (publicId.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: publicId));
    onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: publicId.isEmpty ? null : _copy,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '专属 ID',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  publicId.isEmpty ? '暂未生成' : publicId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor.withValues(
                      alpha: publicId.isEmpty ? 0.55 : 1,
                    ),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: publicId.isEmpty ? 0 : 1.2,
                  ),
                ),
              ),
              if (publicId.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, size: 18, color: labelColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
