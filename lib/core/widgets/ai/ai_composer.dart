import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Bottom composer for AI chat surfaces — large tap targets, clear focus ring.
class AiComposer extends StatelessWidget {
  const AiComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.hintText = 'Ask about cars & bikes…',
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final String hintText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    textField: true,
                    label: 'Message RideMate',
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: enabled ? (_) => onSend() : null,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(
                          color: AppColors.inkFaint,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: AppColors.canvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.yamahaBlue,
                            width: 1.5,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  enabled: enabled,
                  label: 'Send message',
                  child: AnimatedOpacity(
                    opacity: enabled ? 1 : 0.45,
                    duration: const Duration(milliseconds: 160),
                    child: Material(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: enabled ? onSend : null,
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
