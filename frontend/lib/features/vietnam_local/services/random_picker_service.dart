import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how many times the user has tapped the "Random" button on the
/// Daily Starter screen. Capped at 4 per local day.
///
/// Storage is intentionally local (SharedPreferences) so:
///  - it works fully offline,
///  - resets happen per device (matches the casual UX of a "quick pick").
///
/// On a new day (Vietnam timezone) the counter automatically resets.
class RandomPickerService {
  RandomPickerService({this.dailyLimit = 4});

  static const String _storageKey = 'daily_starter.random_count.v1';

  final int dailyLimit;

  Future<int> _readCount() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _todayKey();
    final storedDate = prefs.getString('$_storageKey.date') ?? '';
    if (storedDate != dateKey) return 0;
    return prefs.getInt('$_storageKey.count') ?? 0;
  }

  Future<void> _writeCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_storageKey.date', _todayKey());
    await prefs.setInt('$_storageKey.count', count);
  }

  /// Returns how many picks are still available today (>= 0).
  Future<int> remaining() async {
    final used = await _readCount();
    return (dailyLimit - used).clamp(0, dailyLimit);
  }

  /// Returns the current usage for the day (0..dailyLimit).
  Future<int> usedToday() async => (await _readCount()).clamp(0, dailyLimit);

  /// Tries to spend one pick. Returns `true` if a new pick was registered,
  /// `false` when the daily limit has been reached.
  Future<bool> tryConsumePick() async {
    final used = await _readCount();
    if (used >= dailyLimit) return false;
    await _writeCount(used + 1);
    return true;
  }

  /// Resets the counter (useful for testing or when the user logs out).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_storageKey.date');
    await prefs.remove('$_storageKey.count');
  }

  String _todayKey() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
