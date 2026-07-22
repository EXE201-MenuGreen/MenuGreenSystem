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

class FoodMoodItem {
  const FoodMoodItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.scientificInsight,
    required this.rescueFoods,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final dynamic icon;
  final dynamic color;
  final String scientificInsight;
  final List<RescueFood> rescueFoods;

  static List<FoodMoodItem> defaultMoods() {
    return const [
      FoodMoodItem(
        id: 'stress',
        title: 'Căng thẳng / Stress',
        subtitle: 'Cần xoa dịu thần kinh & hạ Cortisol',
        emoji: '😫',
        icon: null,
        color: null,
        scientificInsight:
            'Khi stress, cơ thể tiết Cortisol làm suy giảm Magie và Vitamin B. Hãy nạp các món giàu đạm nhẹ, chất xơ & khoáng chất để làm dịu thần kinh.',
        rescueFoods: [
          RescueFood(
            name: 'Súp nấm hạt sen gà xé',
            caloriesKcal: 250,
            proteinG: 22.0,
            carbsG: 28.0,
            fatG: 5.5,
            estimatedPriceVnd: 45000,
            description: 'Hạt sen dưỡng tâm an thần, kết hợp đạm gà dễ tiêu hóa.',
          ),
          RescueFood(
            name: 'Salad bơ quả mộng & ức gà',
            caloriesKcal: 320,
            proteinG: 28.0,
            carbsG: 18.0,
            fatG: 14.0,
            estimatedPriceVnd: 55000,
            description: 'Bơ chứa chất béo Omega-3 giúp giảm viêm thần kinh.',
          ),
          RescueFood(
            name: 'Chuối chín & Chuối sấy hạt phỉ',
            caloriesKcal: 180,
            proteinG: 4.5,
            carbsG: 35.0,
            fatG: 3.0,
            estimatedPriceVnd: 25000,
            description: 'Chuối giàu Tryptophan - tiền chất sản sinh Serotonin vui vẻ.',
          ),
        ],
      ),
      FoodMoodItem(
        id: 'low_energy',
        title: 'Buồn ngủ / Uể uải',
        subtitle: 'Tỉnh táo giờ chiều không vọt đường',
        emoji: '😴',
        icon: null,
        color: null,
        scientificInsight:
            'Cơn buồn ngủ giờ chiều xảy ra do đường huyết sụt giảm sau bữa trưa. Chọn món đạm & chất xơ chậm chuyển hóa thay vì đồ ngọt vọt đường.',
        rescueFoods: [
          RescueFood(
            name: 'Táo giòn & Hạt hạnh nhân',
            caloriesKcal: 190,
            proteinG: 6.0,
            carbsG: 22.0,
            fatG: 9.0,
            estimatedPriceVnd: 30000,
            description: 'Chất xơ Pectin giải phóng năng lượng bền bỉ cả buổi chiều.',
          ),
          RescueFood(
            name: 'Trà xanh lạnh không đường & Chanh',
            caloriesKcal: 15,
            proteinG: 0.5,
            carbsG: 3.0,
            fatG: 0.0,
            estimatedPriceVnd: 15000,
            description: 'L-theanine trong trà xanh giúp tỉnh táo và tập trung cao.',
          ),
          RescueFood(
            name: 'Sữa chua Kép hạt chia & Việt quất',
            caloriesKcal: 160,
            proteinG: 10.0,
            carbsG: 16.0,
            fatG: 4.5,
            estimatedPriceVnd: 35000,
            description: 'Probiotics giúp tiêu hóa nhẹ bụng, đẩy lùi cảm giác nặng nề.',
          ),
        ],
      ),
      FoodMoodItem(
        id: 'sweet_craving',
        title: 'Thèm ngọt / Ăn vặt',
        subtitle: 'Thỏa mãn cơn thèm ít calo',
        emoji: '🍫',
        icon: null,
        color: null,
        scientificInsight:
            'Cơn thèm ngọt bộc phát khi cơ thể thiếu Hydrat hóa hoặc Mangan/Crom. Thay trà sữa bằng đồ ngọt tự nhiên từ trái cây và nước dừa.',
        rescueFoods: [
          RescueFood(
            name: 'Nước dừa tươi nguyên trái',
            caloriesKcal: 60,
            proteinG: 1.0,
            carbsG: 14.0,
            fatG: 0.5,
            estimatedPriceVnd: 25000,
            description: 'Bù khoáng điện giải tức thì, dập tắt cơn thèm ngọt.',
          ),
          RescueFood(
            name: 'Sô-cô-la đen 75% (30g)',
            caloriesKcal: 170,
            proteinG: 3.0,
            carbsG: 15.0,
            fatG: 11.0,
            estimatedPriceVnd: 30000,
            description: 'Giàu Polyphenol chống oxy hóa và xoa dịu cơn thèm đường.',
          ),
          RescueFood(
            name: 'Chè hạt sen nhãn nhục ít đường',
            caloriesKcal: 140,
            proteinG: 3.5,
            carbsG: 28.0,
            fatG: 1.0,
            estimatedPriceVnd: 25000,
            description: 'Vị ngọt thanh dịu nhẹ tự nhiên, mát gan thanh nhiệt.',
          ),
        ],
      ),
      FoodMoodItem(
        id: 'post_workout',
        title: 'Mệt mỏi sau tập',
        subtitle: 'Phục hồi cơ bắp & bù khoáng',
        emoji: '🏋️',
        icon: null,
        color: null,
        scientificInsight:
            'Cửa sổ vàng 30 phút sau tập cần đạm hấp thu nhanh và tinh bột phức hợp để tái tạo Glycogen và phục hồi vi tổn thương cơ bắp.',
        rescueFoods: [
          RescueFood(
            name: 'Ức gà nướng thảo mộc & Khoai lang',
            caloriesKcal: 380,
            proteinG: 35.0,
            carbsG: 40.0,
            fatG: 5.0,
            estimatedPriceVnd: 50000,
            description: 'Tỷ lệ Đạm - Tinh bột chuẩn tối ưu cho sự phát triển cơ.',
          ),
          RescueFood(
            name: 'Sinh tố Whey Protein & Chuối',
            caloriesKcal: 260,
            proteinG: 26.0,
            carbsG: 30.0,
            fatG: 2.5,
            estimatedPriceVnd: 40000,
            description: 'Đạm Whey hấp thu cực nhanh vào tế bào cơ.',
          ),
          RescueFood(
            name: 'Trứng luộc lòng đào (2 quả) & Muối tiêu',
            caloriesKcal: 140,
            proteinG: 13.0,
            carbsG: 1.0,
            fatG: 9.5,
            estimatedPriceVnd: 15000,
            description: 'Nguồn đạm sinh học hoàn hảo giá bình dân.',
          ),
        ],
      ),
      FoodMoodItem(
        id: 'comfort',
        title: 'Thèm đồ nóng / Giải cảm',
        subtitle: 'Ấm bụng, nhẹ dạ & giải độc',
        emoji: '🍲',
        icon: null,
        color: null,
        scientificInsight:
            'Món ăn nóng ấm giúp giãn mạch, tăng lưu thông máu và kích thích tiêu hóa. Gia vị gừng tỏi tự nhiên có tính kháng viêm cao.',
        rescueFoods: [
          RescueFood(
            name: 'Cháo gà gừng tươi & Hành hoa',
            caloriesKcal: 280,
            proteinG: 20.0,
            carbsG: 38.0,
            fatG: 4.5,
            estimatedPriceVnd: 35000,
            description: 'Gừng tươi làm ấm bụng, giải cảm và êm dịu đường ruột.',
          ),
          RescueFood(
            name: 'Canh cua đồng rau đét & Cà muối',
            caloriesKcal: 180,
            proteinG: 16.0,
            carbsG: 12.0,
            fatG: 6.0,
            estimatedPriceVnd: 30000,
            description: 'Giàu Canxi tự nhiên, thanh mát giải nhiệt mùa hè.',
          ),
          RescueFood(
            name: 'Súp hải sản nấm tuyết',
            caloriesKcal: 220,
            proteinG: 18.0,
            carbsG: 24.0,
            fatG: 4.0,
            estimatedPriceVnd: 45000,
            description: 'Đạm hải sản nhẹ nhàng, nấm tuyết bồi bổ thể lực.',
          ),
        ],
      ),
    ];
  }
}

class RescueFood {
  const RescueFood({
    required this.name,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.estimatedPriceVnd,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int estimatedPriceVnd;
  final String description;
  final String? imageUrl;
}
