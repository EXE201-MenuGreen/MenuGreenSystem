/// Canonical health-profile values used by onboarding, profile edit, and API payloads.
class HealthProfileValues {
  HealthProfileValues._();

  static const Map<String, String> activityLabels = {
    'sedentary': 'Ít vận động',
    'lightly active': 'Vận động nhẹ',
    'moderately active': 'Vận động vừa',
    'very active': 'Rất năng động',
  };

  static const Map<String, String> goalLabels = {
    'lose weight': 'Giảm cân',
    'maintain weight': 'Duy trì vóc dáng',
    'gain weight': 'Tăng cân',
    'build muscle': 'Tăng cơ',
  };

  static const Map<String, String> genderLabels = {
    'Male': 'Nam',
    'Female': 'Nữ',
    'Other': 'Khác',
  };

  /// Maps API / legacy values to canonical activity key.
  static String normalizeActivity(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    switch (v) {
      case 'light':
      case 'lightlyactive':
      case 'lightly active':
        return 'lightly active';
      case 'moderate':
      case 'moderatelyactive':
      case 'moderately active':
        return 'moderately active';
      case 'active':
      case 'veryactive':
      case 'very active':
        return 'very active';
      case 'sedentary':
      default:
        return v.isEmpty ? 'sedentary' : (activityLabels.containsKey(v) ? v : 'sedentary');
    }
  }

  /// Maps API / legacy values to canonical goal key.
  static String normalizeGoal(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    switch (v) {
      case 'loseweight':
      case 'lose weight':
        return 'lose weight';
      case 'gainweight':
      case 'gain weight':
        return 'gain weight';
      case 'buildmuscle':
      case 'build muscle':
        return 'build muscle';
      case 'maintain':
      case 'maintain weight':
        return 'maintain weight';
      default:
        return v.isEmpty ? 'maintain weight' : (goalLabels.containsKey(v) ? v : 'maintain weight');
    }
  }

  static String? normalizeGender(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final v = raw.trim();
    if (genderLabels.containsKey(v)) return v;
    switch (v.toLowerCase()) {
      case 'nam':
      case 'male':
        return 'Male';
      case 'nữ':
      case 'nu':
      case 'female':
        return 'Female';
      default:
        return 'Other';
    }
  }

  static bool isHealthBaselineComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    final height = _positiveNum(profile['heightCm']);
    final weight = _positiveNum(profile['weightKg']);
    return height != null && weight != null;
  }

  static double? _positiveNum(dynamic value) {
    if (value == null) return null;
    final n = value is num ? value.toDouble() : double.tryParse(value.toString());
    if (n == null || n <= 0) return null;
    return n;
  }
}
