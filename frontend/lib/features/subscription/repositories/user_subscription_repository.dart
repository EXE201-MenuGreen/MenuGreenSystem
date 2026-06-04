import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/subscription_models.dart';

class UserSubscriptionRepository {
  UserSubscriptionRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

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
    if (body.isEmpty) return 'Yêu cầu thất bại';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['Message'];
        if (message != null) return message.toString();
      }
    } catch (_) {}
    return 'Yêu cầu thất bại';
  }
}
