part of 'micro_learning_screen.dart';

class SavedMicroLearningScreen extends StatefulWidget {
  const SavedMicroLearningScreen({super.key, required this.allowQuiz});

  final bool allowQuiz;

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
        builder: (_) => MicroLearningDetailScreen(
          cardId: card.id,
          allowQuiz: widget.allowQuiz,
        ),
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
