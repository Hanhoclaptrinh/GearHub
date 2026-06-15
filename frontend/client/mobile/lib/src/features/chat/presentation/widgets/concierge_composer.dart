import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ConciergeComposer extends StatefulWidget {
  final bool disabled;
  final String? disabledText;
  final ValueChanged<String> onSend;
  final ValueChanged<bool> onTyping;

  const ConciergeComposer({
    super.key,
    required this.disabled,
    this.disabledText,
    required this.onSend,
    required this.onTyping,
  });

  @override
  State<ConciergeComposer> createState() => _ConciergeComposerState();
}

class _ConciergeComposerState extends State<ConciergeComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.disabled) return;
    widget.onSend(text);
    _controller.clear();
    widget.onTyping(false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.disabled && widget.disabledText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                widget.disabledText!,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant),
            ),
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.disabled,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    keyboardAppearance: Theme.of(context).brightness,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Trao đổi với GearHub...',
                      hintStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.32),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) =>
                        widget.onTyping(value.trim().isNotEmpty),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.disabled
                          ? cs.onSurface.withValues(alpha: 0.08)
                          : cs.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      LucideIcons.sendHorizontal,
                      color: widget.disabled
                          ? cs.onSurfaceVariant.withValues(alpha: 0.24)
                          : cs.onPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
