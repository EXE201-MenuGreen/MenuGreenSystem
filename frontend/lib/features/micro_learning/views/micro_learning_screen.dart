import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../models/micro_learning_models.dart';
import '../repositories/micro_learning_repository.dart';
import '../../subscription/models/subscription_models.dart';
import '../../subscription/repositories/user_subscription_repository.dart';

part 'micro_learning_saved_part.dart';
part 'micro_learning_detail_part.dart';
part 'micro_learning_widgets_part.dart';

class MicroLearningScreen extends StatefulWidget {
  const MicroLearningScreen({super.key});

  @override
  State<MicroLearningScreen> createState() => _MicroLearningScreenState();
}

class _MicroLearningScreenState extends State<MicroLearningScreen> {
  final _repository = MicroLearningRepository();
  final _subscriptionRepository = UserSubscriptionRepository();
  FeatureAccess _access = FeatureAccess.free;
  List<MicroLearningCard> _cards = const [];
  List<MicroLearningCategory> _categories = const [];
  late List<FoodMoodItem> _moods;
  late FoodMoodItem _selectedMood;
  String? _category;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _moods = FoodMoodItem.defaultMoods();
    _selectedMood = _moods.first;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final access = await _subscriptionRepository.getFeatureAccess();
      final results = await Future.wait([
        access.hasCasual
            ? _repository.getRecommended()
            : _repository.getLibrary(),
        _repository.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _cards = results[0] as List<MicroLearningCard>;
        _categories = results[1] as List<MicroLearningCategory>;
        _access = access;
      });
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MicroLearningCard> get _visibleCards => _category == null
      ? _cards
      : _cards
            .where(
              (card) => card.category.toLowerCase() == _category!.toLowerCase(),
            )
            .toList();

  Future<void> _openCard(MicroLearningCard card) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MicroLearningDetailScreen(
          cardId: card.id,
          allowQuiz: _access.hasCasual,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _openSaved() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SavedMicroLearningScreen(allowQuiz: _access.hasCasual),
      ),
    );
    if (changed == true) await _load();
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value.replaceFirst('Exception: ', '')),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final read = _cards.where((card) => card.isRead).length;
    final quizzes = _cards.where((card) => card.isQuizCompleted).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Góc Cảm Xúc & Thèm Ăn'),
        actions: [
          IconButton(
            tooltip: 'Đã lưu',
            onPressed: _openSaved,
            icon: const Icon(Icons.bookmark_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_access.hasCasual) ...[
                  // Mood Selector Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          Colors.green.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🎭', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              'Hôm nay bạn cảm thấy thế nào?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Chọn trạng thái cảm xúc hoặc cơn thèm để MenuGreen gợi ý món ăn giải cứu phù hợp nhất!',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        _MoodSelectionGrid(
                          moods: _moods,
                          selectedMood: _selectedMood,
                          onSelectMood: (mood) {
                            setState(() {
                              _selectedMood = mood;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Selected Mood Insight & Rescue Foods
                  _MoodRescueSection(
                    mood: _selectedMood,
                    onAppliedFood: (food) async {
                      await showMealLogSheet(
                        context,
                        initialFoodName: food.name,
                        caloriesKcal: food.caloriesKcal,
                        proteinG: food.proteinG,
                        carbsG: food.carbsG,
                        fatG: food.fatG,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  _ProgressPanel(
                    read: read,
                    quizzes: quizzes,
                    total: _cards.length,
                  ),
                  const SizedBox(height: 20),
                  ],
                  const Text(
                    'Chủ đề dinh dưỡng',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'Tất cả',
                          selected: _category == null,
                          onSelected: () => setState(() => _category = null),
                        ),
                        ..._categories.map(
                          (item) => _CategoryChip(
                            label: item.displayName.isEmpty
                                ? item.name
                                : item.displayName,
                            selected: _category == item.name,
                            onSelected: () =>
                                setState(() => _category = item.name),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _category == null
                        ? (_access.hasCasual
                              ? 'Dành cho bạn'
                              : 'Thư viện chung')
                        : 'Thẻ thuộc chủ đề',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_visibleCards.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Chưa có thẻ phù hợp trong danh sách đề xuất.',
                        ),
                      ),
                    )
                  else
                    ..._visibleCards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LearningCard(
                          card: card,
                          onTap: () => _openCard(card),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
