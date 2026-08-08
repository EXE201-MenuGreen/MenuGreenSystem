class FeatureAccess {
  const FeatureAccess({
    required this.tier,
    required this.entitlements,
    required this.featureGroups,
    required this.expiresAt,
  });

  final String tier;
  final Set<String> entitlements;
  final Set<String> featureGroups;
  final DateTime? expiresAt;

  static const free = FeatureAccess(
    tier: 'free',
    entitlements: {'free_features'},
    featureGroups: {'free'},
    expiresAt: null,
  );

  bool get hasCasual => entitlements.contains('casual_features');
  bool get hasOffice => entitlements.contains('office_features');
  bool get hasGym => entitlements.contains('gym_features');
  bool get hasCoachAccess => entitlements.contains('coach_access');
  bool get hasAi => entitlements.contains('ai_features');

  factory FeatureAccess.fromJson(Map<String, dynamic> json) {
    Set<String> stringSet(String camel, String pascal) {
      final raw = json[camel] ?? json[pascal];
      if (raw is! List) return const {};
      return raw
          .map((item) => item.toString().trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
    }

    final entitlements = stringSet('entitlements', 'Entitlements');
    return FeatureAccess(
      tier: _pickString(json, 'tier', 'Tier').toLowerCase(),
      entitlements: {'free_features', ...entitlements},
      featureGroups: {'free', ...stringSet('featureGroups', 'FeatureGroups')},
      expiresAt: _pickDate(json, 'expiresAt', 'ExpiresAt'),
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String? description;
  final int durationDays;
  final int priceVnd;
  final String? featureGroup;
  final bool isActive;
  final String tierLabel;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.durationDays,
    required this.priceVnd,
    this.featureGroup,
    required this.isActive,
    required this.tierLabel,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: _pickString(json, 'id', 'Id'),
      name: _pickString(json, 'name', 'Name'),
      description: _pickNullableString(json, 'description', 'Description'),
      durationDays: _pickInt(json, 'durationDays', 'DurationDays'),
      priceVnd: _pickInt(json, 'priceVnd', 'PriceVnd'),
      featureGroup: _pickNullableString(json, 'featureGroup', 'FeatureGroup'),
      isActive: _pickBool(json, 'isActive', 'IsActive', defaultValue: true),
      tierLabel: _pickString(json, 'tierLabel', 'TierLabel'),
    );
  }

  bool get isFree => priceVnd <= 0;

  bool belongsToFeatureGroup(String expectedGroup) {
    final expected = expectedGroup.trim().toLowerCase();
    final group = featureGroup?.trim().toLowerCase() ?? '';
    if (group == expected) return true;

    final normalizedName = name.trim().toLowerCase();
    return switch (expected) {
      'casual' => normalizedName.contains('casual'),
      'office' => normalizedName.contains('office'),
      'gym' => normalizedName.contains('gym'),
      _ => false,
    };
  }

  bool get isBaselineFree {
    final group = featureGroup?.trim().toLowerCase() ?? '';
    final normalizedName = name.trim().toLowerCase();
    return group == 'basic' ||
        group == 'free' ||
        normalizedName == 'cơ bản' ||
        normalizedName == 'basic' ||
        normalizedName == 'free';
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final String subscriptionPlanId;
  final String subscriptionPlanName;
  final String? featureGroup;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? cancelledAt;
  final DateTime? renewedAt;
  final int daysRemaining;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.subscriptionPlanId,
    required this.subscriptionPlanName,
    this.featureGroup,
    required this.status,
    this.startDate,
    this.endDate,
    this.cancelledAt,
    this.renewedAt,
    required this.daysRemaining,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: _pickString(json, 'id', 'Id'),
      userId: _pickString(json, 'userId', 'UserId'),
      subscriptionPlanId: _pickString(
        json,
        'subscriptionPlanId',
        'SubscriptionPlanId',
      ),
      subscriptionPlanName: _pickString(
        json,
        'subscriptionPlanName',
        'SubscriptionPlanName',
      ),
      featureGroup: _pickNullableString(json, 'featureGroup', 'FeatureGroup'),
      status: _pickString(json, 'status', 'Status'),
      startDate: _pickDate(json, 'startDate', 'StartDate'),
      endDate: _pickDate(json, 'endDate', 'EndDate'),
      cancelledAt: _pickDate(json, 'cancelledAt', 'CancelledAt'),
      renewedAt: _pickDate(json, 'renewedAt', 'RenewedAt'),
      daysRemaining: _pickInt(json, 'daysRemaining', 'DaysRemaining'),
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  bool get isBaselineFree {
    final group = featureGroup?.trim().toLowerCase() ?? '';
    final normalizedName = subscriptionPlanName.trim().toLowerCase();
    return group == 'basic' ||
        group == 'free' ||
        normalizedName == 'cơ bản' ||
        normalizedName == 'basic' ||
        normalizedName == 'free';
  }

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final expiration = endDate;
    if (expiration == null) return true;
    final nowUtc = DateTime.now().toUtc();
    final expirationUtc = expiration.toUtc();
    return expirationUtc.isAfter(nowUtc);
  }

  int realtimeDaysRemaining([DateTime? currentTime]) {
    final expiration = endDate;
    if (expiration == null) return 0;
    final remaining = expiration.difference(currentTime ?? DateTime.now());
    if (remaining <= Duration.zero) return 0;
    return (remaining.inSeconds / Duration.secondsPerDay).ceil();
  }
}

class SubscriptionTransaction {
  final String id;
  final String userId;
  final String userSubscriptionId;
  final String transactionType;
  final int amount;
  final String status;
  final String? note;
  final DateTime? transactionDate;

  const SubscriptionTransaction({
    required this.id,
    required this.userId,
    required this.userSubscriptionId,
    required this.transactionType,
    required this.amount,
    required this.status,
    this.note,
    this.transactionDate,
  });

  factory SubscriptionTransaction.fromJson(Map<String, dynamic> json) {
    return SubscriptionTransaction(
      id: _pickString(json, 'id', 'Id'),
      userId: _pickString(json, 'userId', 'UserId'),
      userSubscriptionId: _pickString(
        json,
        'userSubscriptionId',
        'UserSubscriptionId',
      ),
      transactionType: _pickString(json, 'transactionType', 'TransactionType'),
      amount: _pickInt(json, 'amount', 'Amount'),
      status: _pickString(json, 'status', 'Status'),
      note: _pickNullableString(json, 'note', 'Note'),
      transactionDate: _pickDate(json, 'transactionDate', 'TransactionDate'),
    );
  }
}

String _pickString(Map<String, dynamic> json, String camel, String pascal) {
  return (json[camel] ?? json[pascal])?.toString() ?? '';
}

String? _pickNullableString(
  Map<String, dynamic> json,
  String camel,
  String pascal,
) {
  final value = json[camel] ?? json[pascal];
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _pickInt(Map<String, dynamic> json, String camel, String pascal) {
  final value = json[camel] ?? json[pascal];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

bool _pickBool(
  Map<String, dynamic> json,
  String camel,
  String pascal, {
  bool defaultValue = false,
}) {
  final value = json[camel] ?? json[pascal];
  if (value is bool) return value;
  if (value == null) return defaultValue;
  return value.toString().toLowerCase() == 'true';
}

DateTime? _pickDate(Map<String, dynamic> json, String camel, String pascal) {
  final value = json[camel] ?? json[pascal];
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return null;
  final parsed = DateTime.tryParse(str);
  if (parsed == null) return null;
  if (!parsed.isUtc && !str.endsWith('Z') && !str.contains('+')) {
    return DateTime.tryParse('${str}Z')?.toUtc() ?? parsed.toUtc();
  }
  return parsed.toUtc();
}

String formatVnd(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final position = text.length - i;
    buffer.write(text[i]);
    if (position > 1 && position % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()}đ';
}

String formatSubscriptionDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year';
}

String formatSubscriptionRemaining(DateTime? endDate, [DateTime? currentTime]) {
  if (endDate == null) return 'Không giới hạn';

  final remaining = endDate.difference(currentTime ?? DateTime.now());
  if (remaining <= Duration.zero) return 'Đã hết hạn';

  final totalMinutes = (remaining.inSeconds / Duration.secondsPerMinute).ceil();
  if (totalMinutes < 60) return 'Còn $totalMinutes phút';

  final totalHours = (remaining.inMinutes / Duration.minutesPerHour).ceil();
  if (totalHours < 24) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(Duration.minutesPerHour);
    return minutes == 0 ? 'Còn $hours giờ' : 'Còn $hours giờ $minutes phút';
  }

  final days = (remaining.inSeconds / Duration.secondsPerDay).ceil();
  return 'Còn $days ngày';
}

String formatDurationLabel(int durationDays) {
  if (durationDays <= 0) return 'Vĩnh viễn';
  if (durationDays >= 365) return '/năm';
  if (durationDays >= 30) return '/tháng';
  return '/$durationDays ngày';
}
