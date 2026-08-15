import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/i18n/api_message_translator_fixed.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/jwt_utils.dart';
import '../../../core/network/token_storage.dart';
import '../models/subscription_models.dart';

class UserSubscriptionRepository {
  UserSubscriptionRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  void _logFeatureAccess(String source, FeatureAccess access) {
    if (!kDebugMode) return;
    debugPrint(
      '[SubscriptionAccess] source=$source '
      'tier=${access.tier} '
      'entitlements=${access.entitlements.join(',')} '
      'groups=${access.featureGroups.join(',')}',
    );
  }

  Future<FeatureAccess> getFeatureAccess() async {
    if (kDebugMode) {
      final token = await TokenStorage().getAccessToken();
      debugPrint(
        '[SubscriptionAccess] tokenUserId=${token == null ? 'missing' : JwtUtils.tryGetUserId(token) ?? 'invalid'}',
      );
    }

    try {
      final response = await _api.get(ApiEndpoints.subscriptionEntitlements);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final access = FeatureAccess.fromJson(decoded);
          _logFeatureAccess('entitlements', access);
          return access;
        }
      }
      if (kDebugMode) {
        debugPrint(
          '[SubscriptionAccess] entitlements status=${response.statusCode} '
          'bodyEmpty=${response.body.isEmpty}; using active-subscriptions fallback.',
        );
      }
    } catch (_) {}

    try {
      final activeList = await getActive();
      if (activeList.isNotEmpty) {
        final entitlements = <String>{'free_features'};
        final featureGroups = <String>{'free'};
        for (final sub in activeList) {
          if (sub.isCurrentlyActive) {
            final fg = sub.featureGroup?.trim().toLowerCase() ?? '';
            final name = sub.subscriptionPlanName.toLowerCase();
            if (fg == 'office' || name.contains('office')) {
              entitlements.add('office_features');
              featureGroups.add('office');
            }
            if (fg == 'gym' || name.contains('gym')) {
              entitlements.add('gym_features');
              entitlements.add('coach_access');
              entitlements.add('ai_features');
              featureGroups.add('gym');
            }
            if (fg == 'casual' || name.contains('casual')) {
              entitlements.add('casual_features');
              featureGroups.add('casual');
            }
            if (fg == 'pro' || name.contains('pro')) {
              entitlements.addAll([
                'office_features',
                'gym_features',
                'casual_features',
                'coach_access',
                'ai_features',
              ]);
              featureGroups.addAll(['office', 'gym', 'casual', 'pro']);
            }
          }
        }
        final access = FeatureAccess(
          tier: featureGroups.length > 1 ? 'active' : 'free',
          entitlements: entitlements,
          featureGroups: featureGroups,
          expiresAt: null,
        );
        _logFeatureAccess('active-subscriptions fallback', access);
        return access;
      }
    } catch (_) {}

    _logFeatureAccess('free fallback', FeatureAccess.free);
    return FeatureAccess.free;
  }

  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    final response = await _api.get(ApiEndpoints.subscriptionPlans);
    if (response.statusCode != 200 || response.body.isEmpty) return [];

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPlan.fromJson)
        .toList();
  }

  Future<UserSubscription?> getCurrent() async {
    try {
      final response = await _api.get(ApiEndpoints.subscriptionCurrent);
      if (response.statusCode == 204 || response.body.isEmpty) return null;
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded == null) return null;
      if (decoded is! Map<String, dynamic>) return null;

      return UserSubscription.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserSubscription>> getActive() async {
    try {
      final response = await _api.get(ApiEndpoints.subscriptionActive);
      if (response.statusCode != 200 || response.body.isEmpty) {
        final current = await getCurrent();
        return current == null ? [] : [current];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(UserSubscription.fromJson)
          .toList();
    } catch (_) {
      final current = await getCurrent();
      return current == null ? [] : [current];
    }
  }

  Future<List<SubscriptionTransaction>> getHistory() async {
    final response = await _api.get(ApiEndpoints.subscriptionHistory);
    if (response.statusCode != 200 || response.body.isEmpty) return [];

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionTransaction.fromJson)
        .toList();
  }

  Future<({bool success, UserSubscription? data, String message})> subscribe({
    required String subscriptionPlanId,
    String? note,
  }) async {
    final response = await _api.postJson(ApiEndpoints.subscriptionSubscribe, {
      'subscriptionPlanId': subscriptionPlanId,
      if (note != null && note.isNotEmpty) 'note': note,
    });

    return _parseSubscriptionAction(response);
  }

  Future<({bool success, UserSubscription? data, String message})> renew({
    required String userSubscriptionId,
    String? note,
  }) async {
    final response = await _api.postJson(ApiEndpoints.subscriptionRenew, {
      'userSubscriptionId': userSubscriptionId,
      if (note != null && note.isNotEmpty) 'note': note,
    });

    return _parseSubscriptionAction(response);
  }

  Future<({bool success, UserSubscription? data, String message})> cancel({
    required String userSubscriptionId,
    String? reason,
  }) async {
    final response = await _api.postJson(ApiEndpoints.subscriptionCancel, {
      'userSubscriptionId': userSubscriptionId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });

    return _parseSubscriptionAction(response);
  }

  Future<({bool success, UserSubscription? data, String message})>
  _parseSubscriptionAction(dynamic response) async {
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return (
          success: true,
          data: UserSubscription.fromJson(decoded),
          message: 'Thành công',
        );
      }
      return (success: true, data: null, message: 'Thành công');
    }

    return (
      success: false,
      data: null,
      message: _extractErrorMessage(response.body),
    );
  }

  String _extractErrorMessage(String body) {
    if (body.isEmpty) return 'Thao tác thất bại. Vui lòng thử lại sau.';
    return ApiMessageTranslator.translate(body);
  }
}
