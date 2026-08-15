part of 'micro_learning_screen.dart';

class _MoodSelectionGrid extends StatelessWidget {
  const _MoodSelectionGrid({
    required this.moods,
    required this.selectedMood,
    required this.onSelectMood,
  });

  final List<FoodMoodItem> moods;
  final FoodMoodItem selectedMood;
  final ValueChanged<FoodMoodItem> onSelectMood;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods.map((mood) {
          final isSelected = mood.id == selectedMood.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelectMood(mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      mood.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MoodRescueSection extends StatelessWidget {
  const _MoodRescueSection({
    required this.mood,
    required this.submitting,
    required this.onAppliedFood,
  });

  final FoodMoodItem mood;
  final bool submitting;
  final ValueChanged<RescueFood> onAppliedFood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      mood.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scientific Insight Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mood.scientificInsight,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.amber.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Món ăn giải cứu gợi ý:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ...mood.rescueFoods.map(
            (food) => _RescueFoodTile(
              food: food,
              submitting: submitting,
              onAppliedFood: onAppliedFood,
            ),
          ),
        ],
      ),
    );
  }
}

class _RescueFoodTile extends StatelessWidget {
  const _RescueFoodTile({
    required this.food,
    required this.submitting,
    required this.onAppliedFood,
  });

  final RescueFood food;
  final bool submitting;
  final ValueChanged<RescueFood> onAppliedFood;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${food.estimatedPriceVnd.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            food.description,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${food.caloriesKcal.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                'P: ${food.proteinG}g  C: ${food.carbsG}g  F: ${food.fatG}g',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: submitting ? null : () => onAppliedFood(food),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (submitting)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.add_to_photos_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      submitting ? 'Đang thêm...' : 'Thêm vào kế hoạch',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
