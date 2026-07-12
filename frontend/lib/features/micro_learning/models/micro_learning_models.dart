class MicroLearningCard {
  const MicroLearningCard({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    this.tips = const [],
    this.imageUrl,
    this.quizQuestion,
    this.quizOptions = const [],
    this.pointsReward = 0,
    this.isSaved = false,
    this.isRead = false,
    this.isQuizCompleted = false,
    this.isQuizCorrect,
    this.selectedQuizOption,
  });

  final String id;
  final String title;
  final String summary;
  final String category;
  final List<String> tips;
  final String? imageUrl;
  final String? quizQuestion;
  final List<String> quizOptions;
  final int pointsReward;
  final bool isSaved;
  final bool isRead;
  final bool isQuizCompleted;
  final bool? isQuizCorrect;
  final int? selectedQuizOption;

  bool get hasQuiz =>
      quizQuestion != null && quizQuestion!.trim().isNotEmpty && quizOptions.isNotEmpty;

  MicroLearningCard copyWith({
    bool? isSaved,
    bool? isRead,
    bool? isQuizCompleted,
    bool? isQuizCorrect,
    int? selectedQuizOption,
  }) {
    return MicroLearningCard(
      id: id,
      title: title,
      summary: summary,
      category: category,
      tips: tips,
      imageUrl: imageUrl,
      quizQuestion: quizQuestion,
      quizOptions: quizOptions,
      pointsReward: pointsReward,
      isSaved: isSaved ?? this.isSaved,
      isRead: isRead ?? this.isRead,
      isQuizCompleted: isQuizCompleted ?? this.isQuizCompleted,
      isQuizCorrect: isQuizCorrect ?? this.isQuizCorrect,
      selectedQuizOption: selectedQuizOption ?? this.selectedQuizOption,
    );
  }

  factory MicroLearningCard.fromJson(Map<String, dynamic> json) {
    String text(String key) => (json[key] ?? json[_pascal(key)] ?? '').toString();
    int number(String key) =>
        (json[key] ?? json[_pascal(key)]) is num
            ? ((json[key] ?? json[_pascal(key)]) as num).toInt()
            : int.tryParse(text(key)) ?? 0;
    bool flag(String key) => (json[key] ?? json[_pascal(key)]) == true;
    List<String> strings(String key) {
      final raw = json[key] ?? json[_pascal(key)];
      return raw is List ? raw.map((item) => item.toString()).toList() : const [];
    }

    final quizCorrect = json['isQuizCorrect'] ?? json['IsQuizCorrect'];

    return MicroLearningCard(
      id: text('id'),
      title: text('title'),
      summary: text('summary'),
      category: text('category'),
      tips: strings('tips'),
      imageUrl: _nullable(json['imageUrl'] ?? json['ImageUrl']),
      quizQuestion: _nullable(json['quizQuestion'] ?? json['QuizQuestion']),
      quizOptions: strings('quizOptions'),
      pointsReward: number('pointsReward'),
      isSaved: flag('isSaved'),
      isRead: flag('isRead'),
      isQuizCompleted: flag('isQuizCompleted'),
      isQuizCorrect: quizCorrect is bool ? quizCorrect : null,
      selectedQuizOption: _intOrNull(json['selectedQuizOption'] ?? json['SelectedQuizOption']),
    );
  }
}

class MicroLearningCategory {
  const MicroLearningCategory({
    required this.name,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.totalCards,
  });

  final String name;
  final String displayName;
  final String description;
  final String icon;
  final int totalCards;

  factory MicroLearningCategory.fromJson(Map<String, dynamic> json) {
    final total = json['totalCards'] ?? json['TotalCards'];
    return MicroLearningCategory(
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['DisplayName'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      icon: (json['icon'] ?? json['Icon'] ?? '').toString(),
      totalCards: total is num ? total.toInt() : int.tryParse('$total') ?? 0,
    );
  }
}

class QuizSubmitResult {
  const QuizSubmitResult({
    required this.isCorrect,
    required this.correctOptionIndex,
    required this.feedback,
    required this.pointsEarned,
  });

  final bool isCorrect;
  final int correctOptionIndex;
  final String feedback;
  final int pointsEarned;

  factory QuizSubmitResult.fromJson(Map<String, dynamic> json) {
    int number(String key) {
      final value = json[key] ?? json[_pascal(key)];
      return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    }

    return QuizSubmitResult(
      isCorrect: (json['isCorrect'] ?? json['IsCorrect']) == true,
      correctOptionIndex: number('correctOptionIndex'),
      feedback: (json['feedback'] ?? json['Feedback'] ?? '').toString(),
      pointsEarned: number('pointsEarned'),
    );
  }
}

String _pascal(String value) => '${value[0].toUpperCase()}${value.substring(1)}';

String? _nullable(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

int? _intOrNull(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');
