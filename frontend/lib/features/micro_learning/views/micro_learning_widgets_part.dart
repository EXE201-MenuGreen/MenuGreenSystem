part of 'micro_learning_screen.dart';

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.read,
    required this.quizzes,
    required this.total,
  });

  final int read;
  final int quizzes;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : read / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ hôm nay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, color: AppColors.primary),
          const SizedBox(height: 10),
          Text('Đã đọc $read/$total thẻ · Hoàn thành $quizzes quiz'),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    ),
  );
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.card, required this.onTap});

  final MicroLearningCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(_categoryIcon(card.category), color: AppColors.primary),
      ),
      title: Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(card.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (card.isSaved)
            const Icon(Icons.bookmark, color: AppColors.primary, size: 18),
          if (card.isQuizCompleted)
            Icon(
              card.isQuizCorrect == true
                  ? Icons.check_circle
                  : Icons.quiz_outlined,
              size: 18,
            ),
        ],
      ),
    ),
  );
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(_categoryIcon(category), size: 18, color: AppColors.primary),
    label: Text(_categoryLabel(category)),
  );
}

class _QuizPanel extends StatelessWidget {
  const _QuizPanel({
    required this.card,
    required this.selectedOption,
    required this.result,
    required this.submitting,
    required this.onSelected,
    required this.onSubmit,
  });

  final MicroLearningCard card;
  final int? selectedOption;
  final QuizSubmitResult? result;
  final bool submitting;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final completed = card.isQuizCompleted;
    final feedback = result?.feedback;
    void handleOptionChanged(int? value) {
      if (!completed && value != null) {
        onSelected?.call(value);
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kiểm tra nhanh',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(card.quizQuestion!),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: selectedOption,
            onChanged: handleOptionChanged,
            child: Column(
              children: card.quizOptions
                  .asMap()
                  .entries
                  .map(
                    (entry) => RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      value: entry.key,
                      enabled: !completed,
                      title: Text(entry.value),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (completed || feedback != null) ...[
            const SizedBox(height: 8),
            Text(
              feedback ??
                  (card.isQuizCorrect == true
                      ? 'Bạn đã hoàn thành quiz.'
                      : 'Bạn đã hoàn thành quiz.'),
              style: TextStyle(
                color: card.isQuizCorrect == true
                    ? AppColors.primary
                    : Colors.orange.shade800,
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting ? null : onSubmit,
                child: Text(submitting ? 'Đang gửi...' : 'Trả lời'),
              ),
            ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String value) {
  switch (value.toLowerCase()) {
    case 'protein':
      return Icons.fitness_center;
    case 'sodium':
      return Icons.water_drop_outlined;
    case 'allergy':
      return Icons.health_and_safety_outlined;
    case 'hydration':
      return Icons.local_drink_outlined;
    default:
      return Icons.menu_book_outlined;
  }
}

String _categoryLabel(String value) {
  switch (value.toLowerCase()) {
    case 'protein':
      return 'Chất đạm';
    case 'sodium':
      return 'Muối & Natri';
    case 'allergy':
      return 'Dị ứng';
    case 'hydration':
      return 'Nước & khoáng';
    default:
      return 'Dinh dưỡng cơ bản';
  }
}


