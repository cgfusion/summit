import 'package:flutter/material.dart';

class RichTextToolbarWidget extends StatelessWidget {
  const RichTextToolbarWidget({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  void _wrapOrInsert(String openTag, String closeTag) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.start >= 0 && selection.end >= 0 && selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$openTag$selectedText$closeTag');
      controller.text = newText;
      controller.selection = TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + openTag.length + selectedText.length + closeTag.length,
      );
    } else {
      final insertPosition = selection.start >= 0 ? selection.start : text.length;
      final newText = text.replaceRange(insertPosition, insertPosition, '$openTag$closeTag');
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: insertPosition + openTag.length);
    }
  }

  void _insertLinePrefix(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    final insertPosition = selection.start >= 0 ? selection.start : text.length;
    final needNewline = insertPosition > 0 && !text.endsWith('\n');
    final toInsert = (needNewline ? '\n' : '') + prefix;
    final newText = text.replaceRange(insertPosition, insertPosition, toInsert);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: insertPosition + toInsert.length);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          // BOLD
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Tebal (Bold)',
            onPressed: () => _wrapOrInsert('<b>', '</b>'),
          ),
          // ITALIC
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Condong (Italic)',
            onPressed: () => _wrapOrInsert('<i>', '</i>'),
          ),
          // UNDERLINE
          _ToolbarButton(
            icon: Icons.format_underlined,
            tooltip: 'Garis Bawah (Underline)',
            onPressed: () => _wrapOrInsert('<u>', '</u>'),
          ),
          // HIGHLIGHT
          _ToolbarButton(
            icon: Icons.highlight,
            tooltip: 'Sorot (Highlight)',
            onPressed: () => _wrapOrInsert('<mark>', '</mark>'),
          ),
          const SizedBox(height: 20, child: VerticalDivider(width: 12)),
          // BULLET LIST
          _ToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Senarai Senarai (Bullet)',
            onPressed: () => _insertLinePrefix('• '),
          ),
          // NUMBERED LIST
          _ToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Senarai Nombor (Numbering)',
            onPressed: () => _insertLinePrefix('1. '),
          ),
          // HEADER
          _ToolbarButton(
            icon: Icons.title,
            tooltip: 'Tajuk Sub (Header)',
            onPressed: () => _insertLinePrefix('📢 '),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}
