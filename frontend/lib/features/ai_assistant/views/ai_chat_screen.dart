import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/ai_assistant_models.dart';
import '../providers/ai_assistant_provider.dart';
import '../../discover/repositories/food_discovery_repository.dart';
import '../../discover/models/food_models.dart';
import '../../meal_plan/providers/meal_plan_provider.dart';
import '../../meal_plan/models/meal_plan_requests.dart';

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

  List<FoodItem> _availableFoods = [];

  @override
  void initState() {
    super.initState();
    // Load messages in a post-frame callback to avoid triggering synchronous builds during layout phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AiAssistantProvider>().loadMessages(widget.conversation.id);
        _loadAvailableFoods();
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadAvailableFoods() async {
    try {
      final foods = await FoodDiscoveryRepository().searchFoods();
      if (mounted) {
        setState(() {
          _availableFoods = foods;
        });
      }
    } catch (_) {}
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
    // Filter messages for current conversation to avoid brief flash of old messages
    final currentMessages = provider.messages.where((m) => m.conversationId == widget.conversation.id).toList();

    if (provider.isLoadingMessages && currentMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (currentMessages.isEmpty) {
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
      itemCount: currentMessages.length,
      itemBuilder: (context, index) {
        final message = currentMessages[index];
        final isUser = message.role.toLowerCase() == 'user';
        return _MessageBubble(
          message: message,
          isUser: isUser,
          availableFoods: _availableFoods,
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
    this.availableFoods = const [],
  });

  final AiMessage message;
  final bool isUser;
  final ValueChanged<bool> onFeedback;
  final VoidCallback onRegenerate;
  final List<FoodItem> availableFoods;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? AppColors.primary : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : AppColors.textDark;
    final time = _formatTime(message.createdAt);

    final matchedFoods = <FoodItem>[];
    if (!isUser && availableFoods.isNotEmpty) {
      final contentLower = message.content.toLowerCase();
      for (final food in availableFoods) {
        if (food.nameVi.trim().isNotEmpty &&
            contentLower.contains(food.nameVi.toLowerCase().trim())) {
          matchedFoods.add(food);
        }
      }
    }

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
            if (matchedFoods.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 6),
              const Text(
                'Món ăn gợi ý phát hiện được:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: matchedFoods.map((food) {
                  return ActionChip(
                    avatar: const Icon(Icons.add, size: 14, color: Colors.white),
                    backgroundColor: AppColors.primary,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    label: Text('${food.nameVi} (${food.caloriesKcal?.round() ?? 0} kcal)'),
                    onPressed: () => _showAddMealPlanDialog(context, food),
                  );
                }).toList(),
              ),
            ],
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

  void _showAddMealPlanDialog(BuildContext context, FoodItem food) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Thêm "${food.nameVi}" vào bữa ăn nào?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Text(MealType.breakfast.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(MealType.breakfast.labelVi),
                onTap: () => _addFoodToMealPlan(context, sheetContext, food, MealType.breakfast.value),
              ),
              ListTile(
                leading: Text(MealType.lunch.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(MealType.lunch.labelVi),
                onTap: () => _addFoodToMealPlan(context, sheetContext, food, MealType.lunch.value),
              ),
              ListTile(
                leading: Text(MealType.dinner.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(MealType.dinner.labelVi),
                onTap: () => _addFoodToMealPlan(context, sheetContext, food, MealType.dinner.value),
              ),
              ListTile(
                leading: Text(MealType.snack.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(MealType.snack.labelVi),
                onTap: () => _addFoodToMealPlan(context, sheetContext, food, MealType.snack.value),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addFoodToMealPlan(
    BuildContext context,
    BuildContext sheetContext,
    FoodItem food,
    String mealType,
  ) async {
    Navigator.pop(sheetContext); // Close bottom sheet
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang thêm ${food.nameVi} vào thực đơn...')),
    );

    try {
      final mealPlanProvider = context.read<MealPlanProvider>();
      final request = AddItemRequest(
        mealType: mealType,
        foodId: food.id,
        recipeId: null,
        targetCalories: food.caloriesKcal?.round() ?? 0,
      );
      
      final result = await mealPlanProvider.addRecommendationToTodayPlan(request);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text('Đã thêm ${food.nameVi} vào thực đơn thành công!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Có lỗi xảy ra khi thêm món ăn vào thực đơn.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Lỗi: ${e.toString()}'),
          ),
        );
      }
    }
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
