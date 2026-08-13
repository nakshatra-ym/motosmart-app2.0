import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../models/enums.dart';
import '../../../models/service_message.dart';
import '../../../models/service_request.dart';
import '../data/tickets_providers.dart';

class TicketThreadScreen extends ConsumerStatefulWidget {
  const TicketThreadScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends ConsumerState<TicketThreadScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _isUpdatingStatus = false;

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
      await ref.read(ticketsRepositoryProvider).sendMessage(widget.ticketId, text);
      _messageController.clear();
      invalidateTicketsData(ref, ticketId: widget.ticketId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _updateStatus(ServiceRequestStatus status) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await ref.read(ticketsRepositoryProvider).updateStatus(widget.ticketId, status);
      invalidateTicketsData(ref, ticketId: widget.ticketId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: AsyncValueWidget<ServiceRequest>(
          value: ticketAsync,
          // Who and which bike, not just the issue type — the dealer is replying
          // to a person.
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.type, style: const TextStyle(fontSize: 17)),
              if (r.customerName != null || r.vehicleLabel != null)
                Text(
                  [r.customerName, r.vehicleLabel]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          loading: const Text('Ticket'),
        ),
      ),
      body: Column(
        children: [
          ticketAsync.maybeWhen(
            data: (ticket) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<ServiceRequestStatus>(
                    value: ticket.status,
                    underline: const SizedBox.shrink(),
                    onChanged: _isUpdatingStatus
                        ? null
                        : (status) {
                            if (status != null) _updateStatus(status);
                          },
                    items: ServiceRequestStatus.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          Expanded(
            child: AsyncValueWidget<List<ServiceMessage>>(
              value: messagesAsync,
              onRetry: () => ref.invalidate(ticketMessagesProvider(widget.ticketId)),
              data: (messages) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final isMe = m.senderType == MessageSenderType.dealer;
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
                      decoration: const InputDecoration(hintText: 'Reply to customer…'),
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
