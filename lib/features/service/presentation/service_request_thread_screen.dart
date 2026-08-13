import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../models/enums.dart';
import '../../../models/service_message.dart';
import '../../../models/service_request.dart';
import '../data/service_providers.dart';

class ServiceRequestThreadScreen extends ConsumerStatefulWidget {
  const ServiceRequestThreadScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ServiceRequestThreadScreen> createState() => _ServiceRequestThreadScreenState();
}

class _ServiceRequestThreadScreenState extends ConsumerState<ServiceRequestThreadScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ref.read(serviceRepositoryProvider).sendMessage(widget.requestId, text);
      _messageController.clear();
      ref.invalidate(serviceMessagesProvider(widget.requestId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(serviceRequestDetailProvider(widget.requestId));
    final messagesAsync = ref.watch(serviceMessagesProvider(widget.requestId));
    final customerId = ref.watch(authControllerProvider).valueOrNull?.customer?.id;

    return Scaffold(
      appBar: AppBar(
        title: AsyncValueWidget<ServiceRequest>(
          value: requestAsync,
          data: (r) => Text(r.type),
          loading: const Text('Service request'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueWidget<List<ServiceMessage>>(
              value: messagesAsync,
              onRetry: () => ref.invalidate(serviceMessagesProvider(widget.requestId)),
              data: (messages) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final isMe = m.senderType == MessageSenderType.customer &&
                      m.senderId == customerId;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.yamahaBlue : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.message,
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM, h:mm a').format(m.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(hintText: 'Type a message…'),
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
