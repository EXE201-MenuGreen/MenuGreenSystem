import '../models/subscription_models.dart';

bool hasGymerSubscriptionAccess(Iterable<UserSubscription> subscriptions) {
  final now = DateTime.now();
  return subscriptions.any((subscription) {
    if (!subscription.isActive) return false;
    final endDate = subscription.endDate;
    if (endDate != null && endDate.isBefore(now)) return false;

    final featureGroup = subscription.featureGroup?.trim().toLowerCase() ?? '';
    if (featureGroup == 'gym' || featureGroup == 'pro') return true;

    // Fallback keeps the app compatible while an older backend is rolling out.
    final planName = subscription.subscriptionPlanName.toLowerCase();
    return planName.contains('gym') || planName.contains('pro');
  });
}

bool hasAiVipSubscriptionAccess(Iterable<UserSubscription> subscriptions) {
  final now = DateTime.now();
  return subscriptions.any((subscription) {
    if (!subscription.isActive) return false;
    final endDate = subscription.endDate;
    if (endDate != null && endDate.isBefore(now)) return false;

    final featureGroup = subscription.featureGroup?.trim().toLowerCase() ?? '';
    if (featureGroup == 'gym' ||
        featureGroup == 'pro' ||
        featureGroup == 'premium' ||
        featureGroup == 'vip') {
      return true;
    }

    final planName = subscription.subscriptionPlanName.toLowerCase();
    return planName.contains('gym') ||
        planName.contains('pro') ||
        planName.contains('premium') ||
        planName.contains('vip') ||
        planName.contains('gold');
  });
}
