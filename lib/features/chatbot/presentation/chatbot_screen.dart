import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/design.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/chat_message.dart';
import '../../../models/enums.dart';
import '../data/chatbot_providers.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _isSending = true);
    // Optimistically invalidate right away so the user's own message shows
    // up immediately, then again once the assistant reply lands.
    ref.invalidate(chatHistoryProvider);
    try {
      await ref.read(chatbotRepositoryProvider).sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      ref.invalidate(chatHistoryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(chatHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('RideMate — Car & Bike GPT')),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueWidget<List<ChatMessage>>(
              value: historyAsync,
              onRetry: () => ref.invalidate(chatHistoryProvider),
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.two_wheeler,
                    title: 'Ask RideMate anything',
                    subtitle:
                        'Service due dates, maintenance tips, riding advice, model comparisons — '
                        'anything car or bike, I can help.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isUser = m.role == ChatRole.user;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints:
                            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.yamahaBlue : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(Ds.rMd),
                        ),
                        child: Text(
                          m.content,
                          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Assistant is typing…', style: TextStyle(fontSize: 12, color: Ds.inkMuted)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask about cars & bikes…'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
