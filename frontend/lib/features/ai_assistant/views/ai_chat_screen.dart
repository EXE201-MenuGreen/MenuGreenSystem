import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/ai_assistant_models.dart';
import '../providers/ai_assistant_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, required this.conversation});

  final AiConversation conversation;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AiAssistantProvider>();
    if (provider.messages.isEmpty) {
      provider.loadMessages(widget.conversation.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await context.read<AiAssistantProvider>().sendMessage(
          widget.conversation.id,
          text,
        );
    if (mounted) _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 120), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiAssistantProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        title: Text(widget.conversation.title ?? 'Trợ lý AI'),
        actions: [
          IconButton(
            onPressed: () async {
              await provider.loadMessages(widget.conversation.id);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(provider),
          ),
          _buildInput(provider),
        ],
      ),
    );
  }

  Widget _buildMessageList(AiAssistantProvider provider) {
    if (provider.isLoadingMessages && provider.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.messages.isEmpty) {
      return const Center(
        child: Text(
          'Bắt đầu trò chuyện với trợ lý AI để nhận gợi ý dinh dưỡng.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        final isUser = message.role.toLowerCase() == 'user';
        return _MessageBubble(
          message: message,
          isUser: isUser,
          onFeedback: (isPositive) async {
            await provider.sendFeedback(
              widget.conversation.id,
              message.id,
              isPositive: isPositive,
            );
          },
          onRegenerate: () async {
            await provider.regenerateMessage(
              widget.conversation.id,
              message.id,
            );
            if (mounted) _scrollToBottom();
          },
        );
      },
    );
  }

  Widget _buildInput(AiAssistantProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi về dinh dưỡng...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (provider.isSending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.onFeedback,
    required this.onRegenerate,
  });

  final AiMessage message;
  final bool isUser;
  final ValueChanged<bool> onFeedback;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? AppColors.primary : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : AppColors.textDark;
    final time = _formatTime(message.createdAt);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: textColor, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: (isUser ? Colors.white : Colors.grey.shade600).withValues(alpha: 0.8),
              ),
            ),
            if (!isUser) _buildAssistantActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantActions(BuildContext context) {
    final isPositive = message.feedback == 'positive';
    final isNegative = message.feedback == 'negative';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => onFeedback(true),
          icon: Icon(
            Icons.thumb_up,
            size: 18,
            color: isPositive ? Colors.green : (Colors.grey.shade600),
          ),
          visualDensity: VisualDensity.compact,
          tooltip: 'Hữu ích',
        ),
        IconButton(
          onPressed: () => onFeedback(false),
          icon: Icon(
            Icons.thumb_down,
            size: 18,
            color: isNegative ? Colors.orange : (Colors.grey.shade600),
          ),
          visualDensity: VisualDensity.compact,
          tooltip: 'Chưa hữu ích',
        ),
        IconButton(
          onPressed: onRegenerate,
          icon: Icon(Icons.refresh, size: 18, color: Colors.grey.shade600),
          visualDensity: VisualDensity.compact,
          tooltip: 'Tạo lại câu trả lời',
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
