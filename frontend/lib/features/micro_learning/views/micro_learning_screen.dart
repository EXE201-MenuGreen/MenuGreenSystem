import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/micro_learning_models.dart';
import '../repositories/micro_learning_repository.dart';

class MicroLearningScreen extends StatefulWidget {
  const MicroLearningScreen({super.key});

  @override
  State<MicroLearningScreen> createState() => _MicroLearningScreenState();
}

class _MicroLearningScreenState extends State<MicroLearningScreen> {
  final _repository = MicroLearningRepository();
  List<MicroLearningCard> _cards = const [];
  List<MicroLearningCategory> _categories = const [];
  String? _category;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repository.getRecommended(),
        _repository.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _cards = results[0] as List<MicroLearningCard>;
        _categories = results[1] as List<MicroLearningCategory>;
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
        builder: (_) => MicroLearningDetailScreen(cardId: card.id),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _openSaved() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SavedMicroLearningScreen()),
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
        title: const Text('Góc dinh dưỡng'),
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
                  _ProgressPanel(
                    read: read,
                    quizzes: quizzes,
                    total: _cards.length,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chủ đề',
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
                  const SizedBox(height: 24),
                  Text(
                    _category == null ? 'Dành cho bạn' : 'Thẻ thuộc chủ đề',
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

class SavedMicroLearningScreen extends StatefulWidget {
  const SavedMicroLearningScreen({super.key});

  @override
  State<SavedMicroLearningScreen> createState() =>
      _SavedMicroLearningScreenState();
}

class _SavedMicroLearningScreenState extends State<SavedMicroLearningScreen> {
  final _repository = MicroLearningRepository();
  List<MicroLearningCard> _cards = const [];
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cards = await _repository.getSaved();
      if (mounted) setState(() => _cards = cards);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCard(MicroLearningCard card) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MicroLearningDetailScreen(cardId: card.id),
      ),
    );
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Kiến thức đã lưu')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _cards.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('Bạn chưa lưu thẻ kiến thức nào.')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _LearningCard(
                    card: _cards[index],
                    onTap: () => _openCard(_cards[index]),
                  ),
                ),
        ),
      ),
    );
  }
}

class MicroLearningDetailScreen extends StatefulWidget {
  const MicroLearningDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  State<MicroLearningDetailScreen> createState() =>
      _MicroLearningDetailScreenState();
}

class _MicroLearningDetailScreenState extends State<MicroLearningDetailScreen> {
  final _repository = MicroLearningRepository();
  MicroLearningCard? _card;
  int? _selectedOption;
  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;
  bool _changed = false;
  QuizSubmitResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final card = await _repository.getById(widget.cardId);
      if (!mounted) return;
      setState(() {
        _card = card;
        _selectedOption = card.selectedQuizOption;
        _loading = false;
      });
      if (!card.isRead) {
        await _repository.recordAction(card.id, 'read');
        if (mounted) setState(() => _card = card.copyWith(isRead: true));
        _changed = true;
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        _message(error.toString(), error: true);
      }
    }
  }

  Future<void> _toggleSaved() async {
    final card = _card;
    if (card == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _repository.recordAction(card.id, card.isSaved ? 'unsave' : 'save');
      if (mounted) {
        setState(() => _card = card.copyWith(isSaved: !card.isSaved));
      }
      _changed = true;
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _dismiss() async {
    final card = _card;
    if (card == null) return;
    try {
      await _repository.recordAction(card.id, 'dismiss');
      _changed = true;
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    }
  }

  Future<void> _submitQuiz() async {
    final card = _card;
    if (card == null || _selectedOption == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await _repository.submitQuiz(card.id, _selectedOption!);
      if (!mounted) return;
      setState(() {
        _result = result;
        _card = card.copyWith(
          isQuizCompleted: true,
          isQuizCorrect: result.isCorrect,
          selectedQuizOption: _selectedOption,
        );
      });
      _changed = true;
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
    final card = _card;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kiến thức dinh dưỡng'),
          actions: [
            IconButton(
              tooltip: card?.isSaved == true ? 'Bỏ lưu' : 'Lưu thẻ',
              onPressed: card == null || _saving ? null : _toggleSaved,
              icon: Icon(
                card?.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'dismiss') _dismiss();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'dismiss', child: Text('Ẩn thẻ này')),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : card == null
            ? const Center(child: Text('Không tìm thấy thẻ kiến thức.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryBadge(category: card.category),
                    const SizedBox(height: 14),
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.summary,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    if (card.tips.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Mẹo áp dụng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...card.tips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (card.hasQuiz) ...[
                      const SizedBox(height: 28),
                      _QuizPanel(
                        card: card,
                        selectedOption: _selectedOption,
                        result: _result,
                        submitting: _submitting,
                        onSelected: card.isQuizCompleted
                            ? null
                            : (value) =>
                                  setState(() => _selectedOption = value),
                        onSubmit:
                            card.isQuizCompleted || _selectedOption == null
                            ? null
                            : _submitQuiz,
                      ),
                    ],
                  ],
                ),
              ),
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
          Column(
            children: card.quizOptions
                .asMap()
                .entries
                .map(
                  (entry) => RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    value: entry.key,
                    groupValue: selectedOption,
                    onChanged: completed
                        ? null
                        : (value) => handleOptionChanged(value),
                    title: Text(entry.value),
                  ),
                )
                .toList(),
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
