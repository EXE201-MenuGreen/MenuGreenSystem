import 'package:flutter/foundation.dart';

import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';
import '../services/random_picker_service.dart';

/// Daily Starter provider — `2.12 Beginner Quick-Start` ("Hôm nay ăn gì?").
class DailyStarterProvider extends ChangeNotifier {
  DailyStarterProvider({
    DailyStarterRepository? repository,
    RandomPickerService? pickerService,
  }) : _repo = repository ?? DailyStarterRepository(),
       _picker = pickerService ?? RandomPickerService();

  final DailyStarterRepository _repo;
  final RandomPickerService _picker;

  static const int randomDailyLimit = 4;

  bool _isLoading = false;
  String? _errorMessage;
  DailyStarterToday? _today;
  List<DailyStarterFood> _featured = const [];
  DailyStarterPersonalization? _personalization;
  bool _isPersonalizationLoading = false;
  bool _isQuickLogging = false;

  /// A single food that the user "randomed" — highlighted on top of the list.
  DailyStarterFood? _randomHighlight;
  int _randomUsedToday = 0;
  bool _isRandomPicking = false;
  String? _randomErrorMessage;

  bool get isLoading => _isLoading;
  bool get isPersonalizationLoading => _isPersonalizationLoading;
  bool get isQuickLogging => _isQuickLogging;
  bool get isRandomPicking => _isRandomPicking;
  String? get errorMessage => _errorMessage;
  String? get randomErrorMessage => _randomErrorMessage;
  DailyStarterToday? get today => _today;
  List<DailyStarterFood> get featured => _featured;
  DailyStarterPersonalization? get personalization => _personalization;
  DailyStarterFood? get randomHighlight => _randomHighlight;
  int get randomUsedToday => _randomUsedToday;
  int get randomRemaining => (randomDailyLimit - _randomUsedToday)
      .clamp(0, randomDailyLimit);

  /// Picks a random safe food from the featured pool and highlights it.
  ///
  /// Returns the picked food on success, `null` when:
  ///   - the daily limit (4) has been reached,
  ///   - there are no featured foods to pick from,
  ///   - the underlying storage fails.
  Future<DailyStarterFood?> pickRandomHighlight() async {
    if (_isRandomPicking) return null;
    _randomErrorMessage = null;

    final remaining = await _picker.remaining();
    if (remaining <= 0) {
      _randomErrorMessage = 'Bạn đã dùng hết $randomDailyLimit lượt gợi ý ngẫu nhiên hôm nay.';
      notifyListeners();
      return null;
    }
    if (_featured.isEmpty) {
      _randomErrorMessage = 'Chưa có món gợi ý để random.';
      notifyListeners();
      return null;
    }

    _isRandomPicking = true;
    notifyListeners();

    final consumed = await _picker.tryConsumePick();
    if (!consumed) {
      _isRandomPicking = false;
      _randomErrorMessage =
          'Bạn đã dùng hết $randomDailyLimit lượt gợi ý ngẫu nhiên hôm nay.';
      notifyListeners();
      return null;
    }

    // Avoid picking the same highlight as last time when possible.
    final pool = _featured.length > 1
        ? _featured
              .where((f) => f.id != (_randomHighlight?.id ?? ''))
              .toList()
        : _featured;
    final picked = pool[_randomIndex(pool.length)];

    _randomHighlight = picked;
    _randomUsedToday = await _picker.usedToday();
    _isRandomPicking = false;
    notifyListeners();
    return picked;
  }

  Future<void> refreshRandomUsage() async {
    _randomUsedToday = await _picker.usedToday();
    notifyListeners();
  }

  void clearRandomHighlight() {
    if (_randomHighlight == null) return;
    _randomHighlight = null;
    notifyListeners();
  }

  int _randomIndex(int length) {
    // Use a simple non-secure RNG; security does not matter here.
    return (DateTime.now().microsecondsSinceEpoch.abs()) % length;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final todayResult = await _repo.getToday();
    if (todayResult.success) {
      _today = todayResult.data;
    }
    final featuredResult = await _repo.getFeaturedMeals();
    if (featuredResult.success && featuredResult.data != null) {
      _featured = featuredResult.data!;
    }

    final personalizationResult = await _repo.getPersonalization();
    if (personalizationResult.success) {
      _personalization = personalizationResult.data;
    }

    _randomUsedToday = await _picker.usedToday();
    _isLoading = false;
    if (!todayResult.success && !featuredResult.success) {
      _errorMessage = todayResult.translatedMessage.isNotEmpty
          ? todayResult.translatedMessage
          : 'Không tải được dữ liệu.';
    }
    notifyListeners();
  }

  Future<bool> refreshPersonalization() async {
    _isPersonalizationLoading = true;
    notifyListeners();
    final result = await _repo.getPersonalization();
    _isPersonalizationLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _personalization = result.data;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> submitPersonalization({
    double? heightCm,
    double? weightKg,
    double? targetCalories,
    String? dietaryPreference,
  }) async {
    _isPersonalizationLoading = true;
    notifyListeners();
    final result = await _repo.updatePersonalization({
      'heightCm': ?heightCm,
      'weightKg': ?weightKg,
      'targetCalories': ?targetCalories,
      'dietaryPreference': ?dietaryPreference,
    });
    _isPersonalizationLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _personalization = result.data;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<String?> selectMeal(Map<String, dynamic> payload) async {
    final result = await _repo.selectMeal(payload);
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return result.translatedMessage;
    }
    _errorMessage = null;
    notifyListeners();
    return result.data;
  }

  Future<DailyStarterStartLog?> quickLog() async {
    if (_isQuickLogging) return null;
    _isQuickLogging = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.startLog();
    _isQuickLogging = false;
    if (!result.success || result.data == null) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return null;
    }

    _errorMessage = null;
    notifyListeners();
    await loadAll();
    return result.data;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
