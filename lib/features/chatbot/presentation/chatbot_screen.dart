import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/ai/ai_composer.dart';
import '../../../core/widgets/ai/ai_message_bubble.dart';
import '../../../core/widgets/ai/ai_suggestion_chips.dart';
import '../../../core/widgets/ai/ai_typing_indicator.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../models/chat_message.dart';
import '../data/chatbot_providers.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  static const _suggestions = [
    'When is my next service due?',
    'Tips for rainy-season riding',
    'Compare scooter vs motorcycle',
    'What does a high coolant temp mean?',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    setState(() => _isSending = true);
    // Optimistically invalidate so the user's message shows immediately,
    // then again once the assistant reply lands.
    ref.invalidate(chatHistoryProvider);
    _scrollToBottom();
    try {
      await ref.read(chatbotRepositoryProvider).sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      ref.invalidate(chatHistoryProvider);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(chatHistoryProvider);

    ref.listen<AsyncValue<List<ChatMessage>>>(chatHistoryProvider, (prev, next) {
      next.whenData((messages) {
        if (messages.length != _lastMessageCount) {
          _lastMessageCount = messages.length;
          _scrollToBottom();
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RideMate',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Car & bike assistant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueWidget<List<ChatMessage>>(
              value: historyAsync,
              onRetry: () => ref.invalidate(chatHistoryProvider),
              data: (messages) {
                if (messages.isEmpty && !_isSending) {
                  return _EmptyChat(
                    suggestions: _suggestions,
                    onSuggestion: (prompt) => _send(prompt),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  itemCount: messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const AiTypingIndicator();
                    }
                    return AiMessageBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),
          AiComposer(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !_isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({
    required this.suggestions,
    required this.onSuggestion,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.yamahaBlue.withValues(alpha: 0.12),
                      AppColors.yamahaBlue.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.yamahaBlue.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 32,
                  color: AppColors.yamahaBlue,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Ask RideMate anything',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      letterSpacing: -0.4,
                      color: const Color(0xFF141414),
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Service schedules, maintenance tips, riding advice, '
                'and model comparisons — all in one place.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withValues(alpha: 0.5),
                      height: 1.5,
                      fontSize: 14.5,
                    ),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Try asking',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.black.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              AiSuggestionChips(
                suggestions: suggestions,
                onSelected: onSuggestion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
