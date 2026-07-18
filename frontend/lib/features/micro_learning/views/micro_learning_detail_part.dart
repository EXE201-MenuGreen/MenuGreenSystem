part of 'micro_learning_screen.dart';

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


