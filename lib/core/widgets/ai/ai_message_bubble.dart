import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/chat_message.dart';
import '../../../models/enums.dart';
import '../../config/theme.dart';

/// Chat bubble with entrance motion and role-aware styling.
class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.message,
    this.animate = true,
  });

  final ChatMessage message;
  final bool animate;

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    final bubble = Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: _isUser ? 'You said' : 'Assistant said',
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          child: Column(
            crossAxisAlignment:
                _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!_isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.yamahaBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: AppColors.yamahaBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RideMate',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.inkFaint,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _isUser ? AppColors.yamahaBlue : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(_isUser ? 18 : 6),
                    bottomRight: Radius.circular(_isUser ? 6 : 18),
                  ),
                  border: _isUser ? null : Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: _isUser ? 0.1 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      color: _isUser ? Colors.white : AppColors.ink,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  DateFormat.jm().format(message.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!animate) {
      return Padding(padding: const EdgeInsets.only(bottom: 14), child: bubble);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: child,
            ),
          );
        },
        child: bubble,
      ),
    );
  }
}
