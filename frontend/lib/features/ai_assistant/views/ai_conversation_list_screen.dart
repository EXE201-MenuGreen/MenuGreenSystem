import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/ai_assistant_models.dart';
import '../providers/ai_assistant_provider.dart';
import 'ai_chat_screen.dart';

class AiConversationListScreen extends StatefulWidget {
  const AiConversationListScreen({super.key});

  @override
  State<AiConversationListScreen> createState() => _AiConversationListScreenState();
}

class _AiConversationListScreenState extends State<AiConversationListScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<AiAssistantProvider>();
    if (provider.conversations.isEmpty && !provider.isLoadingConversations) {
      provider.loadConversations();
    }
  }

  Future<void> _createConversation() async {
    final provider = context.read<AiAssistantProvider>();
    final conversation = await provider.createConversation(null);
    if (conversation != null && mounted) {
      _openChat(conversation);
    }
  }

  void _openChat(AiConversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiChatScreen(conversation: conversation),
      ),
    );
  }

  Future<void> _deleteConversation(AiConversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa đoạn hội thoại?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AiAssistantProvider>().deleteConversation(conversation.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Consumer<AiAssistantProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingConversations && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.conversations.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: provider.loadConversations,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = provider.conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  onTap: () => _openChat(conversation),
                  onDelete: () => _deleteConversation(conversation),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createConversation,
        icon: const Icon(Icons.add_comment),
        label: const Text('Cuộc hội thoại mới'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Chưa có cuộc hội thoại nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu trò chuyện với trợ lý dinh dưỡng để nhận gợi ý cá nhân hóa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final AiConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = conversation.title?.trim().isNotEmpty == true
        ? conversation.title!
        : 'Cuộc hội thoại mới';
    final date = _formatDate(conversation.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(date),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Xóa',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hôm nay';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
